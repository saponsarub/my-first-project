# K2 — Data Dictionary (Core Tables)

คำอธิบายระดับ **field** ของตารางแกน · เทียบเท่าที่ [[ITOS Overview|ITOS]] มีให้ `S_CUSTOMER`

**ที่มาของคำอธิบาย** — ไม่ได้เดาจากชื่อคอลัมน์ แต่มาจากงานที่ทำจริงกับฐานนี้:
หนังสือบอกเลิกสัญญา ([[K2 - Termination Letter Mapping]]) · นโยบายค่าธรรมเนียม ([[K2 - Fee Policy]]) ·
การคัดรายชื่อ OD6 ([[K2 - OD6 Selection Logic]]) · ความรู้ของทีม ([[K2 - Business Rules]])

> คอลัมน์ที่มีเครื่องหมาย ✅ = ใช้งานจริงและยืนยันค่าแล้ว · ⚠️ = มีกับดัก · ❌ = อย่าใช้

---

## Table importance tiers (364 live tables)

| ชั้น | ตาราง | ความหมาย |
|---|---:|---|
| **★★★ core** | **10** | ใช้ทำงานจริงแล้ว มีคำอธิบายระดับ field ในหน้านี้ |
| **★★ สำคัญ** | **40** | ต้องรู้จัก ยังไม่ได้ลงรายละเอียด |
| ★ master | 117 | ตาราง lookup — ค่าจริงอยู่ที่ [[K2 - Master & Setup]] |
| ⛔ ระวัง | 5 | ห้ามแตะ / ต้องตัดสินใจก่อน |
| · ชั้นรอง | 192 | log, reporting, interface |

### ★★★ Core — 10 tables

| ตาราง | แถว | คอลัมน์ | คือ |
|---|---:|---:|---|
| `COLLECTION_OD` | 15,653,423 | 33 | snapshot หนี้ค้างรายวัน |
| `CUSTOMER_CARD` | 5,816,576 | 26 | การ์ดลูกหนี้ 1 แถว = 1 งวด |
| `REPAYMENT` | 5,205,084 | 47 | การรับชำระจริง |
| `INVOICE` | 4,396,632 | 24 | ใบแจ้งหนี้รายงวด |
| `QUOTATION` | 801,197 | 107 | ใบเสนอราคา + เงื่อนไขการเงิน |
| `APPLICATION` | 410,319 | 27 | ใบคำขอสินเชื่อ |
| `PERSON` | 404,758 | 190 | บุคคล (1 แถวต่อ 1 ใบคำขอ) |
| `PRODUCT` | 403,771 | 95 | เครื่องที่ปล่อยเช่าซื้อ |
| `ADDRESS` | 403,295 | 101 | ที่อยู่ 5 ชุดในแถวเดียว |
| `CONTRACT` | 288,207 | 30 | สัญญาเช่าซื้อ |

### ⛔ Handle with care — 5 tables

| ตาราง | แถว | ทำไม |
|---|---:|---|
| `CreditScrolling_Logs_Contract` | **239,757,512** | 66% ของแถวทั้งฐาน · ต้องตัดสินก่อน ingest |
| `PDF_FORM` | 2,553,579 | อาจเก็บ PDF เป็น binary |
| `IMAGE_FILE` | 582,811 | รูปเอกสารสัญญา |
| **`STATEMENT_FILE_PASSWORD`** | **79,067** | **รหัสผ่านไฟล์ statement ธนาคาร — ห้าม ingest** |
| `PDF_NOTICE` | 17,903 | หนังสือแจ้งเตือนที่ออกไปแล้ว |

---

## `CONTRACT` — hire-purchase contract · 288,207 rows · 30 columns

**คีย์:** `CONTRACT_ID` (PK) · `CONTRACT_NUMBER` ไม่ซ้ำ 288,195 ค่า

| คอลัมน์ | Type | คำอธิบาย |
|---|---|---|
| `CONTRACT_ID` | int | PK · ใช้ join กับทุกตารางลูก |
| `CONTRACT_NUMBER` | nvarchar | เลขสัญญาที่ใช้สื่อสารกับลูกค้า ✅ |
| `STATUS_ID` | int | **สถานะสัญญา** join `MT_STATUS.HP_STA_ID` ✅ |
| `STATUS_HP` | int | ❌ **ตายแล้ว** — NULL 288,201 จาก 288,205 แถว ชื่อชวนหยิบผิด |
| `APP_ID` | int | → `APPLICATION` · ใช้ join ผู้ค้ำ (`GUARANTOR.APP_ID`) ✅ |
| `PERSON_ID` | int | → `PERSON` / `ADDRESS` ✅ |
| `PRODUDCT_ID` | int | → `PRODUCT.PRODUCT_ID` · **สะกดผิดในฐานจริง** · join ติด 288,197/288,207 ✅ |
| `CIF_PERSON_ID` | int | ⚠️ ตั้งใจทำ CIF แต่ว่าง 99.97% |
| `REPAY_ID` | int | อ้างถึงรายการรับชำระ |
| `PARTNER_ID` | int | → `SETUP_PARTNER` · ร้านที่ขายเครื่อง ✅ |
| `P_BRANCH_ID` | int | สาขา |
| `EMP_ID` | int | พนักงานผู้ทำรายการ |
| `APPLICATION_NUMBER` | nvarchar | เลขใบคำขอ 13 หลัก |
| `CUSTOMER_NAME` | nvarchar | ⚠️ ชื่อ-นามสกุลรวมช่องเดียว (denormalize) · 299 แถวมีช่องว่างนำหน้า ต้อง `LTRIM` |
| `MAKE_DATE` | date | วันทำรายการ — ให้ค่าเดียวกับ `CONTRACT_START` |
| `CONTRACT_START` | date | **วันทำสัญญา** ✅ ใช้ในหนังสือ |
| `CONTRACT_END` | date | ❌ **เชื่อไม่ได้** — เพี้ยนจาก `MAX(CUSTOMER_CARD.DUEDATE)` ได้ถึง **1,454 วัน** และบางแถวน้อยกว่าวันครบกำหนดงวดสุดท้าย |
| `PERIOD_DATE` | date | |
| `INSTALL_NUM_FINAL` | int | ⚠️ **ไม่ใช่จำนวนงวดทั้งหมด** — หมายถึงงวดที่ค่างวดปกติ น้อยกว่าจริง 1 งวด · ใช้ `PRODUCT.INSTALL_NUM` แทน |
| `OVERDUE` | int | ขั้น OD |
| `ASSIGN_DATE` | date | วันมอบหมายให้ collector |
| `COLLECTION_NAME` | nvarchar | ชื่อผู้ติดตาม |
| `ROLE_COLLECTION` | nvarchar | บทบาทผู้ติดตาม |
| `SERIAL_NUMBER` | nvarchar | ❌ **ว่างทั้งตาราง 0/288,207** · serial จริงอยู่ที่ `PRODUCT.SERIAL_NUMBER` |
| `PROJECT_TYPE` | nvarchar | สายผลิตภัณฑ์ — UFUND 95,758 · PARTNER 3,818 · UFICON 1,181 · SolarCell 37 · UPHONE 2 · **NULL 187,410** ⚠️ |
| `FLAG_SEND_S9` / `DATE_SEND_S9` | bit / datetime | ส่งไประบบ "S9" — ยังไม่รู้ว่าคืออะไร |
| `CREATE_DATE` / `UPDATE_DATE` | datetime | ✅ **มีครบ** → ทำ incremental extraction ได้ |
| `NAME_MAKE` | nvarchar | user ที่สร้างรายการ |

**สถานะสัญญาปัจจุบัน** (จาก `STATUS_ID` join `MT_STATUS`):
Close Contract 146,731 · **ลูกหนี้ปกติ 93,214** · ปิดบัญชีล่วงหน้า 20,571 · บอกเลิกสัญญา 10,581 ·
Overdue 1–6 รวม 10,091 · ขายหนี้ 4,015 · Write Off 2,665

---

## `CUSTOMER_CARD` — instalment card · 5,816,576 rows · 26 columns

### ⚠️ Misleading name — this is not a customer table

**1 แถว = 1 งวดผ่อน** ของ 288,198 สัญญา · `INSTALL_NUM` 1 ถึง 84 · เฉลี่ย 20 งวด/สัญญา

| คอลัมน์ | Type | คำอธิบาย |
|---|---|---|
| `ID` | int | PK |
| `CONTRACT_ID` | int | → `CONTRACT` · **มี index `INNO_CONTRACT_ID (CONTRACT_ID, INSTALL_NUM)`** ✅ |
| `CONTRACT_NUMBER` | nvarchar | denormalize |
| `APPLICATION_NUMBER` | nvarchar | denormalize |
| `INSTALL_NUM` | int | **งวดที่เท่าไหร่** ✅ |
| `DUEDATE` | date | **วันครบกำหนด** ✅ · **มีแค่วันที่ 1 (3,000,934) กับ 16 (2,815,636) ทั้งตาราง** |
| `INSTALL_AMT` | float | ค่างวด |
| `PAY_PRINCIPLE` | float | เงินต้นในงวดนั้น (`PRINCIPLE` สะกดผิด ควรเป็น `PRINCIPAL`) |
| `PAY_INTEREST` | float | ดอกเบี้ยในงวดนั้น |
| `PAY_INSTALL_VAT` | float | VAT ในงวดนั้น |
| `OUTSTD_SUM_PRINCIPLE` | float | เงินต้นคงเหลือหลังงวดนี้ |
| `OUTSTD_SUM_INTEREST` | float | ดอกเบี้ยคงเหลือ |
| `SUM_OUTSTAND` | float | ยอดคงเหลือรวม |
| `INVOICE_NUMBER` | nvarchar | เลขใบแจ้งหนี้ของงวดนี้ |
| **`RECEIPT_NUMBER`** | nvarchar | ⭐ **ตัวชี้ว่างวดนี้ชำระแล้วหรือยัง** · `IS NOT NULL` = ชำระแล้ว (4,335,203) · `IS NULL` = ยังไม่ชำระ (1,481,373) ✅ |
| `INSTALL_OD_01` / `_02` / `_SUM` | nvarchar | ⚠️ ยอดค้าง **เก็บเป็นข้อความ** ต้อง cast ก่อนคำนวณ |
| `SUM_OD_AMT` | float | ยอดค้างรวม |
| `PENALTY_AMT` | float | ค่าปรับของงวดนี้ |
| `COLLECT_AMT` | float | ค่าติดตามของงวดนี้ |
| `DISCOUNT_AMT` | float | ส่วนลด |
| `REVENUE_INS_MARGIN` / `_OUTSTD` | float | ส่วนต่างรายได้ประกัน |
| `FEE_INSTALL` / `FEE_SUM` | float | ค่าธรรมเนียม |

**การใช้งานหลัก** — `RECEIPT_NUMBER IS NULL` + `DUEDATE <= วันนี้` = **งวดที่ค้างจริง**
ใช้แทน `COLLECTION_OD.NUMBER_OF_OD_INSTALLMENT` ที่นับต่ำกว่าความจริง 1 งวด ([[K2 - OD6 Selection Logic]] ชั้น 7)

> "ชำระแล้ว" ≠ "ชำระตรงงวด" — 30,810 งวดมีใบเสร็จทั้งที่ยังไม่ครบกำหนด (ปิดก่อนกำหนด) ·
> 154,444 งวดไม่มีใบเสร็จทั้งที่เกินกำหนด 1 ปี

---

## `COLLECTION_OD` — daily arrears snapshot · 15,653,423 rows · 33 columns

**ตารางที่ใช้มากที่สุดในงานติดตามหนี้** · **heap ไม่มี index เลย** ⚠️

| คอลัมน์ | Type | คำอธิบาย |
|---|---|---|
| **`EXTRACT_DATE`** | date | ⭐ **วัน snapshot** — ~120,800 สัญญา/วัน ตั้งแต่ 2026-04-08 · **ต้องใส่เสมอ** ไม่งั้นได้สัญญาซ้ำ 140 ครั้ง ✅ |
| `CONTRACT_ID` / `CONTRACT_NUMBER` | int / nvarchar | → `CONTRACT` |
| **`CONTRACT_STATUS`** | int | ⚠️ **ป้ายสถานะ ไม่ใช่จำนวนงวดค้าง** · `48` = Overdue 6 · **เหนียว ขึ้นแล้วไม่ลดแม้จ่ายบางส่วน** |
| `CONTRACT_STATUS_DESC` | nvarchar | ชื่อสถานะ |
| `PRODUDCT_ID` | int | (typo) |
| `PRODUCT_TYPE` | varchar | ⭐ **กลุ่มลูกค้า** — `Student` 73,209 · `Personal` 47,370 · ครบกว่า `CONTRACT.PROJECT_TYPE` ✅ |
| `UPDATE_DATE` | datetime | |
| `NUMBER_OF_PERIOD` | int | จำนวนงวดทั้งสัญญา |
| `INSTALLMENT_PER_PERIOD` | float | ค่างวด |
| `TOTAL_OUTSTANDING` / `_PRINCIPLE` / `_INTEREST` / `_VAT` | float | ยอดตามสัญญาทั้งหมด |
| `PAID_TOTAL_*` | float | ยอดที่ชำระแล้ว |
| **`PAID_NUMBER_OF_PERIOD`** | int | จ่ายมาแล้วกี่งวด ✅ |
| `REMAINING_*` | float | ยอดคงเหลือ (ยอดปิดบัญชี ไม่ใช่ยอดค้าง) |
| `REMAINING_PERIOD` | int | เหลืออีกกี่งวด |
| **`PERIOD_DUE_DATE`** | date | ⭐ **งวดปัจจุบันที่ยังออกบิลอยู่** · **หยุดเดินเมื่อสัญญาไม่มีงวดใหม่** → ใช้ตรวจว่าสัญญาหมดอายุแล้วหรือยัง ✅ |
| **`LAST_REPAY_DATE`** | date | วันชำระล่าสุด ✅ ใช้ดูว่าเงียบมากี่วัน |
| `INVOICE_NUMBER` / **`INVOICE_DATE`** | nvarchar / date | ใบแจ้งหนี้ของงวดที่ค้าง · `INVOICE_DATE` ใช้นับอายุหนี้ ✅ |
| **`NUMBER_OF_OD_INSTALLMENT`** | nvarchar | ⚠️ **จำนวนงวดที่ค้าง — เก็บเป็นข้อความ ต้อง `TRY_CAST`** · **นับต่ำกว่าการ์ดจริง 1 งวดเสมอ** (งวดที่เพิ่งครบกำหนดยังไม่นับ) |
| **`OD_AMOUNT`** | float | ยอดค่าเช่าซื้อที่ค้าง = งวดที่เลยกำหนด × ค่างวด ✅ |
| **`PENALTY_AMT`** | float | ค่าปรับ = ขั้น OD × 100 → [[K2 - Fee Policy]] ✅ |
| **`COLLECT_AMT`** | float | ค่าติดตาม ไต่ขั้นตามตาราง แยก 2 กรณีตามว่าค่างวดถึง 1,000 ไหม ✅ |
| `TOTAL_FOLLOW_UP_AMOUNT` | float | ⚠️ **= (งวดค้าง + 1) × ค่างวด + ค่าปรับ + ค่าติดตาม** — **รวมงวดที่กำลังจะถึงด้วย** อย่าใช้เป็นยอดค้าง |

### Status refresh cadence

**ระบบเปลี่ยน `CONTRACT_STATUS` ช้ากว่าวันครบกำหนด ~2 วัน** — ขยับทุก **วันที่ 3 และ 18**

| วันที่ (ส.ค. 2026) | OD6 |
|---|---:|
| 1–2 | 6 |
| **3** | **337** ← รอบของคนครบกำหนดวันที่ 1 |
| 15–17 | 300 |
| **18** | **603** ← รอบของคนครบกำหนดวันที่ 16 |

เกิดซ้ำทุกเดือน (18 พ.ค. → 300 · 18 มิ.ย. → 293 · 18 ก.ค. → 302)

---

## `PRODUCT` — financed device · 403,771 rows · 95 columns

**1 แถวต่อ 1 ใบคำขอ** · join จาก `CONTRACT.PRODUDCT_ID`

### Columns actually used in documents

| คอลัมน์ | Type | คำอธิบาย |
|---|---|---|
| `PRODUCT_ID` | int | PK |
| `APP_ID` / `QUOTATION_ID` | int | เชื่อมต้นทาง |
| **`MODEL_NAME`** | nvarchar | ⭐ **ชื่อรุ่นแบบอ่านออก** เช่น `Samsung Galaxy A26 5G` ✅ |
| **`MODEL_NUMBER`** | nvarchar | บาร์โค้ด/รหัสรุ่น เช่น `8806097098270` ✅ |
| **`SERIAL_NUMBER`** | nvarchar | ⭐ **เลขเครื่อง** มีค่า 289,184/403,773 · **ตัวจริง ไม่ใช่ `CONTRACT.SERIAL_NUMBER`** ✅ |
| `PRODUCT_TYPE` | int | → `MT_PRODUCT_TYPE` · `New Product` / `Used Product` |
| `PRODUCT_CATEGORY` | int | → `MT_CATEGORY` · Smart Phone / Tablet / Laptop ✅ |
| **`PRODUCT_BAND`** | int | ⚠️ **สะกดผิด — ที่จริงคือ BRAND** · join `MT_BRAND.BRAND_ID` ✅ |
| `PRODUCT_SERIES` / `_SUB_SERIES` / `_COLOR` | int | → `MT_SERIES` / `MT_SUB_SERIES` / `MT_COLOR` |
| `PROD_PRICE` / `PROD_VAT` / `PROD_SUM_PRICE` | float | ราคาเครื่อง |
| `DOWN_PERCENT` / `DOWN_AMT` / `DOWN_SUM_AMT` | float | เงินดาวน์ |
| `HP_AMT` / `HP_SUM` / **`HP_VAT_SUM`** | float | ยอดเช่าซื้อ · `HP_VAT_SUM` = ยอดรวม VAT ✅ |
| `INTEREST_FLAT` | float | ดอกเบี้ยแบบ flat ต่อเดือน (เช่น 0.0199 = 1.99%) |
| `INTEREST_EFFECTIVE` | nchar | ⚠️ **เก็บเป็นข้อความ** ไม่ใช่ตัวเลข |
| **`INSTALL_NUM`** | int | ⭐ **จำนวนงวดจริง** ✅ ใช้ตัวนี้ ไม่ใช่ `CONTRACT.INSTALL_NUM_FINAL` |
| `INSTALL_AMT` | float | ⚠️ ค่างวด **ก่อน VAT** — อย่าใช้ในเอกสาร |
| **`INSTALL_SUM`** | float | ⭐ **ค่างวดรวม VAT** ✅ ตัวนี้คือที่ลูกค้าจ่ายจริง |
| `INSTALL_NUM_FINAL` / `INSTALL_AMT_FINAL` | int / float | งวดสุดท้ายที่ค่างวดต่าง |
| **`DUEDATE_NUM`** | int | ⭐ **วันครบกำหนดของเดือน** — มีแค่ `1` กับ `16` ✅ |
| **`FRIST_PAY_DATE`** | date | ⭐ **วันครบกำหนดงวดแรก** (สะกดผิด `FRIST`) ✅ = `MIN(CUSTOMER_CARD.DUEDATE)` |
| `DESCRIPTION` | nvarchar | ว่างทั้งหมดในตัวอย่างที่ตรวจ |
| `ACS_*` / `INSURE_*` / `Icare_*` / `PACKAGE_*` | | อุปกรณ์เสริม · ประกัน · แพ็กเกจพ่วง |
| `Tradein_AMT` / `TRADE_IN_*` | | รับเทิร์นเครื่องเก่า |
| `Balloon_Type` / `INSTALL_NUM_BALLOON` | int | ผ่อนแบบ balloon |
| `ABM_STARTDATE` / `_ENDDATE` / `_NUMBER` | | ยังไม่รู้ว่า ABM คืออะไร |

**นี่คือ Device Registry (`DEV-01`) ที่ Gap Review ระบุว่า "ขาด"** — 289,184 เครื่องพร้อม serial + รุ่น ผูกกับสัญญาและลูกค้าได้

---

## `PERSON` — person · 404,758 rows · 190 columns

### ⚠️ Not a customer registry — one row per role per application

`APP_ID` ไม่ซ้ำเลยทั้งตาราง · คนเดิมยื่นใหม่ = `PERSON_ID` ใหม่ · **404,627 แถวที่มีเลขบัตร → 343,249 เลขบัตรไม่ซ้ำ**

### Identity keys

| คอลัมน์ | Type | คำอธิบาย |
|---|---|---|
| `PERSON_ID` | int | PK · `PK_HP_PERSON` clustered |
| **`TAX_ID`** | nvarchar | ⭐ **เลขบัตรประชาชน 13 หลัก ไม่มีขีด** · มีค่า 404,627 แถว · **มี index `INNO_TAX_ID`** ✅ |
| `CARD_CODE` | nvarchar | ❌ **ไม่ใช่เลขบัตร** — รหัสประเภทบัตร มีแค่ค่า `1` (328,361) และ `3` (51) |
| `PREFIX` | nvarchar | ⚠️ **เก็บเป็นรหัส** ต้อง join `MT_PREFIX.Prefix_ID` ถึงได้คำว่า นาย/นาง/นางสาว ✅ |
| `FIRST_NAME` / `LAST_NAME` | nvarchar | ⚠️ **ไม่มี index** — ค้นด้วยชื่อ = scan ทั้งตาราง |
| `PREFIX_ENG` / `FIRST_NAME_ENG` / `LAST_NAME_ENG` | nvarchar | ชื่ออังกฤษ |
| `BIRTHDAY` | date | วันเกิด |
| `SEX` / `NATIONALITY_CODE` / `MARITAL_STATUS` | nvarchar | |
| `CIF_PERSON_ID` | int | ⚠️ ว่าง 404,645/404,758 |
| `CUSTOMER_TYPE` | nvarchar | ⚠️ ว่าง 404,644/404,758 |
| `FLAG_GUARANTOR` | int | ⚠️ NULL 401,519 (99.2%) · `=1` แค่ 3,217 · **ใช้แทบไม่ได้** |
| `PHONE` / `PHONE_SECOND` | nvarchar | **มี index `INNO_PHONE`** ✅ · `PHONE_SECOND` ว่างเกือบหมด |
| `EMAIL` / `LINEID` / `FACEBOOK` | nvarchar | |

### Financial group (sensitive)

`MAIN_INCOME` · `OTHER_INCOME` · `EXPENSE` · `AMOUNT_INCOME` · `SALARY_RANGE_MIN/MAX` ·
`FINANCIAL_AMOUNT` · `CREDIT_CARD_LIMIT` · `INSTALLMENT_HOME` · `INSTALLMENT_CAR` · `INSTALLMENT_ETC` ·
`INSTITUTION_BANK` · `INSTITUTION_BANK_AMOUNT` · `BANK_NAME` · `PAY_DAY`

### Education group — confirms students are the main segment

`STUDENT_ID` · `UNIVERSITY_NAME` · `UNIVERSITY_PROVINCE` · `CAMPUS_NAME` · `FACULTY_NAME` ·
`SUBJECT` · `U_LEVEL` · `LEVEL_TYPE` · `LOAN_KYS`
→ master `MT_FACULTY` 39,475 แถว · `MT_UNIVERSITY_NAME` 1,149

### Occupation group

`OCCUPATION_CODE` ⚠️ join `MT_OCCUPATION.Ocpt_ID` ติดแค่ **87.9%** ต้อง cast เป็นข้อความ ·
`OFFICE_NAME` · `OFFICE_POSITION` · `OFFICE_YEAR` · `OFFICE_PHONE` · `BUSINESS_TYPE`

### Third-party group

**คู่สมรส** `SPOUSE_*` (ชื่อ อาชีพ ที่ทำงาน รายได้ ค่าใช้จ่าย) ·
**บุคคลอ้างอิง 2 ชุด** `REF_*` และ `REF_*_2` — แต่ละชุดมี **เลขบัตร วันเกิด รายได้ เบอร์ อีเมล LINE Facebook**

> คนเหล่านี้ไม่ได้ทำสัญญากับ COM7 — ประเด็นเดียวกับที่ ITOS เจอ

### Highly sensitive group

`Disease_ID` → `MT_DISEASE` (9 แถว) · `Narcotic_ID` · `Acknowledge_ID`
→ **PDPA มาตรา 26 ต้องมีฐานทางกฎหมายแยก** ไม่ใช่ consent ทั่วไป

### Attachment group

`CARD_CODE_FILE` · `STUDENT_CARD_FILE` · `FACE_PERSON` · `CONSENT_FILE` · `STATEMENT_FILE` ·
`BANK_STATE_FILE` (ถึง `_FOURTH`) · `SLIP_FILE` · `DS_PDPA` · และคู่ `*_FILE_PATH` อีกชุด
→ **สำเนาบัตร รูปหน้า statement ธนาคาร อาจเก็บเป็น base64 ในคอลัมน์**

### PDPA

`CONFIRM_PDPA` · `CONFIRM_INFOR` · `DS_PDPA` · `CONSENT_FILE` · `CONSENT_FILE_PATH`

### Other

`PASSWORD` ⚠️ ยังไม่ตรวจว่า hash หรือ plaintext · `CREATE_DATE` / `UPDATE_DATE` ✅ มีครบ

---

## `ADDRESS` — address · 403,295 rows · 101 columns

**1 แถวต่อ 1 `PERSON_ID`** — ต่างจาก ITOS ที่ `S_CUSTADDR` เป็น one-to-many

### Five address blocks in one row

| ชุด | prefix | ความหมาย (`MT_ADDRESS_TYPE`) | กรอกไว้ | index |
|---|---|---|---:|---|
| A1 | `A1_*` | ที่อยู่ตามทะเบียน | 403,181 | — |
| **A2** | `A2_*` | **ที่อยู่ปัจจุบัน** | 403,174 | ✅ province/district/subdistrict |
| A3 | `A3_*` | ที่อยู่ติดต่อได้ | 403,154 | — |
| A4 | `A4_*` | ที่อยู่จัดส่งเอกสาร | **93** | — |
| WORK | `A_*_WORK` | ที่ทำงาน | 67,533 | ✅ |

### Columns per block (19 fields × 5 blocks)

| suffix | Type | หมายเหตุ |
|---|---|---|
| `_MASTER` | int | เลขชุดตัวเอง (A1=1, A2=2) — ยืนยันการ map |
| `_COPY` | int | |
| `_NO` | nvarchar | บ้านเลขที่ |
| **`_MOI`** | nvarchar | ⚠️ **สะกดผิด — ที่จริงคือ MOO (หมู่)** |
| `_VILLAGE` / `_BUILDING` / `_FLOOR` / `_ROOM_NO` / `_SOI` / `_ROAD` | nvarchar | |
| **`_PROVINCE`** | **nvarchar** | ⚠️ **เก็บรหัสจังหวัดเป็นข้อความ** ต้อง `TRY_CAST(... AS int)` ก่อน join `MT_PROVINCE` |
| `_DISTRICT` | int | → `MT_DISTRICT.DISTRICT_ID` (4 หลัก) |
| `_SUBDISTRICT` | int | → `MT_SUB_DISTRICT.SUB_DISTRICT_ID` (6 หลัก) |
| `_POSTALCODE` | int | |
| `_OWNER_TYPE` | int | ประเภทการครอบครอง |
| **`_LIVEING_TIME`** | nvarchar | ⚠️ สะกดผิด — `LIVING` |
| `_PHONE` | nvarchar | |
| `_LATITUDE` / `_LONGITUDE` | nvarchar | **มีพิกัด** |

**A1 = A2 ใน 62.5%** · **A2 = A3 ใน 89.5%** — สามชุดชี้ที่เดียวกันเป็นส่วนใหญ่
ถ้าต้องเลือกชุดเดียวเพื่อติดต่อ/จัดส่ง **ใช้ A2** แล้ว fallback A1 · อย่าพึ่ง A4

---

## `INVOICE` — invoice · 4,396,632 rows · 24 columns

| คอลัมน์ | Type | คำอธิบาย |
|---|---|---|
| `INVOICE_ID` | int | PK |
| `INVOICE_NUMBER` | nvarchar | เลขใบแจ้งหนี้ |
| `INVOICEE_TYPE` | int | ประเภทผู้รับ |
| `CONTRACT_ID` | int | → `CONTRACT` |
| **`CUSTOMER_CARD_ID`** | int | ⭐ **กาวที่เชื่อมใบแจ้งหนี้กับงวดผ่อน** — 1 ใบต่อ 1 งวด |
| `INVOICE_DATE` / `DUE_DATE` | date | |
| `STATUS_ID` | int | → `MT_STATUS` |
| `AMOUNT` / `VAT_AMT` / `WHT_AMT` / `SUM_AMT` | float | ยอด |
| `DES_SUM_AMT` | nvarchar | จำนวนเงินเป็นตัวอักษร |
| `AMT_OLD` / `INSTALL_NUM_OLD` / `INSTALL_OUTSTAND` / `SUM_OUTSTAND` / `INSTALL_CURRENT` | | ยอดยกมา |
| `INSTALL_OD_01` / `_02` / `_SUM` / `SUM_OD_AMT` | | ยอดค้าง |
| `PENALTY_AMT` / `COLLECT_AMT` | float | ค่าปรับ / ค่าติดตาม |

**4.4M ใบ ต่อ 5.8M งวด** — ไม่ใช่ทุกงวดที่ออกใบแจ้งหนี้ (งวดอนาคตยังไม่ออก)

---

## `REPAYMENT` — payments received · 5,205,084 rows · 47 columns

**โครงสร้าง 2 ชั้น: `REPAY_*` = ยอดที่ต้องชำระ · `PAY_*` = ยอดที่ชำระจริง**

| กลุ่ม | คอลัมน์ |
|---|---|
| คีย์ | `REPAY_ID` (PK) · `CONTRACT_ID` ✅ · `CUSTOMER_CARD_ID` · `APP_ID` · `INVOICE_ID` |
| ต้องชำระ | `REPAY_DATE` · `REPAY_NAME` · `REPAY_AMOUNT` · `REPAY_PENALTY` · `REPAY_COLLECT` · `REPAY_VAT` · `REPAY_WHT` · `REPAY_DISCOUNT` · `REPAY_SUM_AMOUNT` |
| ชำระจริง | `PAY_DATE` · `PAY_NAME` (มี index) · `PAY_AMT` · `PAY_PENALTY` · `PAY_COLLECT` · `PAY_VAT` · `PAY_DISCOUNT` · `PAY_SUM_AMT` |
| ส่วนต่าง | **`OVER_AMT`** (ชำระเกิน) · **`LACK_AMT`** (ชำระขาด) |
| ยกเว้น | `PENALTY_WAVE_AMT` · `COLLECT_WAVE_AMT` |
| เงินสำรอง | `RESERVE_AMOUNT` · `FLAG_RESERVE` · `USE_RESERVE_AMT` |
| ปิดก่อนกำหนด | **`FLAG_EARLY_CLOSE`** |
| เอกสาร | `RECEIPT_NUMBER` · `TAX_NUMBER` · `PHY_NUMBER` · `CREDIT_NOTE_NUMBER` |
| **`REPAY_TYPE`** | → `MT_REPAY_TYPE` — ค่างวดเช่าซื้อ 4,396,628 · ค่าติดตาม 515,382 · เงินดาวน์ 291,263 · NULL 1,809 |

⚠️ **ทำรายงาน "จ่ายค่างวดเท่าไหร่" ต้องกรอง `REPAY_TYPE`** ไม่ใช่รวมทั้งก้อน — เพราะเงินก้อนเดียวถูกแตกไปหลายรายการตามการตัดชำระแนวนอน ([[K2 - Fee Policy]])

**มี 21 index** ส่วนใหญ่เป็น covering index → ตารางนี้ถูก query หนักมาก **ETL ต้องระวังภาระ**

**ข้อมูลผิด:** `MIN(REPAY_DATE) = 1067-07-09` — ปี พ.ศ. ถูกกรอกเป็น ค.ศ. **ต้องมี date filter ตอน ingest**

---

## `APPLICATION` — credit application · 410,319 rows · 27 columns

| คอลัมน์ | คำอธิบาย |
|---|---|
| `APP_ID` (PK) · `APPLICATION_NUMBER` | เลขใบคำขอ 13 หลัก |
| `QUOTATION_ID` | → `QUOTATION` |
| `PERSON_ID` · `CIF_PERSON_ID` · `JURISTIC_ID` · `CUSTOMER_NAME` | ลูกค้า |
| `STATUS_ID` | → `MT_STATUS` |
| `CHECKER_ID` · `CHECKER_RESULT` · `APPROVE_ID` · **`SCORING`** | การอนุมัติ |
| `PARTNER_ID` · `P_BRANCH_TYPE` · `P_BRANCH_ID` · `EMP_ID` · `EMP_ID_Global` · `EMP_ComCode` · `EMP_NAME` | ช่องทาง |
| `PRODUCT_ID` · `PROJECT_TYPE` · `ProcInstID` · `UNiDAYS` | อื่น |
| `CREATE_DATE` / `UPDATE_DATE` | ✅ |

**อัตราการแปลง:** 801,197 ใบเสนอราคา → 410,319 ใบคำขอ → 288,207 สัญญา ≈ 36%

---

## `QUOTATION` — quotation · 801,197 rows · 107 columns

**ที่ที่เงื่อนไขการเงินทั้งหมดถูกคำนวณครั้งแรก** — โครงสร้างซ้ำกับ `PRODUCT` เกือบทั้งหมด

| กลุ่ม | คอลัมน์เด่น |
|---|---|
| คีย์ | `QUOTATION_ID` · `QT_DATE` · `DATE_END` · `STATUS_ID` |
| ลูกค้า | `TAX_ID` · `CUSTOMER_NAME` · `OCCUPATION_ID` · `UNIVERSITY_ID` · `FACULTY_ID` |
| สินค้า | `PRODUCT_TYPE` · `PRODUCT_CATEGORY` · `PRODUCT_BAND`(typo) · `PRODUCT_SERIES` · `PRODUCT_COLOR` |
| ราคา | `PROD_PRICE` · `PROD_SUM_PRICE` · `Org_Product_Price` · `Promo_Discount` |
| ดาวน์ | `DOWN_PERCENT` · `DOWN_AMT` · `DOWN_SUM_AMT` · `DOWN_TYPE` |
| ดอกเบี้ย | `INTEREST_FLAT` · `INTEREST_EFFECTIVE`(nchar) · `INTEREST_AMT` |
| งวด | `INSTALL_NUM` · `INSTALL_AMT` · `INSTALL_SUM` |
| พ่วง | `ACS_*` · `INSURE_*` · `Icare_*` · `PACKAGE_*` |
| เทิร์น | `Tradein_AMT` · `TRADE_IN_*` |
| **การตลาด** | **`UTM_CODE`** → `MT_UTM` (2,496) · `MEMBER_REF` · `MT_CUSTOMER_SIM_ID` |
| **consent** | **`CONSENT_DATE` · `CONSENT_TIME`** ⚠️ เก็บเป็น `varchar` ทั้งคู่ |
| ที่อยู่ KYC | `ADDR_PROS_KYC` · `Addr_KYC_ID` · `DUEDATE_KYC` · `PERIOD_KYC` |

> **ใช้ `PRODUCT` ไม่ใช่ `QUOTATION`** เวลาทำเอกสารสัญญา เพราะ `PRODUCT` ผูกกับสัญญาโดยตรงผ่าน `PRODUDCT_ID`

---

## The most common traps

| กับดัก | ตัวอย่าง |
|---|---|
| **คอลัมน์มีอยู่แต่ว่าง** | `CONTRACT.SERIAL_NUMBER` (0%) · `CONTRACT.STATUS_HP` (0.001%) · `CIF_PERSON_ID` (0.03%) · `FLAG_GUARANTOR` (0.8%) |
| **ชื่อบอกอย่าง ข้างในอีกอย่าง** | `CUSTOMER_CARD` = งวดผ่อน · `CARD_CODE` = ประเภทบัตร · `A1_PROVINCE` = รหัสไม่ใช่ชื่อ |
| **ตัวเลขเก็บเป็นข้อความ** | `NUMBER_OF_OD_INSTALLMENT` · `INSTALL_OD_*` · `INTEREST_EFFECTIVE` · `A*_PROVINCE` |
| **สะกดผิดใน production** | `PRODUDCT_ID` · `PRODUCT_BAND` · `PRINCIPLE` · `FRIST_PAY_DATE` · `A1_MOI` · `_LIVEING_TIME` · `CONTARCT_NUMBER` · `VOURCHER_NO` |
| **ก่อน/หลัง VAT ปนกัน** | `INSTALL_AMT` (ก่อน) vs `INSTALL_SUM` (หลัง) |
| **ตัวนับของระบบ ≠ ข้อมูลจริง** | `NUMBER_OF_OD_INSTALLMENT` ต่ำกว่าการ์ด 1 งวดเสมอ |

---

## เชื่อมกับโน้ตอื่น

[[K2 Overview]] · [[K2 - Table Inventory]] · [[K2 - Business Rules]] · [[K2 - Fee Policy]] · [[K2 - OD6 Selection Logic]] · [[K2 - Termination Letter Mapping]] · [[K2 - Customer & Address]] · [[K2 - Contract & Account]] · [[K2 - Payment & Invoice]] · [[K2 - Collection & OD]] · [[K2 - Master & Setup]]
