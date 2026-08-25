# UFUND (K2 & ITOS)

Survey กำลังทำ · K2 โดย MIS-Fintech · ITOS โดย K.Ton

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

**Physical:** ฐาน `HPCOM7` · table ที่ยืนยันแล้วคือ `HPCOM7.dbo.COLLECTION_OD_ASSIGNMENT`
Data dictionary ได้จากพี่เนตร

### Field ที่เห็นจากคิวรี่ union

Contract: `CONTRACT_ID`, `CONTRACT_NUMBER`, `CONTRACT_STATUS`, `CONTRACT_STATUS_DESC`, `PRODUDCT_ID`, `PRODUCT_TYPE`, `UPDATE_DATE`

Financial: `TOTAL_OUTSTANDING`, `TOTAL_PRINCIPLE`, `TOTAL_INTEREST`, `TOTAL_VAT`, `NUMBER_OF_PERIOD`, `INSTALLMENT_PER_PERIOD` และชุด `PAID_*`, `REMAINING_*`, `*_TO_DUE`

Schedule: `PERIOD_DUE_DATE`, `LAST_REPAY_DATE`, `INVOICE_NUMBER`, `INVOICE_DATE`

ค้างชำระ: `NUMBER_OF_OD_INSTALLMENT`, `OD_AMOUNT`, `PENALTY_AMT`, `COLLECT_AMT`, `TOTAL_FOLLOW_UP_AMOUNT`, `IS_FIRST_DUE`, `IS_LAST_DUE`

Assignment: `ASSIGN_TO_TEAM`, `EMP_CODE`, `EMP_NAME`

ลูกค้า: `CUSTOMER_BIRTH_DATE`, `CUSTOMER_PHONE_NUM`, `CUSTOMER_NAME`, `CUSTOMER_ADDRESS_REGISTER`, `CUSTOMER_ADDRESS_CURRENT`, `CUSTOMER_ADDRESS_DELIVERY`, `CUSTOMER_OCCUPATION`

ผู้ค้ำ: `GUARANTOR_NAME`, `GUARANTOR_RELATION`, `GUARANTOR_PHONE_NUM`

### ข้อสังเกต

**ที่อยู่เก็บเป็น 3 คอลัมน์** (register / current / delivery) ต่างจาก ITOS ที่แยกเป็นตาราง `S_CUSTADDR` — สองรูปแบบนี้รวมกันไม่ตรงไปตรงมา `[อนุมาน]`

**ไม่มี `CREATE_DATE` / `MODIFY_DATE`** — คิวรี่ union ต้องใส่ `CAST(NULL as date)` แทน
ผลคือ **ดึง incremental ด้วย timestamp จาก K2 ไม่ได้** ต้องใช้ CDC หรือ full reload `[อนุมาน]`

**ไม่พบคอลัมน์เลขบัตรประชาชนในคิวรี่ union นี้** — แต่คิวรี่นี้เป็นแค่ collection extract ไม่ใช่ทั้งระบบ K2 **ยังสรุปไม่ได้ว่า K2 ไม่มีเลขบัตร ต้องถาม MIS-Fintech**

---

## โปรเจกต์รวม K2 + ITOS

มีโปรเจกต์แยกที่กำลังรวมสองระบบนี้เป็นระบบเดียว → **[[../5 Sub-Projects/K2 + ITOS Integration|K2 + ITOS Integration]]**

## คำถามที่ยังเปิด

- K2 component/table ไหนยัง update อยู่จริง
- K2 กับ ITOS มีข้อมูลสัญญาเดียวกันซ้ำกันไหม
- K2 มีเลขบัตรประชาชนที่ไหนนอก collection extract ไหม
- รายการ table ทั้งหมดของ K2 คืออะไร (ยืนยันแค่ตารางเดียว)
- ITOS ยัง update อยู่ไหม
- `ILOAN_COLLECTION` กับ `ILOAN_DATASOURCE` refresh บ่อยแค่ไหน
- พอรวมแล้ว lake จะ ingest ระบบรวม หรือ 2 source
- "ถังของพี่คอง" คืออะไรในเชิง AWS

---

## อ่านต่อ

[[System Inventory]] · [[../4 SSOT & Customer 360/Data Standardization & Quality|Data Standardization & Quality]] · [[../4 SSOT & Customer 360/Customer Identity|Customer Identity]] · [[../6 Technical/SQL & Source Schemas|SQL & Source Schemas]]
