# เชื่อม SciProject AI กับ Supabase

## 1. สร้างโปรเจกต์ Supabase

สร้างโปรเจกต์ใหม่ใน Supabase แล้วเปิดใช้ Email authentication ใน **Authentication → Providers** ตามนโยบายของคุณ

## 2. สร้างตารางและกฎสิทธิ์

เปิด **SQL Editor** แล้วรันไฟล์ [20260828_initial_schema.sql](./migrations/20260828_initial_schema.sql) ทั้งไฟล์เพียงครั้งเดียว

ไฟล์นี้สร้างตาราง `profiles`, `projects`, `evaluations`, `research_references`, bucket สำหรับเอกสาร และ Row Level Security (RLS) ดังนี้:

- ผู้ใช้ทั่วไป: เห็นเฉพาะโครงงานและผลของตนเอง
- ผู้ดูแล (`admin`): เห็นทุกโครงงานและข้อมูลทั้งหมดผ่าน Dashboard เดียวกัน

## 3. กำหนดบัญชีผู้ดูแล

Supabase Auth แบบอีเมลต้องมีอีเมลสำหรับเข้าสู่ระบบ จึงไม่ควรสร้างผู้ดูแลด้วยชื่อผู้ใช้อย่างเดียวหรือเก็บรหัสผ่านไว้ใน source code

1. สร้างบัญชีผู้ดูแลใน **Authentication → Users** ด้วยอีเมลที่ควบคุมได้ หรือให้บัญชีนั้นสมัครผ่านหน้าเว็บก่อน
2. ใน SQL Editor รันคำสั่งนี้ โดยแทนที่อีเมลด้วยอีเมลของบัญชีผู้ดูแล:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'admin@example.com');
```

หลังจากนั้น บัญชีนี้จะเห็นข้อมูลรวมทั้งหมด ส่วนผู้ใช้คนอื่นที่สมัครเองจะมี role `student` และเห็นเฉพาะข้อมูลของตัวเอง

## 4. เชื่อมจากโค้ด

แก้ไขไฟล์ [config.js](./config.js) แล้วใส่ Project URL (`https://xxxxx.supabase.co`) และ **Publishable key** จากหน้า **API Keys**:

```js
window.SUPABASE_CONFIG = {
  url: 'https://xxxxx.supabase.co',
  publishableKey: 'sb_publishable_...'
};
```

จากนั้นเปิด `index.html` ผู้ใช้จะเห็นเฉพาะหน้า Login และสามารถสมัครสมาชิกหรือเข้าสู่ระบบได้ ข้อมูลโครงงานจะเริ่มบันทึกที่ Supabase เมื่อผู้ใช้เข้าสู่ระบบแล้ว

## ข้อควรระวัง

- ใส่ได้เฉพาะ Publishable key (หรือ anon key ของโปรเจกต์เก่า) ในหน้าเว็บ
- ห้ามใส่ `sb_secret_...` หรือ `service_role` key ใน HTML, localStorage หรือ Git โดยเด็ดขาด
- ก่อนเปิดใช้งานจริง ให้ทดสอบ RLS ด้วยผู้ใช้ทั่วไปอย่างน้อย 2 บัญชี และบัญชี admin เพื่อยืนยันว่า user อ่านข้ามกันไม่ได้ แต่ admin เห็นข้อมูลรวมได้
- AI API key ต้องเก็บเป็น secret ใน Supabase Edge Function หรือ backend เท่านั้น ไม่เรียก AI จาก browser โดยตรง
