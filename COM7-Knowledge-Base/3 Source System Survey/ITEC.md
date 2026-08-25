# ITEC

Survey **Done** — ระบบเดียวที่เสร็จแล้ว · Data Team

---

## ที่รู้

ITEC เป็นฐานข้อมูล/ระบบหลักของธุรกิจค้าปลีก IT

**ความสำคัญ:** Data Framework slide 8 ฝั่ง Current ระบุว่า

> "CRM Data: Covers ITEC only. Data is sent to CRM team to conduct promotion/loyalty program through Braze."

**ITEC เป็นระบบเดียวที่ป้อนข้อมูลเข้า CRM ตอนนี้** ฝั่ง Propose คือขยายเป็น "covers every system in COM7 group"

Brief เดิมระบุว่า ITEC เกี่ยวข้องกับ Studio7 และ Banana IT — ตาราง `M_COMPANY` ใน ITOS ก็มี `Studio7` และ `BaNANA` เป็นบริษัทที่เกี่ยวข้องกับสัญญาสินเชื่อ แต่**ยังไม่มีเอกสารที่ระบุความสัมพันธ์ระหว่าง ITEC กับสองแบรนด์นี้โดยตรง**

---

## ข้อมูลลูกค้าที่ไหลเข้า CRM

Data Framework slide 8 ระบุ Available Data ฝั่ง Current:

- Main Customer id (เชื่อมกับ 7Club ได้)
- Citizen id
- Demographic: name, age, birth day, gender
- Career type
- Address: province, district, post code
- Contract Channel: phone, e-mail
- Create Date และ Updated Date
- UTM: activity and engagement — purchase transaction, channel, website/application search, landing page
- PDPA Consent
- Employee flag
- Student flag

Gap Review ทักว่า "Contract Channel" น่าจะเป็น typo ของ "Contact Channel" (`DEM-04`)

---

## Field ที่ Gap Review ระบุว่าอยู่ที่ ITEC

Owner ที่ระบุคือ MIS

| ID       | Field                             | สถานะ                                                         |
| -------- | --------------------------------- | ------------------------------------------------------------- |
| `TXN-01` | Line-item / SKU level detail      | มีแล้ว                                                        |
| `TXN-02` | Payment Method + Installment Plan | มีแล้ว                                                        |
| `TXN-03` | Store Code + Staff / Sales ID     | มีแล้ว                                                        |
| `TXN-05` | Channel of Purchase               | มีแต่ไม่ละเอียดพอ — มี channel (UTM) แต่ไม่แยก online/offline |
| `DEV-02` | Purchase Date + Device Age        | ขาด                                                           |
| `DEV-06` | Accessory Attach History          | มีแล้ว                                                        |

ITEC เป็นระบบที่มีข้อมูล transaction ครบที่สุดในบรรดาที่ Gap Review ตรวจ — SKU level, payment method, store/staff มีครบ

ช่องว่างคือ `DEV-01` Device Registry (brand/model/serial/IMEI) ที่ระบุว่าขาด และเป็นสิ่งที่จะเชื่อมการซื้อเข้ากับตัวอุปกรณ์ `[อนุมาน]`

---

## ที่อยู่ทางกายภาพ

จาก SQL ใน `C:\Projects\Data-Team-Code\`:

`PROJECT_1.dbo.view_itec_payment` — view ข้อมูลการชำระเงินของ ITEC
ไฟล์ที่เกี่ยวข้อง: `ITEC_PaymentType-Amount.sql`, `ITEC_ReceiveVoucher.sql`

view นี้ใช้**ชื่อคอลัมน์ภาษาไทย** (`ประเภท`, `จำนวนเงินที่ได้รับ`) ซึ่งเกี่ยวข้องกับเรื่อง encoding และการ rename ที่ Bronze

**ยังไม่รู้ว่า `PROJECT_1` เป็น source จริง หรือเป็นชั้น reporting เหนือ ITEC**

---

## ปัญหา: survey Done แต่ไม่มีเอกสาร

Timeline ระบุ ITEC เป็น **Done** แต่**ไม่พบ schema หรือ data dictionary ของ ITEC ในโฟลเดอร์ที่ตรวจทั้งหมด**

ต่างจาก ITOS ที่มี schema wiki 55 tables และ GI Core ที่มี `schema.prisma`

ควรถามว่าผลการ survey เก็บไว้ที่ไหน

---

## บทบาทใน Pilot

Timeline ระบุ Pilot item 2: **"ITEC Replicated Data to AWS direcly"** tag `INGEST`

เป็นตัวเลือกที่สมเหตุสมผลสำหรับ ingestion จริงตัวแรก เพราะเป็นระบบเดียวที่ survey เสร็จ และเป็นระบบเดียวที่ป้อน CRM อยู่แล้วจึงมี baseline ให้เทียบผล `[อนุมาน]`

---

## คำถามที่ยังเปิด

- ITEC schema / data dictionary อยู่ที่ไหน
- ใช้ database engine อะไร อยู่ on-prem หรือ cloud
- `PROJECT_1` เป็น source หรือ reporting layer
- ปริมาณข้อมูลและอัตราการโตเท่าไหร่
- ITEC → CRM feed ทำงานยังไงตอนนี้ (batch? ความถี่?)
- ความสัมพันธ์กับ Studio7 และ Banana IT เป็นยังไงในเชิงระบบ

---

## อ่านต่อ

[[System Inventory]] · [[Customer Platforms (CRM, 7Club, Braze)]] · [[../4 SSOT & Customer 360/Customer Identity|Customer Identity]]
