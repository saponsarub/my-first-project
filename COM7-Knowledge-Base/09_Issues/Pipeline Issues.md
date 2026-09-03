# Pipeline Issues

คำถามและงานค้างของ pipeline · เครือข่าย · โปรเจกต์ที่กำลังเดิน

---

## Network & VPN — งานที่ต้องทำต่อ

เนื้อหา → [[Network & VPN]]

- [ ] กรอกช่องที่ยังว่าง (Public IP · firewall · CIDR ทั้ง 2 ฝั่ง)
- [ ] ตัดสินใจ Static vs **BGP**
- [ ] **สร้าง PSK ใหม่** ถ้าไฟล์เดิมผ่านช่องทางที่ไม่ปลอดภัย และย้ายไปเก็บใน Secrets Manager
- [ ] ตรวจว่า on-prem CIDR ไม่ทับกับ VPC CIDR (ถ้าทับ ต้องทำ NAT)
- [ ] ประเมินแบนด์วิดท์ที่ต้องใช้ตอน full load ครั้งแรก — เทียบกับเพดาน 1.25 Gbps
- [ ] ตั้ง CloudWatch alarm บนสถานะ tunnel
- [ ] ระบุเจ้าของ/ผู้ดูแลการเชื่อมต่อ

---

## K2 Termination Automation — เรื่องที่ต้องตัดสินใจก่อนลงมือ

เนื้อหา → [[K2 Termination Automation]] · ยังเป็นข้อเสนอ ยังไม่ได้ลงมือ

- [ ] **"📧 USER" ผู้รับอีเมลคือใคร** — ทีมติดตามหนี้ภายใน หรือตัวลูกค้าเอง · ถ้าเป็นลูกค้า **ขั้นให้คนอนุมัติก่อนส่งจำเป็น ไม่ใช่ทางเลือก** → **หัวหน้าทีมติดตามหนี้**
- [ ] **SES ไม่มีที่ ap-southeast-7** — เลือกทางไหน: presigned URL (แนะนำ) · SMTP ของบริษัท · หรือ SES สิงคโปร์ (ต้องให้ legal เคลียร์เรื่อง PII ข้ามพรมแดน) → **legal / DPO**
- [ ] เลือก compute: **ECS Fargate** (เสนอ) หรือ Lambda container image
- [ ] เลือกวิธีทำ PDF: LibreOffice headless หรือ reportlab · และหาฟอนต์ไทยที่มีสิทธิ์ใช้เชิงพาณิชย์
- [ ] ตกลงว่าจะเก็บ audit trail ว่าใครได้รับหนังสือเมื่อไหร่ไว้ที่ไหน (เสนอ DynamoDB)
- [ ] **connection string ยังเป็น public IP** — ต้องเปลี่ยนเป็น private IP ตอนย้ายไปวิ่งผ่าน VPN → [[Network & VPN]]

---

## Redshift — เรื่องที่ต้องหาคำตอบก่อนตัดสินใจ

เนื้อหา → [[Redshift]] · **ยังไม่ได้ตัดสินใจว่าจะใช้หรือไม่**

*(ปิดแล้ว 2026-09-02: ap-southeast-7 มีทั้ง Redshift Serverless และ Provisioned · Serverless GA ที่ไทยตั้งแต่ มี.ค. 2025 — ไม่ติดข้อกำหนด PDPA ดู [[Redshift]])*

- [ ] PoC review บันทึกว่า Spectrum "แพงมาก" — **ประเมินบนฐาน Provisioned ($5/TB แยก) หรือ Serverless (รวมใน RPU) ?** ขอตัวเลขจริงด้วยว่า scan เท่าไหร่ query แบบไหน → **คนที่ทำ PoC** · ดู [[Redshift]]
- [ ] มี dashboard ที่ต้องใช้ทุกวันจริงไหม — ถ้าไม่มี [[Athena Benchmark|Athena]] ยังพอ ยังไม่ต้องเปิด Redshift
- [ ] ถ้าเปิดใช้ ต้องตกลง VARCHAR ของฟิลด์ข้อความไทยให้เผื่อ 3–4 เท่า (byte ไม่ใช่ตัวอักษร) → [[Data Standardization & Quality]]
- [ ] QuickSight ไม่มีที่ไทย — ถ้าเลือก BI ตัวอื่น ตัวนั้นต่อ Redshift หรือ Athena ได้ไหม → [[Analytics & AI]]

---

## Google Sheet → S3 (Lambda) — งานที่ต้องทำต่อ

เนื้อหา → [[Google Sheet to S3 (Lambda)]] · deploy สำเร็จ 2026-09-02 · ยังเป็นฟังก์ชันทดลอง (`test-ingest-googlesheet`)

- [ ] เติม log ให้ครบตาม [[ETL & Spark|ข้อกำหนดที่ตกลง 2026-08-27]] — จำนวนแถวปลายทางเทียบต้นทาง · timestamp เริ่ม-เสร็จ · โหมดเขียน
- [ ] ผูก **EventBridge schedule** เข้ารอบ 23:30 น. (ตอนนี้ยัง manual trigger)
- [ ] ยืนยันว่า `leads-ev7-2026.csv` มี PII จริงไหม ถ้ามีต้องเข้ากติกา [[Consent & PDPA]] และตรวจ bucket policy / encryption ของ `google-sheet-extract`
- [ ] ตกลงว่าจะเก็บประวัติย้อนหลังไหม — ตอนนี้เขียนทับ key เดิมทุกรอบ ไม่มี partition ตามวันที่
- [ ] ตั้ง CloudWatch alarm บน error/timeout ของฟังก์ชัน
- [ ] ป้องกัน schema drift — คนแก้คอลัมน์ในชีตได้ตลอดโดย pipeline ไม่รู้ตัว → [[Data Standardization & Quality]]
- [ ] ย้าย library ไป **Lambda Layer** เพื่อให้ zip โค้ดเหลือไม่กี่ KB (ตอนนี้ 5.9 MB แก้ใน Console ไม่ได้)
- [ ] เปลี่ยนชื่อฟังก์ชัน/role จาก `test-*` ถ้าจะใช้จริง

---

## Collection Union (K2 + ITOS) — งานที่ต้องทำต่อ

เนื้อหา → [[Collection Union (K2 + ITOS)]]

- [ ] แก้ `nvarchar` ให้ระบุความยาว (ข้อบกพร่อง #1) แล้วเทียบว่าที่อยู่ยาวขึ้นจริง
- [ ] เติม `WHERE EXTRACT_DATE` เพื่อจำกัดปริมาณ
- [ ] ตัดสินใจว่าจะ union ที่ **ต้นทาง (SQL)** หรือที่ **Bronze/Silver (Glue)** — ดู [[ETL & Spark]] · [[Decisions]]
- [ ] ตรวจว่ามี `CONTRACT_ID` ชนกันระหว่าง 2 ระบบไหม (ถ้าชน ต้องทำ composite key `SOURCE_SYSTEM + CONTRACT_ID`)
- [ ] หา entity resolution ระหว่างลูกค้า K2 กับ ITOS — คนเดียวกันอาจมีทั้ง 2 ระบบ → [[Customer Identity]]

---

## K2 + ITOS Integration — คำถามที่ยังไม่มีคำตอบ

เนื้อหา → [[K2 + ITOS Integration]]

*(ปิดแล้วจากประชุม 2026-08-27: K2 table ไหนยัง update · lake จะ ingest อะไร → **ITOS primary · K2 historical** ดู [[UFUND in Customer 360]])*

- K2 กับ ITOS มีข้อมูลสัญญาเดียวกันซ้ำกันไหม
- "ถังของพี่คอง" คืออะไรในเชิง AWS — S3 bucket หรือ staging DB
- **ข้อมูลผู้ค้ำประกัน** จะใช้หรือไม่ใช้ (ความเห็นล่าสุด: น่าจะไม่ใช้ เพราะไม่ใช่ลูกค้าจริง)

---

## OD6 Collection Delivery — คำถามที่ยังไม่มีคำตอบ

เนื้อหา → [[OD6 Collection Delivery]]

1. เกณฑ์แบ่ง `GROUP_ASSIGN` 1–5 คืออะไร ใครกำหนด
2. ทำไมไฟล์นี้ไม่มีสัญญา ITOS (`TFF`) — ทีม ITOS ส่งไฟล์แยก หรือยังไม่ได้รวม
3. `ASSIGN_TO_TEAM` มีค่าอะไรอีกบ้างนอกจาก `OA_OD6` (OD1–OD5 ส่งให้ทีมไหน)
4. ไฟล์นี้ส่งด้วยมือหรืออัตโนมัติ ความถี่เท่าไหร่
5. หลังส่งแล้ว ผลการติดตามถูกบันทึกกลับเข้าระบบไหม ที่ตารางไหน

---

## EV China Benchmark (Ontime) — งานที่ต้องทำต่อ

เนื้อหา → [[EV China Benchmark]]

- [ ] **ยืนยันกับฐานข้อมูลจริงว่า K2 มีข้อมูล EV ปนอยู่จริงหรือไม่ และแยกด้วยคอลัมน์ไหน** ← สำคัญที่สุด
- [ ] ตรวจว่า `365` (Dynamics) ควรเป็นแหล่งข้อมูลใน Data Lake หรือไม่ — ปัจจุบันยังไม่อยู่ใน [[System Inventory]]
- [ ] ระบุว่า `Gtrack Smarth` (GPS) เก็บข้อมูลอะไร ความถี่เท่าไหร่ — เป็น time-series ขนาดใหญ่
- [ ] ประเมินว่าจะสร้าง risk layer บน Data Lake หรือซื้อระบบ risk engine

---

## เชื่อมกับโน้ตอื่น

[[Issue Index]] · [[Open Questions & Risks]] · [[Current Status]] · [[Home]]
