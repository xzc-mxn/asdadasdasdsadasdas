# SciProject AI

แดชบอร์ดผลประเมินโครงงานวิทยาศาสตร์ภาษาไทย โทน Dark Mode สำหรับใช้เป็นต้นแบบหน้าจอและการนำเสนอ

## สิ่งที่ทำงานได้ในต้นแบบ

- แสดงคะแนนรวม, คะแนนรายเกณฑ์, checklist, จุดแข็ง, ข้อเสนอแนะ และผลที่คาดว่าจะได้รับ
- Responsive sidebar สำหรับมือถือ
- ปุ่มสร้างโครงงานบันทึกชื่อและประเภทไว้ใน `localStorage` ของเบราว์เซอร์ และสลับโครงงานที่กำลังแสดงได้
- คลิกรายการงานวิจัยเพื่อดูสรุป และเปิด/ปิดรายการเพิ่มเติมได้
- ปุ่มดาวน์โหลดรายงานสร้างไฟล์ HTML แบบพกพา ซึ่งเปิดแล้วเลือก Print เพื่อบันทึกเป็น PDF ได้
- มีหน้า Login; ผู้ใช้สมัคร/เข้าสู่ระบบด้วยอีเมลได้ และ Supabase RLS จำกัดข้อมูลให้เห็นเฉพาะของตนเอง ขณะที่ role `admin` เห็นข้อมูลรวมได้
- การตั้งค่า Supabase อยู่ในโค้ดที่ [supabase/config.js](./supabase/config.js) โดยไม่แสดงใน UI

> ผลประเมินทั้งหมดในเวอร์ชันนี้เป็นข้อมูลตัวอย่างใน `index.html` การสร้างโครงงานเก็บไว้เฉพาะเบราว์เซอร์เครื่องนั้น และยังไม่มีการเรียก AI จริง

## Supabase

มี migration พร้อม RLS, Auth และ private storage bucket ที่ [supabase/migrations/20260828_initial_schema.sql](./supabase/migrations/20260828_initial_schema.sql) และขั้นตอนเชื่อมต่อใน [supabase/SETUP.md](./supabase/SETUP.md)

## วิธีเปิดดู

เปิดไฟล์ `index.html` ด้วยเบราว์เซอร์สมัยใหม่ที่เชื่อมต่ออินเทอร์เน็ต เพื่อโหลดฟอนต์และไอคอน Lucide จาก CDN

## สิ่งที่ต้องทำก่อนเปิดใช้งานจริง

### ต้องมี (MVP)

- [x] ฐานข้อมูล Supabase สำหรับผู้ใช้, โครงงาน, ผลวิเคราะห์ และงานวิจัย พร้อม RLS ขั้นพื้นฐาน
- [x] Email authentication สำหรับผู้ใช้, role `student`/`admin` และการซิงก์รายการโครงงานตามสิทธิ์
- [ ] การแก้ไข/ลบโครงงาน, สิทธิ์ครู/กรรมการ และการอัปโหลดไฟล์ (PDF/DOCX/รูป) ไปยัง object storage
- [ ] AI evaluation service: แยกข้อความจากไฟล์, ส่งตาม rubric, เก็บ score/reasoning/source, แสดงสถานะกำลังประมวลผล และรองรับงานที่ล้มเหลว
- [ ] Validation ของคะแนน: เกณฑ์คะแนนที่ตรวจสอบได้, human review/override, log เวอร์ชันของ prompt และโมเดล
- [ ] ระบบงานวิจัยที่เกี่ยวข้อง: ค้นจากแหล่งข้อมูลที่ได้รับอนุญาต, เก็บ URL/DOI/แหล่งอ้างอิง และหลีกเลี่ยงการสร้าง citation ขึ้นเอง
- [ ] รายงาน PDF ฝั่ง server ที่มีชื่อโครงงาน, วันเวลา, rubric และผลวิเคราะห์จริง

### ความปลอดภัยและข้อกำกับดูแล

- [ ] ป้องกัน API ด้วย session/JWT, authorization ทุก endpoint, rate limit และ validation ของไฟล์
- [ ] เข้ารหัสข้อมูลระหว่างส่งและขณะเก็บ, backup/restore, audit log และนโยบายลบข้อมูล
- [ ] PDPA: consent, privacy notice, จำกัดข้อมูลส่วนบุคคลที่ส่งให้โมเดล และข้อตกลงกับผู้ให้บริการ AI
- [ ] ป้องกัน prompt injection จากเอกสารที่อัปโหลด และสแกนไฟล์อันตรายก่อนประมวลผล

### พร้อมใช้งานในระดับ production

- [ ] แยก React + Tailwind เป็นโปรเจกต์จริง (ปัจจุบันเป็น HTML prototype) พร้อม state management และ routing
- [ ] Automated tests: unit, API, upload, authorization, browser responsive และ acceptance test ของ rubric
- [ ] Observability: error tracking, structured logs, uptime/queue/AI-cost monitoring และ alert
- [ ] CI/CD, environment แยก dev/staging/prod, secret manager และ custom domain + HTTPS
- [ ] หน้าสถานะวิเคราะห์, retry, empty/error states และช่องทางติดต่อผู้ดูแล

## ลำดับที่แนะนำ

1. สร้างฐานข้อมูล, authentication และ Project CRUD
2. ทำอัปโหลดไฟล์ + text extraction + AI evaluation ที่ตรวจสอบย้อนหลังได้
3. เชื่อม dashboard กับ API และสร้างรายงาน PDF
4. เพิ่ม search งานวิจัย, สิทธิ์ครู/กรรมการ, security และ monitoring
