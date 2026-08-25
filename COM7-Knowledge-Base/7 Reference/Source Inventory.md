# Source Inventory

ที่มาของข้อมูลทุกอย่างใน vault นี้ · สำรวจ 2026-08-24
**ไฟล์ต้นทางถูกอ่านอย่างเดียว ไม่มีการแก้ไข**

---

## ⚠️ กติกาสำคัญ

**อ้างเฉพาะเอกสารต้นทาง ห้ามอ้างไฟล์สรุปที่ AI เขียน**

`D:\aws\README.md` เป็นไฟล์ที่ AI เขียน (ท้ายไฟล์ระบุว่า *"สร้างและปรับปรุงร่วมกับ Claude"*) ไม่ใช่เอกสารบริษัท

vault เวอร์ชันแรกอ้างไฟล์นี้เป็นแหล่งข้อมูล ทำให้ข้อความต่อไปนี้หลุดเข้ามาทั้งที่**ไม่มีในเอกสารจริง**: "1,000 สาขา" · "สมาร์ทโฟน 60%+ ของรายได้" · "Lifestyle Technology Ecosystem" · "New S-Curve" · "iCare COVER+ ร่วมกับ Apple" · "EV7 เช่ารถ EV สำหรับผู้ประกอบการขนส่ง"

ข้อความเหล่านี้ถูกลบออกแล้ว

---

## เอกสารต้นทางที่ใช้

| # | ที่ | เนื้อหา | ใช้ทำอะไร |
|---|---|---|---|
| 1 | `D:\Clickuptask\` (9 ไฟล์) | ClickUp task export — PoC issue log, datacleanplan, K2&ITOS, GI+EV7, VPN, GuardDuty, Redshift, Bronze/Silver/Gold, S3 design | บันทึกสถานะและปัญหาปัจจุบันที่ละเอียดที่สุด |
| 2 | `D:\Consent_PDPA\COM7 Group Data Framework.pptx` | 16 สไลด์ — framework ทางการของ MIS | ขอบเขต 6 เรื่อง, หลัก consent, CRM current vs propose, customer tracking |
| 3 | `D:\Consent_PDPA\พระราชบัญญัติPDPA.PDF` | ตัวบท PDPA ฉบับเต็ม | มาตราที่กระทบการออกแบบ |
| 4 | `D:\ITOS\` (61 ไฟล์) | Schema wiki ของ `ILOAN_COLLECTION` 55 tables พร้อม sample rows | จำนวนแถว, column, `M_COMPANY`, `M_CHANNEL` |
| 5 | `D:\EV_GI_database\schema.prisma` | 166 models, MySQL | โครงสร้าง GI Core, nullability ของ match key |
| 6 | `D:\aws\Proposal - COM7 Internal Data Lake.pdf` | 12 หน้า · AWS Solution Architect | สถาปัตยกรรมเป้าหมาย, sizing, ingestion paths, security |
| 7 | `D:\aws\COM7 Customer Data Gap Review updated.xlsx` | 5 ชีต · 88 รายการตรวจ | ความพร้อมข้อมูลลูกค้า, ช่องว่างสถาปัตยกรรม, priority |
| 8 | `D:\aws\etl-lab\athena performance.xlsx` + `.pptx` | 45 query runs | ผลวัด performance จริง |
| 9 | `D:\Project Timeline _ Data Team.xlsx` | Timeplan · 11 ระบบ + phase | สถานะ survey, เจ้าของ, ลำดับ phase |
| 10 | `D:\Azure\` (2 PDF โดย Alphametrics) | คู่มือและ training Azure Synapse | เอกสาร platform เดิม |
| 11 | `C:\Projects\Data-Team-Code\` | SQL ที่ทีมใช้จริง + บันทึกออกแบบ AWS (Medalion Archetecture, POC_reveiw) | ชื่อฐานข้อมูลจริง, นิยาม layer, คิวรี่ union K2/ITOS |

---

## สิ่งที่เจอเพราะตามไปดูตามที่เอกสารอ้างถึง

| เจอ | เจอจาก | ทำไมสำคัญ |
|---|---|---|
| `D:\Project Timeline _ Data Team.xlsx` | กวาดหาไฟล์ชื่อ Timeline | tracker ที่ใช้งานจริง — เป็นแกนของ System Inventory |
| **Tech Trade** | Timeline 1.2.2 + Gap Review DEV-04 | BU/ระบบที่ไม่อยู่ใน brief เดิม เป็นเจ้าของข้อมูลเทิร์นเครื่อง |
| **Braze** | Data Framework slide 8 + Gap Review ARC-01 | platform activation ปัจจุบัน และเป็นประเด็นว่าไม่ใช่ CDP |
| `M_COMPANY` มีรายชื่อบริษัท 18 รายการ | อ่าน table wiki ของ ITOS | **ยืนยันว่า TFF เป็นนิติบุคคล** — สำคัญต่อเรื่อง consent |
| `M_CHANNEL` เป็นช่องทางชำระเงิน | อ่าน table wiki ของ ITOS | **Dtac ในนี้คือจุดรับชำระ ไม่ใช่ร้านในเครือ** — แก้ความเข้าใจผิดจาก brief |
| `D365FO_DATALAKE`, `syndpdev001` | SQL ใน Data-Team-Code | ชื่อฐาน/server จริงเบื้องหลัง D365 และ Synapse |
| `ILOAN_DATASOURCE`, `HPCOM7` | คิวรี่ union K2/ITOS | ฐานจริงของ ITOS และ K2 |
| AION DMS, EV7CORE, EVTRACKING | ClickUp GI+EV7 | ระบบฝั่ง EV ที่ทับซ้อนกัน |

---

## ตรวจแล้วไม่ใช้

| ที่ | เหตุผล |
|---|---|
| `D:\aws\README.md`, `readme.txt` | **ไฟล์ที่ AI เขียน ไม่ใช่เอกสารบริษัท** |
| `D:\EV_GI_database\node_modules\` | dependency ไม่มีข้อมูลธุรกิจ |
| `C:\Projects\Data-Team-Code\.vs\`, `.git\` | ไฟล์ภายในของ IDE/VCS |
| `D:\aws\Test_Spark\`, `D:\aws\etl-lab\` (โค้ด) | lab ฝึก ETL ส่วนตัว ไม่ใช่ production ของ COM7 — อ้างเฉพาะปัญหา Spark ANSI mode ที่เจอจริง และระบุที่มาไว้ชัด |
| `D:\UI Guideline.pptx` | ไม่เกี่ยวกับสถาปัตยกรรมข้อมูล |
| `C:\Projects\my-first-project\` | repo ฝึก Git มีแค่ query ITOS 1 อัน |

---

## เอกสารที่ถูกอ้างถึงแต่หาไม่เจอ

- `COM7-DataLake-Project-Timeline.xlsx` — `D:\aws\README.md` อ้างว่ามี 9 phase 50 subtask **ไม่มีบนดิสก์** และ README นั้นเป็นไฟล์ที่ AI เขียน จึงไม่ยืนยันว่าไฟล์นี้เคยมีจริง
- `crm_fied_description.html` — CRM data dictionary ที่บันทึกประชุม GI+EV7 ระบุ
- **ITEC schema / data dictionary** — survey เป็น Done แต่ไม่พบเอกสาร
- **K2 data dictionary** — ClickUp ระบุว่าได้จากพี่เนตรแล้ว แต่ไม่อยู่ในโฟลเดอร์ที่ตรวจ
- Architecture diagram (Figure 1) จาก AWS proposal — เป็นรูปภาพ

---

## ประวัติการแก้ vault

| วันที่ | ทำอะไร |
|---|---|
| 2026-08-24 | สร้างครั้งแรก 95 ไฟล์ 10 โฟลเดอร์ |
| 2026-08-24 | จัดใหม่เหลือ 23 ไฟล์ 5 โฟลเดอร์ (รวมโน้ตที่ทับซ้อน) |
| 2026-08-24 | **ตรวจสอบความถูกต้องทั้งหมด** — ลบข้อมูลที่มาจากไฟล์สรุปของ AI, แยก `[อนุมาน]` ออกจากข้อเท็จจริง, เพิ่มข้อมูลจาก `M_COMPANY` และ `M_CHANNEL` ที่ควรอ่านตั้งแต่แรก |

---

## อ่านต่อ

[[../3 Source System Survey/System Inventory|System Inventory]] · [[../1 Data Framework/Objectives & SSOT Roadmap|Objectives & SSOT Roadmap]] · [[People & Teams]] · [[Glossary]]
