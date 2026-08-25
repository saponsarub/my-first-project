# COM7 Data Knowledge Base

บันทึกงานข้อมูลที่ **บริษัท คอมเซเว่น จำกัด (มหาชน)**

---

## แผนที่โปรเจกต์

โฟลเดอร์ 1–5 เรียงตามลำดับที่งานเดินจริง

| # | โฟลเดอร์ | คืออะไร | สถานะ |
|---|---|---|---|
| **1** | **Data Framework** | **มาตรฐาน**ที่ MIS ออกให้ทั้งเครือ + เป้าหมาย SSOT | เขียนแล้ว |
| **2** | **AWS Data Lake** | **โปรเจกต์หลัก** — PoC / Pilot / Production | PoC กำลังทำ |
| **3** | **Source System Survey** | สำรวจ 11 ระบบต้นทาง | **เสร็จ 1/11** |
| **4** | **SSOT & Customer 360** | 3 ปัญหาที่ยากจริง — identity, consent, standardization | ยังไม่เริ่มแก้ |
| **5** | **Sub-Projects** | โปรเจกต์ย่อยที่เดินคู่ขนาน | กำลังทำ |
| 6 | Technical | ความรู้เทคนิค AWS / ETL / SQL / Analytics | อ้างอิง |
| 7 | Reference | คน · ศัพท์ · ที่มาข้อมูล · ผลทดสอบ | อ้างอิง |

---

## หาอะไรเปิดตรงไหน

| อยากรู้ | เปิด |
|---|---|
| **Data Framework** ของ MIS มีอะไรบ้าง | [[1 Data Framework/Framework Scope\|Framework Scope]] |
| **SSOT / Customer 360** เป้าหมายคืออะไร ลำดับยังไง | [[1 Data Framework/Objectives & SSOT Roadmap\|Objectives & SSOT Roadmap]] |
| **AWS** สถาปัตยกรรมเป็นยังไง | [[2 AWS Data Lake/Architecture\|Architecture]] |
| **AWS** ตอนนี้ถึงไหน ต้องทำอะไรต่อ | [[2 AWS Data Lake/Status & Phases\|Status & Phases]] |
| ตกลงอะไรไปแล้ว | [[2 AWS Data Lake/Decisions\|Decisions]] |
| ติดอะไรอยู่ | [[2 AWS Data Lake/Open Questions & Risks\|Open Questions & Risks]] |
| ระบบไหนเก็บอะไร ใครดูแล | [[3 Source System Survey/System Inventory\|System Inventory]] |
| **ลูกค้าซ้ำ** แก้ยังไง | [[4 SSOT & Customer 360/Customer Identity\|Customer Identity]] |
| **PDPA** ติดตรงไหน | [[4 SSOT & Customer 360/Consent & PDPA\|Consent & PDPA]] |
| งาน **K2 + ITOS** ถึงไหน | [[5 Sub-Projects/K2 + ITOS Integration\|K2 + ITOS Integration]] |
| งาน **GI + EV7 → 7Club** ถึงไหน | [[5 Sub-Projects/GI + EV7 to 7Club\|GI + EV7 → 7Club]] |
| เขียน Glue job ยังไง | [[6 Technical/ETL & Spark\|ETL & Spark]] |
| ศัพท์นี้แปลว่าอะไร | [[7 Reference/Glossary\|Glossary]] |

---

## 3 ปัญหาที่ยากจริง

1. **[[4 SSOT & Customer 360/Customer Identity|Customer Identity]]** — ลูกค้าคนเดียวอยู่หลายระบบคนละ ID · Gap Review `ARC-02` ระบุว่ายังไม่มีกลไกรวม
2. **[[4 SSOT & Customer 360/Consent & PDPA|Consent & PDPA]]** — Data Framework บอกว่า consent เป็นของแต่ละบริษัท แต่แผนต้องการรวมทั้งเครือ **สองข้อนี้ขัดกัน**
3. **[[4 SSOT & Customer 360/Data Standardization & Quality|Data Standardization]]** — แต่ละระบบตั้งชื่อและเก็บข้อมูลคนละแบบ พิสูจน์แล้วจากงานรวม K2 กับ ITOS

---

## ตัวเลขที่ยืนยันแล้ว

| | | ที่มา |
|---|---|---|
| Region เป้าหมาย | ap-southeast-7 (Bangkok) | AWS Proposal |
| ขนาด lake | 30 TB | AWS Proposal |
| ข้อมูลเข้า / ออก | ~50 GB/วัน · ~1 TB/วัน | AWS Proposal |
| Pipeline | ~30 เส้น | AWS Proposal |
| Survey เสร็จ | **1 จาก 11 ระบบ** | Project Timeline |
| ความพร้อมข้อมูลลูกค้า | **9 มี / 17 ไม่พอ / 62 ขาด (จาก 88)** | Customer Data Gap Review |
| ช่วงเวลา | ส.ค. 2569 – ก.พ. 2570 | Project Timeline |

---

## กติกาการเขียน

ทุกข้อความต้องบอกได้ว่ามาจากไหน ใช้ 2 ระดับ:

- **ข้อความปกติ** = มาจากเอกสารต้นฉบับ มีบอกที่มา
- **`[อนุมาน]`** = สรุปเอง ไม่ได้เขียนไว้ในเอกสาร เก็บไว้เพราะช่วยตัดสินใจ

ถ้าไม่มีหลักฐาน ให้เขียนว่า **ไม่รู้** ห้ามเดา

> **บทเรียน:** vault เวอร์ชันแรกมีข้อมูลผิดเพราะไปอ้าง `D:\aws\README.md` ซึ่งเป็นไฟล์ที่ AI เขียนเอง ทำให้ตัวเลขอย่าง "1,000 สาขา" และ "สมาร์ทโฟน 60% ของรายได้" หลุดเข้ามาทั้งที่ไม่มีในเอกสารจริง — **อ้างเฉพาะเอกสารต้นทาง ห้ามอ้างไฟล์สรุป**

**สถานะข้อมูลระบบ** ใช้ 4 ระดับ อย่าเลื่อนขั้นเองโดยไม่มีหลักฐานใหม่:
Confirmed · Partially Confirmed · To Verify · ต้องให้ legal ตอบ

---

*ที่มาข้อมูลทั้งหมด: [[7 Reference/Source Inventory|Source Inventory]]*
