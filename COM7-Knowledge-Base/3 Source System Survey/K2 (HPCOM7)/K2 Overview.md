# K2 (HPCOM7) — Overview

Survey **Done** · สำรวจจากฐาน `HPCOM7` โดยตรงเมื่อ **2026-08-26** ด้วยสิทธิ์ read-only
ระบบเช่าซื้ออุปกรณ์ IT ของ **TFF — บริษัท ธันเดอร์ ฟินฟิน จำกัด** (เจ้าของระบบฝั่งงาน: MIS-Fintech)

> ตัวเลขและชื่อคอลัมน์ทุกอย่างในโฟลเดอร์นี้มาจากการ query ฐานจริง ไม่ใช่จากเอกสาร
> ยกเว้น [[Business Rules]] ที่มาจากเอกสารความรู้ของทีม แล้ว**ตรวจกับฐานจริงทุกข้อ**
> ไฟล์ดิบอยู่ในโฟลเดอร์ `_raw/` (`tables.csv`, `columns.csv`, `indexes.csv`, `foreign_keys.csv`, `views.csv`, `samples-masked.md`) · สคริปต์ `C:\Projects\my-first-project\k2_survey.py` และ `k2_samples.py`

---

## เปิดตรงไหน

| อยากรู้ | เปิด |
|---|---|
| **ขอที่อยู่ของลูกค้าคนนี้** / ค้นจากชื่อ / ดูสัญญา | [[Query Cookbook]] |
| **กฎธุรกิจ** — วันชำระ · งวดไหนจ่ายแล้ว · OD · ผู้ค้ำ | [[Business Rules]] |
| **ทำหนังสือบอกเลิกสัญญา** — ดึงอะไรจากไหน · คัดใครบ้าง | [[Termination Letter Mapping]] |
| **ค่าปรับ · ค่าติดตาม · การตัดรับชำระ** คิดยังไง | [[Fee Policy]] |
| **คัดใครเข้าเกณฑ์บอกเลิกสัญญา** — ตรรกะ + SQL ทีละบรรทัด | [[OD6 Selection Logic]] |
| ตารางไหนเก็บอะไร มีกี่แถว | [[Table Inventory]] |
| ลูกค้าเก็บที่ไหน · เลขบัตร · ที่อยู่ 5 ชุด | [[Customer & Address]] |
| สัญญาเช่าซื้อ · สถานะ · บัญชี GL | [[Contract & Account]] |
| ค่างวด · ใบแจ้งหนี้ · การรับชำระ | [[Payment & Invoice]] |
| หนี้ค้าง · การมอบหมายทวงถาม | [[Collection & OD]] |
| รหัสสถานะ · จังหวัด · แบรนด์ · ธนาคาร | [[Master & Setup]] |

---

## K2 ทำอะไร

ลูกค้าเดินเข้าร้านในเครือ COM7 (Studio7 / BaNANA) เลือกเครื่อง → ขอสินเชื่อเช่าซื้อกับ TFF → K2 คือระบบที่รับใบเสนอราคา อนุมัติ ทำสัญญา ออกใบแจ้งหนี้รายงวด รับชำระ ลงบัญชี และติดตามหนี้

```
QUOTATION  ──►  APPLICATION  ──►  CONTRACT  ──►  CUSTOMER_CARD  ──►  INVOICE  ──►  REPAYMENT  ──►  ACCOUNT
 801,188         410,306          288,205        5,816,540          4,396,632     5,205,081      25,977,656
ใบเสนอราคา       ใบคำขอสินเชื่อ      สัญญาเช่าซื้อ     ตารางผ่อนรายงวด      ใบแจ้งหนี้       การรับชำระ      ลงบัญชี GL

PROSPECT_CUSTOMER ─┘                    │
   800,283                              └──►  COLLECTION_OD  ──►  COLLECTION_OD_ASSIGNMENT
ผู้สนใจก่อนเป็นลูกค้า                              15,653,423             98,477
                                        snapshot หนี้ค้างรายวัน      มอบหมายให้ collector

PERSON (404,749) ──1:1──► ADDRESS (403,283)
ข้อมูลบุคคล                ที่อยู่ 4 ชุด + ที่ทำงาน  (รวม 5 ชุดในแถวเดียว)
```

**สิ่งที่ปล่อยกู้คือเครื่อง** — `MT_CATEGORY` มีแค่ Smart Phone · Tablet · Laptop
`MT_BRAND` = Apple · Samsung · Xiaomi · Vivo · OPPO · Realme (+ Apple UFicon)

---

## ตัวเลขที่ยืนยันแล้ว

| | | |
|---|---:|---|
| Tables | **542** | schema `dbo` ทั้งหมด ไม่มี schema อื่น |
| ตารางที่ใช้จริง | **364** | หลังตัด backup/temp/test/zero-row |
| Views | **165** | อ่าน definition ไม่ได้ (ไม่มีสิทธิ์) |
| **Foreign keys** | **16** | จาก 542 ตาราง — แทบไม่มี relation ประกาศไว้ |
| สัญญาทั้งหมด | 288,205 | ตั้งแต่ 2020-07-15 |
| บุคคลในระบบ | 404,749 | มีสัญญาจริง 288,195 |
| **เลขบัตรที่ไม่ซ้ำ** | **343,249** | จาก 404,627 แถวที่มีเลขบัตร |
| สัญญาที่ยังเดินอยู่ | 93,214 | สถานะ "ลูกหนี้ปกติ" |
| หนี้ค้าง snapshot ล่าสุด | ~120,579 สัญญา/วัน | `COLLECTION_OD` วันที่ 2026-08-26 |

### สัญญาต่อปี

| ปี | สัญญาใหม่ |
|---|---:|
| 2020 | 1,768 |
| 2021 | 28,725 |
| 2022 | 29,730 |
| 2023 | 27,121 |
| 2024 | 81,476 |
| 2025 | **102,809** |
| 2026 (ถึง ส.ค.) | 16,567 |

โต 3 เท่าในปี 2024 แล้วโตต่อในปี 2025 · ปี 2026 ชะลอลงชัดเจน `[อนุมาน]`

### สายผลิตภัณฑ์ — `CONTRACT.PROJECT_TYPE`

| ค่า | สัญญา |
|---|---:|
| NULL | 187,410 |
| **UFUND** | 95,758 |
| PARTNER | 3,818 |
| UFICON | 1,181 |
| SolarCell | 37 |
| UPHONE | 2 |

NULL คือสัญญาเก่าก่อนที่จะมีฟิลด์นี้ `[อนุมาน]` — **ห้ามใช้ `PROJECT_TYPE` แบ่งกลุ่มโดยไม่จัดการ NULL**

`COLLECTION_OD.PRODUCT_TYPE` แบ่งอีกแบบและครบกว่า: **Student 73,209 · Personal 47,370** (สัญญาที่มีหนี้ค้าง ณ 2026-08-26)
→ **UFund เป็นสินเชื่อเครื่องสำหรับนักศึกษาเป็นหลัก** สอดคล้องกับที่ `PERSON` มี `STUDENT_ID`, `UNIVERSITY_NAME`, `FACULTY_NAME`, `MT_FACULTY` (39,475 แถว), `MT_UNIVERSITY_NAME` (1,149)

### พาร์ทเนอร์ที่ขายเครื่อง — `SETUP_PARTNER`

| บริษัท | สัญญา |
|---|---:|
| บริษัท คอมเซเว่น จำกัด (มหาชน) | 283,144 |
| บริษัท ยูฟิคอน จำกัด | 2,968 |
| บริษัท เอส พี วี ไอ จำกัด (มหาชน) | 1,885 |
| บริษัท ไพร์ม โซลูชั่น แอนด์ เซอร์วิส จำกัด | 1 |
| NULL | 208 |

`SETUP_COMPANY` id 121 = **บริษัท ธันเดอร์ ฟินฟิน จำกัด** เลขนิติบุคคล `0105558011806` ทุนจดทะเบียน 150,000,000 บาท จดทะเบียน 2015-06-21

> ITOS สะกด **"ธันเดอร์ ฟิน ฟิน"** (มีเว้นวรรค) K2 สะกด **"ธันเดอร์ ฟินฟิน"** — เป็นตัวอย่างจริงของปัญหา standardization ที่ [[../../4 SSOT & Customer 360/Data Standardization & Quality|Data Standardization & Quality]] พูดถึง

---

## กฎคัดตารางขยะ

178 ตารางจาก 542 ถูกตัดออกจาก inventory ด้วยกฎนี้ (เขียนไว้ใน `k2_survey.py`):

| กฎ | ตัวอย่าง |
|---|---|
| row = 0 | `CUSTOMER_CARD_AR`, `MT_UPHONE_PERCENT_SRP_DG` |
| ลงท้าย `_BACKUP` `_Backup` `_BK` `_BAK` | `CUSTOMER_CARD_BACKUP`, `TTP_VAT_RPT_BAK` |
| ลงท้าย `_TEMP` `_TMP` `_TEST` `_DEMO` `_OLD` | `CUSTOMER_CARD_TEMP`, `CUSTOMER_CARD_TEST` |
| ลงท้ายวันที่ `_yymmdd` `_yyyymmdd` `_yyyy_n` | `CUSTOMER_CARD_220116`, `PROSPECT_CUSTOMER_20220105`, `REPORT_CUSTOMER_CARD_2023_3` |

`CUSTOMER_CARD` อย่างเดียวมีฝาแฝด 8 ตัว — **การเลือกตารางด้วยชื่ออย่างเดียวจะหยิบผิดตัวได้ง่ายมาก** ให้ยึด [[Table Inventory]]

---

## ข้อสังเกตระดับระบบ

**ไม่มี foreign key** — 16 ตัวจาก 542 ตาราง ความสัมพันธ์ทุกอย่างในโฟลเดอร์นี้มาจากการ **ทดสอบ join จริงแล้วนับแถว** ไม่ใช่จาก metadata ถ้าจะสร้าง ER diagram อัตโนมัติจากฐานนี้จะได้แค่ 16 เส้น

**ทำ incremental ได้** — `PERSON`, `CONTRACT`, `APPLICATION`, `QUOTATION`, `REPAYMENT` มี `CREATE_DATE` และ `UPDATE_DATE` ครบ (`PERSON.UPDATE_DATE` ล่าสุด 2026-08-26 14:06)
> แก้ข้อสรุปเดิมใน [[../UFUND (K2 & ITOS)|UFUND (K2 & ITOS)]] ที่บอกว่า "ดึง incremental ด้วย timestamp จาก K2 ไม่ได้" — ข้อสรุปนั้นมาจากดู `COLLECTION_OD_ASSIGNMENT` ตารางเดียวซึ่งเป็น extract ไม่ใช่ตารางต้นทาง **ตารางต้นทางมี timestamp**

**collation เป็น `SQL_Latin1_General_CP1_CI_AS`** ทั้งฐาน แม้คอลัมน์จะเป็น `nvarchar` — เก็บภาษาไทยได้ปกติ แต่ต้องใส่ `N''` นำหน้า literal ทุกครั้งที่เทียบภาษาไทย และตอน UNION กับ ITOS ต้อง `COLLATE DATABASE_DEFAULT` ตามที่ [[../../6 Technical/SQL & Source Schemas|SQL & Source Schemas]] เขียนไว้

**สิทธิ์ที่ user `sapon.s` ไม่มี** — `VIEW SERVER STATE` (อ่าน `sys.dm_db_index_usage_stats` ไม่ได้ จึงบอกไม่ได้ว่าตารางไหน application อ่านจริง ต่างจากที่ทำกับ ITOS ได้) และ `VIEW DEFINITION` (อ่าน SQL ของ view 165 ตัวไม่ได้)

**`MS_Description` ไม่มีทั้งฐาน** เหมือน ITOS — ไม่มี data dictionary ในฐาน

---

## Typo ที่อยู่ใน production แล้ว

นอกจาก `PRODUDCT_ID` และ `PRINCIPLE` ที่ vault บันทึกไว้แล้ว survey เจอเพิ่ม:

| ที่ควรเป็น | ที่มีจริง | อยู่ที่ |
|---|---|---|
| `IMPORT` | `BANK_IMPRORT` | ชื่อตาราง |
| `VOUCHER_NO` | `VOURCHER_NO` | `ACCOUNT` |
| `ACCOUNT_DESCRIPTION` | `ACCOUNT_DESCIPTION` | `ACCOUNT`, `ACCOUNT_RECEIVABLE` |
| `CONTRACT_NUMBER` | `CONTARCT_NUMBER` | `CONTACT_DEBT_COLLECTION` |
| `LIVING_TIME` | `A1_LIVEING_TIME` | `ADDRESS` (ทั้ง 5 ชุด) |
| `MOO` (หมู่) | `A1_MOI` | `ADDRESS` (ทั้ง 5 ชุด) |
| `GUARANTOR` | `GAURANTOR_FLAG` | `NCAP_INFORMATION` |

ต้อง map ให้ถูกที่ Bronze แก้ต้นทางไม่ได้แล้ว

---

## คำถามที่ยังเปิด

- `CreditScrolling_Logs_Contract` **239.7 ล้านแถว** เป็นตารางใหญ่สุดของฐาน มี 15 คอลัมน์ (`CONTRACT_ID`, `STATUS_ID`, `CreditScrolling_Logs_Contract_DateTime`) เข้าเค้าว่าเป็น log การเปลี่ยนสถานะสัญญา `[อนุมาน]` — แต่ 239M แถวต่อ 288k สัญญา = เฉลี่ย 832 แถวต่อสัญญา **มากผิดปกติ ต้องถาม MIS-Fintech ว่าเขียนทุกกี่วินาที และต้อง ingest ไหม**
- **`EGG_*` 65 views** จาก 165 views ทั้งหมด (`EGG_PERSON`, `EGG_ADDRESS`, `EGG_MDM`, `EGG_BANK_STATEMENT`) — "EGG" คือระบบอะไร นี่คือ integration layer ที่มีอยู่แล้วหรือเปล่า อ่าน definition ไม่ได้เพราะไม่มีสิทธิ์
- `UFUNDInterface` (2,029,152 แถว) มีคอลัมน์ `Payload`, `URL`, `Status`, `PostingDate` = คิว API ส่งออก — ส่งไปที่ไหน
- `NCAP_*` (`NCAP_PAYMENT` 2M, `NCAP_STATUS` 1M, `NCAP_INFORMATION` 132k) — NCAP คืออะไร `NCAP_INFORMATION` มี `FULL_NAME`, `TAX_ID`, `ADDRESS_REGIST`, `INCOME` ครบ เข้าเค้าว่าเป็น interface กับสถาบันการเงินภายนอก `[อนุมาน]`
- `HPAP_*` (100–200 แถว) กับ `*_PFUND` / `*_UPHONE` — ผลิตภัณฑ์ที่ยังไม่ launch หรือเลิกแล้ว
- `CIF_PERSON_ID` มีอยู่ในหลายตารางแต่ **ว่าง 404,645 จาก 404,749 แถว** — ตั้งใจจะทำ CIF แล้วไม่ได้ทำ หรือกำลังจะทำ ถ้าจะทำจริงนี่คือจุดที่ควรเสียบ SSOT key
- ยังไม่ได้เทียบว่าสัญญาใน K2 ซ้ำกับ ITOS ไหม — คำถามเดิมที่ยังเปิดอยู่
- `COLLECTION_OD` เก็บ snapshot ตั้งแต่ 2026-04-08 (ตารางถูกสร้างวันนั้น) — ก่อนหน้านั้นเก็บที่ไหน `Temp_History_OD` (5,067,003) ใช่หรือเปล่า

---

## อ่านต่อ

[[../UFUND (K2 & ITOS)|UFUND (K2 & ITOS)]] · [[../System Inventory|System Inventory]] · [[../../4 SSOT & Customer 360/Customer Identity|Customer Identity]] · [[../../5 Sub-Projects/K2 + ITOS Integration|K2 + ITOS Integration]] · [[../../6 Technical/SQL & Source Schemas|SQL & Source Schemas]]
