-- SciProject AI: initial database schema for Supabase
-- Run this migration in Supabase SQL Editor or with the Supabase CLI.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'student' check (role in ('student', 'reviewer', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  category text not null default 'วิทยาศาสตร์ประยุกต์',
  description text,
  status text not null default 'draft' check (status in ('draft', 'analyzing', 'completed', 'failed')),
  source_document_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.evaluations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  status text not null default 'queued' check (status in ('queued', 'running', 'completed', 'failed')),
  overall_score numeric(5,2) check (overall_score between 0 and 100),
  quality_level text,
  metrics jsonb not null default '{}'::jsonb,
  checklist jsonb not null default '[]'::jsonb,
  strengths jsonb not null default '[]'::jsonb,
  suggestions jsonb not null default '[]'::jsonb,
  expected_results jsonb not null default '[]'::jsonb,
  model_name text,
  prompt_version text,
  error_message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.research_references (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  published_year integer check (published_year between 1900 and 2100),
  relevance_score numeric(5,2) check (relevance_score between 0 and 100),
  source_url text,
  doi text,
  summary text,
  created_at timestamptz not null default now()
);

create index if not exists projects_owner_created_idx on public.projects(owner_id, created_at desc);
create index if not exists evaluations_project_created_idx on public.evaluations(project_id, created_at desc);
create index if not exists research_references_project_idx on public.research_references(project_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at before update on public.projects
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.evaluations enable row level security;
alter table public.research_references enable row level security;

revoke all on public.profiles, public.projects, public.evaluations, public.research_references from anon;
grant select on public.profiles, public.evaluations, public.research_references to authenticated;
grant select, insert, update, delete on public.projects to authenticated;

create policy "Users can read own profile or admins can read all" on public.profiles for select to authenticated using ((select auth.uid()) = id or (select public.is_admin()));

create policy "Users can read own projects or admins can read all" on public.projects for select to authenticated using ((select auth.uid()) = owner_id or (select public.is_admin()));
create policy "Users can create their own projects" on public.projects for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "Users can update own projects or admins can update all" on public.projects for update to authenticated using ((select auth.uid()) = owner_id or (select public.is_admin())) with check ((select auth.uid()) = owner_id or (select public.is_admin()));
create policy "Users can delete own projects or admins can delete all" on public.projects for delete to authenticated using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Users can read evaluations of own projects" on public.evaluations for select to authenticated using (
  (select public.is_admin()) or exists (select 1 from public.projects p where p.id = project_id and p.owner_id = (select auth.uid()))
);

create policy "Users can read research for own projects" on public.research_references for select to authenticated using (
  (select public.is_admin()) or exists (select 1 from public.projects p where p.id = project_id and p.owner_id = (select auth.uid()))
);

-- Private file bucket. Client uploads only to <auth.uid()>/<filename>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('project-documents', 'project-documents', false, 10485760,
        array['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain'])
on conflict (id) do nothing;

create policy "Users can read own project documents" on storage.objects for select to authenticated
using (bucket_id = 'project-documents' and ((storage.foldername(name))[1] = (select auth.uid())::text or (select public.is_admin())));
create policy "Users can upload own project documents" on storage.objects for insert to authenticated
with check (bucket_id = 'project-documents' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users can update own project documents" on storage.objects for update to authenticated
using (bucket_id = 'project-documents' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'project-documents' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users can delete own project documents" on storage.objects for delete to authenticated
using (bucket_id = 'project-documents' and (storage.foldername(name))[1] = (select auth.uid())::text);
