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
