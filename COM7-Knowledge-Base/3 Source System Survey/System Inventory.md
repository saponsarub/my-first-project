# System Inventory

อัปเดต 2026-08-24 · ที่มา: `D:\Project Timeline _ Data Team.xlsx` + เอกสารประกอบ

**ห้ามเดาใส่ช่องว่าง** ไม่รู้ให้เขียนว่าไม่รู้

---

## สถานะ Survey

จาก Project Timeline — แบ่งเป็น Main System (1.1) กับ Other Legacy System (1.2)

| Ref | ระบบ | สถานะ | ผู้รับผิดชอบ |
|---|---|---|---|
| 1.1.1 | [[ITEC]] | **Done** | Data Team |
| 1.1.2.1 | [[UFUND (K2 & ITOS)\|K2]] (UFund) | **Done** (survey ฐานจริง 2026-08-26) | MIS-Fintech |
| 1.1.2.2 | [[UFUND (K2 & ITOS)\|ITOS]] (UFund) | In-Progress | K.Ton |
| 1.1.3 | [[EV Business (GI Core & EV7)\|GI Core]] | Todo | Punt, Nut |
| 1.1.4 | [[Other Systems\|D365]] | Todo | MIS-ERP |
| 1.1.5 | [[EV Business (GI Core & EV7)\|EV7]] | Todo | **ไม่มีชื่อในตาราง** |
| 1.1.6.1 | [[Other Systems\|iCare]] — Insurance | Todo | P.Pui |
| 1.1.6.2 | [[Other Systems\|iCare]] — Mobile Service | Todo | P.Pui |
| 1.1.7 | [[Other Systems\|SAP B1]] | Todo | K.Benz |
| 1.2.1 | [[Customer Platforms (CRM, 7Club, Braze)\|7Club+/CRM]] | Todo | P.Por |
| 1.2.2 | [[Other Systems\|Tech Trade]] | Todo | K.Koj, K.Poj |

**เสร็จ 2 จาก 11** — งานนี้เป็นคอขวดของทุกอย่าง

> K2 เลื่อนจาก In-Progress เป็น Done เพราะสำรวจฐาน `HPCOM7` โดยตรงครบ 542 tables เมื่อ 2026-08-26 ผลอยู่ที่ [[K2 (HPCOM7)/K2 Overview|K2 (HPCOM7)]] — **ยังไม่มีเอกสารจาก MIS-Fintech ยืนยัน** สถานะนี้อ้างจากการสำรวจของทีมเราเอง

---

## ตารางระบบ

| ระบบ | ธุรกิจ | ทำอะไร | สถานะ | ที่มา |
|---|---|---|---|---|
| [[ITEC]] | ค้าปลีก IT | ฐานข้อมูลหลักธุรกิจค้าปลีก · เป็นระบบเดียวที่ป้อนข้อมูลเข้า CRM ตอนนี้ | Confirmed | Timeline · Data Framework · SQL |
| [[K2 (HPCOM7)/K2 Overview\|K2]] | สินเชื่อเช่าซื้อ IT **(legacy — ปิดสิ้นปี 2026)** | ฐาน `HPCOM7` · **542 tables · 288,205 สัญญา · 343,249 เลขบัตรไม่ซ้ำ** · กลุ่มหลักคือนักศึกษา | **Confirmed** | survey ฐานจริง 2026-08-26 |
| [[UFUND (K2 & ITOS)\|ITOS]] | สินเชื่อ (collection) | `ILOAN_COLLECTION` 55 tables · ลูกค้า 165,722 ราย | Confirmed | schema wiki |
| [[EV Business (GI Core & EV7)\|GI Core]] | EV / AION | ระบบหลักปัจจุบันฝั่ง GI · MySQL 166 Prisma models | Confirmed | schema.prisma · ClickUp |
| [[Other Systems\|D365]] | ERP / GI เก่า | ข้อมูลผ่าน `D365FO_DATALAKE` | To Verify | Timeline · SQL |
| AION DMS | GI | ระบบ vendor — บันทึกประชุมเขียนว่า "ของจีน" | To Verify | ClickUp |
| EV7CORE | EV7 | ระบุเป็นระบบแยกในปัญหาข้อมูลซ้ำ | To Verify | ClickUp |
| EVTRACKING | EV7 / GI | ยังมีบางรายการของ GI ค้างอยู่หลังโอนไป EV7 | To Verify | ClickUp |
| [[Other Systems\|iCare]] | ประกัน + mobile service | survey แยก 2 track | To Verify | Timeline |
| [[Other Systems\|SAP B1]] | ERP | ไม่รู้ว่า BU ไหนใช้ | To Verify | Timeline |
| [[Customer Platforms (CRM, 7Club, Braze)\|7Club]] | membership | โปรแกรมสมาชิก · survey รวมกับ CRM | To Verify | Timeline · Data Framework |
| [[Customer Platforms (CRM, 7Club, Braze)\|CRM]] | ลูกค้า / แคมเปญ | ครอบคลุมแค่ ITEC · ส่งต่อให้ทีม CRM ใช้ Braze | Partially Confirmed | Data Framework |
| [[Other Systems\|Tech Trade]] | เทิร์นเครื่อง | ถือประวัติและสิทธิ์เทิร์น · **ไม่อยู่ใน brief เดิม** | To Verify | Timeline · Gap Review |
| [[Other Systems\|Azure Synapse]] | analytics เดิม | `syndpdev001` · รับจาก SharePoint 365 + ADLS · กำลังย้ายมา AWS | Confirmed (เป็น source ของ migration) | PDF ของ Alphametrics · PoC |
| [[Customer Platforms (CRM, 7Club, Braze)\|Braze]] | ส่งข้อความ/แคมเปญ | ทีม CRM ใช้ทำ promotion และ loyalty | Confirmed | Data Framework |

---

## ฐานข้อมูลที่เจอใน SQL แต่ยังไม่รู้บทบาท

| ชื่อ | ใช้กับ | สถานะ |
|---|---|---|
| `PROJECT_1` | view ของ ITEC (`view_itec_payment`) | ไม่รู้ว่าเป็น source หรือชั้น reporting |
| `TAN_MIS` | query ของ MIS | ไม่รู้ |
| `ILOAN_DATASOURCE` | extract ของ ITOS | น่าจะเป็นชั้น extract เหนือ ITOS `[อนุมาน]` |
| `HPCOM7` | K2 ทั้งระบบ | **ยืนยันแล้ว** — เป็นฐานจริงของ K2 สำรวจครบ 2026-08-26 |
| `D365FO_DATALAKE` | inventory/purchasing ของ D365 | เป็น data lake export ของ D365 F&O `[อนุมาน]` |
| `syndpdev001` | item master, sales/purchase invoice | น่าจะเป็น Synapse dev endpoint `[อนุมาน]` |

---

## รายชื่อบริษัทจาก ITOS

ตาราง `M_COMPANY` มี 18 แถว ตัวอย่าง 10 แถวแรกจาก schema wiki:

| Code | ชื่อ |
|---|---|
| **TFF** | **บริษัท ธันเดอร์ ฟิน ฟิน จํากัด (THUNDER FINFIN Co.,LTD.)** |
| BaNANA | BaNANA |
| BKK | BKK |
| UFicon | UFicon |
| Samsung | Samsung |
| Studio7 | Studio 7 |
| U-Store | U-Store |
| Kingkong | Kingkong |
| SPVI | SPVI |
| BN | BN-POP, BN-Stand Alone |

**ข้อสังเกตสำคัญ:** นี่คือ *บริษัท/ร้านที่เกี่ยวข้องกับสัญญาสินเชื่อในระบบ ITOS* ไม่ใช่ "รายชื่อ BU ของ COM7" — Samsung และ SPVI เป็นคนละบริษัท การใช้ตารางนี้เป็นรายชื่อ BU จะผิด `[อนุมาน]`

**สิ่งที่ตารางนี้ยืนยันได้:** **TFF เป็นนิติบุคคลจริง** ชื่อ "บริษัท ธันเดอร์ ฟิน ฟิน จำกัด" — สำคัญต่อเรื่อง consent เพราะ Data Framework กำหนดว่า consent เป็นของแต่ละบริษัท

---

## ช่องทางชำระเงินจาก ITOS

ตาราง `M_CHANNEL` มี 7 แถว:

| Type | ช่องทาง |
|---|---|
| B (ธนาคาร) | ธนชาติ · กรุงศรี · กรุงไทย |
| O (อื่น) | Counter Service · True Money · Tesco Lotus · Dtac |

**ข้อสังเกต:** **Dtac ในนี้คือจุดรับชำระเงิน ไม่ใช่ร้านในเครือ COM7** — brief เดิมระบุ "Dtac Shop" เป็น BU แต่ในข้อมูลจริงที่เจอ Dtac ปรากฏเป็น payment channel เท่านั้น ยังไม่มีหลักฐานว่า Dtac Shop เป็น BU

---

## BU ที่ยังไม่มีหลักฐาน

Brief เดิมระบุ **Double7**, **Co-Ture Shop**, **Dtac Shop** เป็น business unit

**ไม่พบชื่อเหล่านี้ในเอกสารต้นฉบับไฟล์ไหนเลย** (ค้นใน ClickUp, Data Framework, Gap Review, Timeline, ITOS wiki, AWS Proposal)

อาจเป็นได้ว่า: ใช้ระบบที่มีในรายการอยู่แล้วภายใต้ชื่ออื่น · ยังไม่ถูกนำเข้า scope · หรือชื่อในเอกสารต่างจากชื่อที่ใช้พูด — **ต้องถามคน ไม่ใช่เดา**

---

## จัดกลุ่มตามปัญหา

**ระบบทับซ้อนกันฝั่ง EV:** D365 · GI Core · AION DMS · EV7CORE · EVTRACKING

**กำลังรวมเป็นระบบเดียว:** K2 + ITOS

**ถือข้อมูลลูกค้าและต้อง reconcile:** ITEC · K2 · ITOS · GI Core · iCare · 7Club · CRM · Tech Trade

**ข้อมูลวงจรชีวิตอุปกรณ์** (Gap Review จัดเป็นช่องว่างอันดับ 1): ITEC (การซื้อ, อุปกรณ์เสริม) · iCare (ประกัน, ซ่อม) · Tech Trade (เทิร์น) · ทะเบียนอุปกรณ์ (ยังไม่มี)

---

## อ่านต่อ

[[../1 Data Framework/Objectives & SSOT Roadmap|Objectives & SSOT Roadmap]] · [[../2 AWS Data Lake/Status & Phases|Status & Phases]] · [[../7 Reference/People & Teams|People & Teams]] · [[../7 Reference/Source Inventory|Source Inventory]]
