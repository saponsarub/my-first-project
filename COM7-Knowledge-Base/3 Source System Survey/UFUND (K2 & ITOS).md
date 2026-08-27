# UFUND (K2 & ITOS)

Survey — **K2 Done (2026-08-26)** · ITOS Done · K2 โดย MIS-Fintech · ITOS โดย K.Ton

> **K2 กำลังถูกเลิกใช้** — ประชุม 2026-08-27 ระบุว่า migrate ไป ITOS ครบ 100% ภายในสิ้นปี 2026 ยกเว้น UFUND Student → [[../4 SSOT & Customer 360/UFUND in Customer 360|UFUND in Customer 360]]

---

## โครงสร้างที่ Timeline ระบุ

```
1.1.2   TFF
1.1.2.1   UFund → K2      (MIS-Fintech)
1.1.2.2   UFund → ITOS    (K.Ton)
```

TFF เป็นร่ม UFund อยู่ใต้ และ K2/ITOS คือระบบ

**ตาราง `M_COMPANY` ใน ITOS ยืนยันว่า TFF เป็นนิติบุคคลจริง:**
`TFF` = **บริษัท ธันเดอร์ ฟิน ฟิน จํากัด (THUNDER FINFIN Co.,LTD.)**

สำคัญต่อเรื่อง consent เพราะ Data Framework กำหนดว่า consent เป็นของแต่ละบริษัท

Gap Review ระบุเจ้าของ field identity ของ K2/ITOS ว่า **"Thunder"**

---

## ITOS

**Physical:** MSSQL ฐาน `ILOAN_COLLECTION`
**Extract layer:** `ILOAN_DATASOURCE.dbo.ITOS_COLLECTION_DETAIL` และ `ITOS_COLLECTION_PORTFOLIO`
**Schema wiki generated:** 2026-05-04 · มี 55 tables

หมายเหตุใน wiki: *"167 tables were omitted because they are zero-row or excluded by naming rules (BK_*, *_BK, or names ending with digits)"*

### ตารางหลัก

| Table | แถว | Columns |
|---|---:|---:|
| `S_PMTSCHDLE` | 3,768,675 | 16 |
| `S_CUSTADDR` | 746,916 | 19 |
| `S_ADDRESS` | 663,728 | 27 |
| `S_CUSTTEL` | 371,323 | 13 |
| `S_CUSTEMAIL` | 370,828 | 6 |
| `T_NOTE` | 277,694 | 109 |
| `S_COLLECTRESP` | 166,189 | 10 |
| `S_CONTRACT` | 165,723 | 71 |
| **`S_CUSTOMER`** | **165,722** | **67** |
| `S_ASSET` | 165,723 | 44 |
| `S_CONTRACTCUST` | 165,723 | 11 |
| `S_INSURANCE` | 165,723 | 10 |
| `S_FINANCE` | 165,547 | 78 |
| `S_OUTSTANDING` | 165,094 | 48 |
| `R_SNAP` | 83,075 | 48 |
| `S_COLLECTIONFEE` | 37,750 | 18 |
| `T_JOBTRANS` | 15,684 | 61 |

ตาราง master: `M_AREA` (7,488) · `M_DISTRICT` (7,460) · `M_COMPANYBRANCH` (1,741) · `M_BUCKETAREA` (1,737) · `M_AMPHUR` (929) · `M_ROAD` (745) · `M_HOLIDAY` (730) · `M_PROVINCE` (80) · `M_COMPANY` (18) · `M_PRODUCT` (16) · `M_CHANNEL` (7)

### `S_CUSTOMER` — 67 columns

Field ที่เกี่ยวกับการระบุตัวตน:

- `CUST_ID` (int, NOT NULL) · `CUST_CODE` (nvarchar 500, NOT NULL)
- ชื่อไทย: `CUST_TITLETH`, `CUST_NAMETH`, `CUST_LASTNAMETH`
- ชื่ออังกฤษ: `CUST_TITLEEN`, `CUST_NAMEEN`, `CUST_LASTNAMEEN`
- `CUST_BIRTHDATE` (date)
- `CUST_GENDER`, `CUST_RACE`, `CUST_NATIONALITY`, `CUST_MARITALSTATUS`
- **`CUST_CARDTYPE`, `CUST_CARDNO`** — เลขบัตร
- `CUST_CARDISSUEDATE`, `CUST_CARDEXPIREDATE`, `CUST_CARDISSUEPLACE`
- `CUST_TAXNO`
- อาชีพ: `CUST_OCCUPATION`, `CUST_COMPANY`, `CUST_DEPT`, `CUST_POSITION`, `CUST_NOOFYEAR`, `CUST_NOOFMONTH`
- **รายได้: `CUST_SALARY`, `CUST_OTHERINCOME`, `CUST_INCOMEYEAR`** (numeric 18,2)
- **คู่สมรส: `CUST_SP_*`** (ไทย + อังกฤษ)
- **รหัส ธปท.: `CUST_BOTCUSTCODE`, `CUST_BOTCODE`, `CUST_BOTINSTCODE`**

### ข้อสังเกต

**มีข้อมูลบุคคลที่สาม** — คู่สมรส (`CUST_SP_*`) และผู้ค้ำประกัน (ใน collection extract) คนเหล่านี้ไม่ได้ทำสัญญากับ COM7 โดยตรง
*ล่าสุดมีความเห็นว่าน่าจะไม่ใช้ข้อมูลผู้ค้ำประกันเพราะไม่ใช่ลูกค้าจริง — รอ legal ยืนยัน*

**มีข้อมูลรายได้** — salary, other income, annual income

**BOT compliance เป็นเรื่องจริง** — 3 field รหัส ธปท. ยืนยันว่ามีภาระรายงานต่อ ธปท. นอกเหนือจาก PDPA

**ที่อยู่และเบอร์เป็น one-to-many** — `S_CUSTADDR` มี 746,916 แถว ขณะที่ `S_CUSTOMER` มี 165,722 แถว ดังนั้น matching ต้องรองรับหลายค่าต่อคน ไม่ใช่ค่าเดียว `[อนุมาน]`

**ชื่อไทยกับอังกฤษคู่กัน** — standardization ต้องตัดสินว่าอันไหนเป็นตัวหลัก

**ไม่มีเอกสารในฐานข้อมูล** — wiki ระบุ `MS_Description: not defined` ทุก table ทุก column

**คอลัมน์ข้อความเกือบทั้งหมดเป็น `nvarchar(500)` หรือ `(800)`** ไม่มี length constraint ที่มีความหมาย

### Usage

Top tables จาก `sys.dm_db_index_usage_stats`:
`M_RESULT` (8 ops) · `M_MASTERINFO` (7) · `M_NOTERESULT` (5) · `M_NOTE` (2) · `S_CONTRACT`, `S_CUSTOMER`, `S_OUTSTANDING`, `T_JOBTRANS` (1 แต่ละตัว)

wiki เตือนว่า *"Counts can reset after server restarts or index maintenance"*

`S_CUSTOMER` — Created: 2025-07-10 · Last Updated: 2025-10-29

---

## K2

Survey **Done** — สำรวจฐาน `HPCOM7` โดยตรงเมื่อ 2026-08-26 · **542 tables · 165 views**

> รายละเอียดทั้งหมดอยู่ในโฟลเดอร์ **[[K2 (HPCOM7)/K2 Overview|K2 (HPCOM7)]]**
> อยากได้ที่อยู่/ชื่อ/สัญญาของลูกค้าคนหนึ่ง → [[K2 (HPCOM7)/Query Cookbook|Query Cookbook]]

**Physical:** MSSQL ฐาน `HPCOM7` · schema `dbo` ทั้งหมด · เจ้าของงาน MIS-Fintech

### โครงหลัก

```
QUOTATION → APPLICATION → CONTRACT → CUSTOMER_CARD → INVOICE → REPAYMENT → ACCOUNT
 801,188     410,306       288,205    5,816,540       4,396,632  5,205,081   25,977,656

PERSON (404,749) ──1:1──► ADDRESS (403,283)
```

| | |
|---|---:|
| สัญญาทั้งหมด | 288,205 (ตั้งแต่ 2020-07) |
| ที่ยังผ่อนอยู่ | 93,214 |
| บุคคลในระบบ | 404,749 |
| **เลขบัตรไม่ซ้ำ** | **343,249** |
| กลุ่มลูกค้า | **Student 73,209 · Personal 47,370** (จากสัญญาที่มีหนี้ค้าง) |
| สินค้า | Smart Phone · Tablet · Laptop (Apple, Samsung, Xiaomi, Vivo, OPPO, Realme) |
| ร้านที่ขาย | COM7 283,144 · UFICON 2,968 · SPVI 1,885 |

### สิ่งที่แก้ความเข้าใจเดิม

**1. เลขบัตรประชาชนอยู่ที่ `PERSON.TAX_ID`** — มีค่า 404,627 จาก 404,749 แถว และมี index
คำถามเดิม *"K2 มีเลขบัตรที่ไหนนอก collection extract ไหม"* → **ปิดแล้ว**
(`CARD_CODE` ไม่ใช่เลขบัตร เป็นรหัสประเภทบัตร มีแค่ค่า 1 กับ 3)

**2. ที่อยู่แตกเป็นฟิลด์ย่อยครบ ไม่ใช่ 3 คอลัมน์ข้อความ** — `ADDRESS` เก็บ **5 ชุด** (ตามทะเบียน / ปัจจุบัน / ติดต่อได้ / จัดส่ง / ที่ทำงาน) แต่ละชุดมีบ้านเลขที่ หมู่ ซอย ถนน ตำบล อำเภอ จังหวัด รหัสไปรษณีย์ และ**พิกัด**
3 คอลัมน์ข้อความที่เคยเห็นเป็นแค่รูปแบบใน extract ของ collection ไม่ใช่ต้นทาง

**3. ทำ incremental ด้วย timestamp ได้** — `PERSON`, `CONTRACT`, `APPLICATION`, `QUOTATION`, `REPAYMENT` มี `CREATE_DATE` + `UPDATE_DATE` ครบ
ข้อสรุปเดิมว่าทำไม่ได้ มาจากดู `COLLECTION_OD_ASSIGNMENT` ตารางเดียวซึ่งเป็น extract

### ข้อสังเกต

**ไม่มี foreign key** — 16 ตัวจาก 542 ตาราง สร้าง ER อัตโนมัติไม่ได้ ต้องพิสูจน์ relation ด้วยการ join จริง

**ลูกค้าซ้ำในระบบเดียว** — 404,627 แถวที่มีเลขบัตร → 343,249 เลขบัตรไม่ซ้ำ · **1,577 เลขบัตรสะกดชื่อไม่ตรงกัน** · เลขบัตรที่ซ้ำมากที่สุดมี 44 แถว
`PERSON` เป็น 1 แถวต่อ 1 ใบคำขอ ไม่ใช่ทะเบียนลูกค้า — ยื่นใหม่ = `PERSON_ID` ใหม่

**`CIF_PERSON_ID` มีคอลัมน์แต่ว่าง 404,645 จาก 404,749** — ตั้งใจทำ CIF แล้วไม่ได้ทำ

**`CUSTOMER_CARD` ไม่ใช่ตารางลูกค้า** — เป็นการ์ดลูกหนี้ 1 แถวต่อ 1 งวดผ่อน (5.8M แถว)

**`CreditScrolling_Logs_Contract` 239.7 ล้านแถว** = 66% ของแถวทั้งฐาน ต้องตัดสินก่อน ingest

**`STATEMENT_FILE_PASSWORD` 79,067 แถว** — รหัสผ่านไฟล์ statement ธนาคารลูกค้าอยู่ในฐาน **ห้าม ingest**

**เก็บไฟล์เป็น base64 ในคอลัมน์จริง** — ยืนยันจาก `SETUP_COMPANY.C_LOGO` และ `REGISTRATION_DOC` ที่มี PDF ฝังอยู่ · `PERSON` มีคอลัมน์ไฟล์แบบเดียวกันสำหรับสำเนาบัตร รูปหน้า และ statement

**`ZZ_PRODUCT_K2_ITOS_mapping` (593 แถว · ก.ย. 2025)** — มีคนทำ mapping สินค้า K2↔ITOS ไว้แล้วในฐาน ต้องไปดูก่อนเริ่มใหม่

**ไม่พบรหัส ธปท.** แบบที่ ITOS มี 3 คอลัมน์

**สิทธิ์ที่ยังขาด** — `VIEW SERVER STATE` (ดู usage stats ไม่ได้) และ `VIEW DEFINITION` (อ่าน SQL ของ view 165 ตัวไม่ได้ · 65 ตัวเป็น `EGG_*`)

## โปรเจกต์รวม K2 + ITOS

มีโปรเจกต์แยกที่กำลังรวมสองระบบนี้เป็นระบบเดียว → **[[../5 Sub-Projects/K2 + ITOS Integration|K2 + ITOS Integration]]**

## คำถามที่ยังเปิด

*(คำถามเรื่องรายการ table ของ K2, เลขบัตรประชาชน และ table ที่ยัง update อยู่ — ปิดแล้วโดย survey 2026-08-26 ดู [[K2 (HPCOM7)/K2 Overview|K2 Overview]])*

- K2 กับ ITOS มีข้อมูลสัญญาเดียวกันซ้ำกันไหม
- ITOS ยัง update อยู่ไหม
- `ILOAN_COLLECTION` กับ `ILOAN_DATASOURCE` refresh บ่อยแค่ไหน
- พอรวมแล้ว lake จะ ingest ระบบรวม หรือ 2 source
- "ถังของพี่คอง" คืออะไรในเชิง AWS

---

## อ่านต่อ

[[K2 (HPCOM7)/K2 Overview|K2 (HPCOM7)]] · [[System Inventory]] · [[../4 SSOT & Customer 360/Data Standardization & Quality|Data Standardization & Quality]] · [[../4 SSOT & Customer 360/Customer Identity|Customer Identity]] · [[../6 Technical/SQL & Source Schemas|SQL & Source Schemas]]
