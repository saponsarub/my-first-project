# K2 — Contract & Account

ใบเสนอราคา → ใบคำขอ → สัญญา → บัญชี · survey 2026-08-26

---

## Document flow

```
QUOTATION ──QUOTATION_ID──► APPLICATION ──APP_ID──► CONTRACT
 801,188                      410,306                288,205
                                  │                      │
                                  │                      ├─PRODUDCT_ID─► PRODUCT  ◄ ทางลัดไปหาเครื่อง
                                  │                      ├─PERSON_ID───► PERSON ── ADDRESS
                                  │                      └─CONTRACT_ID─► CUSTOMER_CARD / INVOICE
                                  ├── CHECKER (402,965)  ผลตรวจสอบ
                                  ├── CHECKER_GUARANTOR (361,169)
                                  └── GUARANTOR (12,629)  ผู้ค้ำตัวจริง — ผูก APP_ID เป็นหลัก
```

**`CONTRACT.PRODUDCT_ID` → `PRODUCT.PRODUCT_ID` join ติด 288,197 จาก 288,207** — ใช้เส้นนี้ถามว่า
"สัญญานี้คือเครื่องอะไร" ได้เลย ไม่ต้องอ้อมผ่าน `QUOTATION` ดู [[K2 - Business Rules]] ข้อ 5

อัตราการแปลง: **801,188 ใบเสนอราคา → 410,306 ใบคำขอ → 288,205 สัญญา** ≈ 36% ของใบเสนอราคากลายเป็นสัญญา `[อนุมาน]`

ทุกตารางในสายนี้มี `CREATE_DATE` และ `UPDATE_DATE` ครบ → **ทำ incremental extraction ด้วย watermark ได้**

---

## `CONTRACT` — 288,205 rows · 30 columns

คีย์: `CONTRACT_ID` (PK) · `CONTRACT_NUMBER` (ไม่ซ้ำ 288,195 ค่า)

| กลุ่ม | คอลัมน์ |
|---|---|
| เชื่อมต้นทาง | `APP_ID`, `PERSON_ID`, `CIF_PERSON_ID`, `PRODUDCT_ID`, `REPAY_ID`, `APPLICATION_NUMBER` |
| ช่องทางขาย | `PARTNER_ID`, `P_BRANCH_ID`, `EMP_ID` |
| สถานะ | **`STATUS_ID`** · `STATUS_HP` (ตายแล้ว) · `OVERDUE` |
| ระยะเวลา | `MAKE_DATE`, `CONTRACT_START`, `CONTRACT_END`, `PERIOD_DATE`, `INSTALL_NUM_FINAL` |
| ทวงถาม | `ASSIGN_DATE`, `COLLECTION_NAME`, `ROLE_COLLECTION` |
| อื่น | `CUSTOMER_NAME`, `SERIAL_NUMBER`, `PROJECT_TYPE`, `FLAG_SEND_S9`, `DATE_SEND_S9`, `NAME_MAKE` |

**`STATUS_HP` เป็น NULL 288,201 จาก 288,205 แถว — คอลัมน์ตายแล้ว ให้ใช้ `STATUS_ID` เท่านั้น**
ทั้งสองคอลัมน์ join กับ `MT_STATUS.HP_STA_ID` เหมือนกัน ชื่อคอลัมน์ชวนให้หยิบผิดตัว

**`CUSTOMER_NAME` เก็บชื่อ-นามสกุลรวมช่องเดียว** ซ้ำกับ `PERSON.FIRST_NAME`/`LAST_NAME` — denormalize ไว้
299 แถวมีช่องว่างนำหน้า ต้อง `LTRIM` ก่อนเทียบ

> ⚠️ **`CONTRACT.SERIAL_NUMBER` ว่างทั้งตาราง** — 0 จาก 288,207 แถว มีคอลัมน์แต่ไม่เคยถูกเติม
> serial ตัวจริงอยู่ที่ **`PRODUCT.SERIAL_NUMBER`** (289,184 จาก 403,773 แถว) พร้อม `MODEL_NAME` และ `MODEL_NUMBER`
> **นั่นคือ device registry `DEV-01` ที่ Gap Review ระบุว่า "ขาด"** ดู [[K2 - Business Rules]] ข้อ 7

### Current contract statuses

| สถานะ (`MT_STATUS`) | สัญญา |
|---|---:|
| Close Contract | 146,731 |
| **ลูกหนี้ปกติ** | **93,214** |
| ลูกหนี้ปิดบัญชีล่วงหน้า | 20,571 |
| ลูกหนี้บอกเลิกสัญญา | 10,581 |
| Overdue 1 | 5,610 |
| ขายหนี้ | 4,015 |
| Write Off | 2,665 |
| Overdue 2 | 1,386 |
| Overdue 3 | 946 |
| Overdue 4 | 811 |
| Overdue 5 | 767 |
| Overdue 6 | 571 |
| In active | 319 |
| Wait Welcome Call | 9 |
| NULL | 10 |

**สัญญาที่ยังมีภาระ = 93,214 (ปกติ) + 10,091 (Overdue 1–6) ≈ 103,305**
**สัญญาที่จบไม่สวย = 10,581 (บอกเลิก) + 4,015 (ขายหนี้) + 2,665 (write off) = 17,261** ≈ 6.0% ของสัญญาทั้งหมด `[อนุมาน]`

`MT_STATUS` มี 61 สถานะ ใช้ร่วมกันทั้งใบคำขอ สัญญา การชำระ และการทวงถาม — ดู [[K2 - Master & Setup]]

---

## `APPLICATION` — 410,306 rows · 27 columns

| กลุ่ม | คอลัมน์ |
|---|---|
| คีย์ | `APP_ID`, `APPLICATION_NUMBER` (13 หลัก), `QUOTATION_ID` |
| ลูกค้า | `PERSON_ID`, `CIF_PERSON_ID`, `JURISTIC_ID`, `CUSTOMER_NAME` |
| อนุมัติ | `STATUS_ID`, `CHECKER_ID`, `CHECKER_RESULT`, `APPROVE_ID`, **`SCORING`** |
| ช่องทาง | `PARTNER_ID`, `P_BRANCH_TYPE`, `P_BRANCH_ID`, `EMP_ID`, `EMP_ID_Global`, `EMP_ComCode`, `EMP_NAME` |
| อื่น | `PRODUCT_ID`, `PROJECT_TYPE`, `ProcInstID`, `UNiDAYS`, `CREATE_DATE`, `UPDATE_DATE` |

`JURISTIC_ID` = ลูกค้านิติบุคคล มีตาราง `JURISTIC` แยก แต่ยังไม่ได้สำรวจ

**Credit scoring มีหลายชั้น** — `APPLICATION_SCORING` (621,676) · `APPLICATION_SCORING_DETAIL` (3,108,359) · `Outsource_Credit_Scoring` (141,488) · `SETUP_SCORING_LIST` / `SETUP_SCORING_SUBLIST` · `NCB_testFormat` (230,556) และ `NationalCreditBureau`
→ **มีการดึงเครดิตบูโร (NCB)** ซึ่งเป็นข้อมูลที่มีข้อจำกัดตามกฎหมายเฉพาะ ไม่ใช่แค่ PDPA `[อนุมาน]`

`UNiDAYS` (bit) — โปรแกรมส่วนลดนักศึกษา สอดคล้องกับกลุ่มลูกค้า Student

---

## `QUOTATION` — 801,188 rows · 107 columns

ใบเสนอราคา คือที่ที่**เงื่อนไขการเงินทั้งหมดถูกคำนวณ**

| กลุ่ม | คอลัมน์ |
|---|---|
| สินค้า | `PRODUCT_TYPE`, `PRODUCT_CATEGORY`, `PRODUCT_BAND`*, `PRODUCT_SERIES`, `PRODUCT_SUB_SERIES`, `PRODUCT_COLOR` |
| ราคา | `PROD_PRICE`, `PROD_VAT`, `PROD_SUM_PRICE`, `Org_Product_Price`, `Promo_Discount` |
| เงินดาวน์ | `DOWN_PERCENT`, `DOWN_AMT`, `DOWN_VAT`, `DOWN_SUM_AMT`, `DOWN_TYPE`, `PAY_DOWN_TYPE` |
| เช่าซื้อ | `HP_AMT`, `HP_INVEST_AMT`, `HP_SUM`, `HP_VAT_SUM`, `CREDIT_LIMIT` |
| ดอกเบี้ย | **`INTEREST_FLAT`**, `INTEREST_EFFECTIVE`, `INTEREST_AMT`, `INTEREST_TOTAL`, `INTEREST_VAT` |
| งวด | `INSTALL_NUM`, `INSTALL_NUM_FINAL`, `INSTALL_AMT`, `INSTALL_AMT_FINAL`, `INSTALL_VAT`, `INSTALL_SUM` |
| พ่วง | `ACS_*` (อุปกรณ์เสริม), `INSURE_*` (ประกัน), `Icare_*`, `PACKAGE_*` |
| เทิร์น | `Tradein_AMT`, `TRADE_IN_TYPE`, `TRADE_IN_INSTALL`, `TRADE_IN_DISCOUNT_*` |
| balloon | `Balloon_Type`, `INSTALL_NUM_BALLOON` |
| การตลาด | **`UTM_CODE`**, `MEMBER_REF`, `MT_CUSTOMER_SIM_ID` |
| consent | `CONSENT_DATE`, `CONSENT_TIME` (เก็บเป็น `varchar` ทั้งคู่) |

\* `PRODUCT_BAND` สะกดผิด ที่จริงคือ brand — join กับ `MT_BRAND.BRAND_ID`

**`UTM_CODE` อยู่ที่นี่** (`MT_UTM` 2,496 แถว) → ตามรอย campaign ที่พาลูกค้ามาได้ เชื่อมกับงาน CRM ที่ [[ITEC Overview|ITEC]] ทำอยู่ `[อนุมาน]`

**`Tradein_AMT` + `TRADE_IN_*`** — มีธุรกิจรับเทิร์นเครื่องเก่า สอดคล้องกับ model `buyback_iphone` ที่พบใน GI Core

**`INTEREST_FLAT` กับ `INTEREST_EFFECTIVE` เก็บคู่กัน** และ `INTEREST_EFFECTIVE` เป็น `nchar` (ข้อความ) ไม่ใช่ตัวเลข — ระวังตอนคำนวณ

---

## `PRODUCT` — 403,758 rows · 95 columns

1 แถวต่อ 1 ใบคำขอ/ใบเสนอราคา (`APP_ID`, `QUOTATION_ID`) เก็บเครื่องที่ปล่อยกู้พร้อมเงื่อนไขการเงินซ้ำจาก `QUOTATION`
`PRODUCT_CODE` · `PRODUCT_TYPE` (`MT_PRODUCT_TYPE`: `New Product` / `Used Product`)

**คอลัมน์ที่ใช้ทำเอกสารจริง** — `MODEL_NAME` (ชื่อรุ่นแบบอ่านออก) · `MODEL_NUMBER` (บาร์โค้ด) · `SERIAL_NUMBER` · `INSTALL_SUM` (ค่างวดรวม VAT) · `INSTALL_NUM` (จำนวนงวดจริง) · `FRIST_PAY_DATE` (งวดแรกครบกำหนด) · `DUEDATE_NUM` (วันครบกำหนด 1 หรือ 16)
→ ตารางแมปเต็ม [[K2 - Termination Letter Mapping]]

**มีสินเชื่อเครื่องมือสอง** — `Used Product` เป็นหนึ่งใน 2 ค่าของ `MT_PRODUCT_TYPE`

---

## `ACCOUNT` — 25,977,656 rows · 16 columns

**ตารางบัญชีแยกประเภท (GL) ไม่ใช่ตารางบัญชีลูกค้า** — ตารางใหญ่อันดับ 2 ของฐาน

`ACCOUNT_ID` · `CONTRACT_ID` · `CONTRACT_NUMBER` · `APP_ID` · `APP_NUMBER` · `REPAY_ID` · `PAY_ID` · `VOURCHER_NO`* · `DATE` · `DATE_POST` · `APAR_CODE` · `ACCOUNT_CODE` · `ACCOUNT_CATEGORY` · `ACCOUNT_DESCIPTION`* · `RECORD_TYPE` · `AMOUNT`

\* สะกดผิดทั้งคู่ในฐานจริง

26M แถว ต่อ 288k สัญญา ≈ **90 บรรทัดบัญชีต่อสัญญา** — ทุกงวด ทุกรายการมีคู่ debit/credit `[อนุมาน]`
`MT_ACCOUNT` (14) และ `MT_ACCOUNT_CATEGORY` (5) เป็นผังบัญชี

ตารางพี่น้อง: `ACCOUNT_RECEIVABLE` (5,711,805 · ลูกหนี้การค้า ใช้ prefix `R_`) · `ACCOUNT_CHECK_GL` (14,120,139) · `ACCOUNT_GENERAL` (2,896,269)

**ถ้าจะ ingest เข้า lake ตารางกลุ่มนี้คือส่วนที่ใหญ่ที่สุด** — `ACCOUNT` + `ACCOUNT_CHECK_GL` + `ACCOUNT_RECEIVABLE` + `ACCOUNT_GENERAL` ≈ 48.7 ล้านแถว ควรตัดสินก่อนว่าฝั่ง analytics ต้องการระดับ GL จริงไหม `[อนุมาน]`

---

## `CreditScrolling_Logs_Contract` — 239,757,512 rows

**ตารางใหญ่ที่สุดของฐาน** · 15 คอลัมน์ · สร้าง 2021-07-08 · แก้ล่าสุด 2025-07-02

`CreditScrolling_Logs_Contract_ID` (bigint) · `_DateTime` · `_Date` · `_Time` · `CONTRACT_ID` · `STATUS_ID` · `APP_ID` · `PERSON_ID` · `CIF_PERSON_ID` · `REPAY_ID` · `APPLICATION_NUMBER` · `CONTRACT_NUMBER` · `CONTRACT_START` · `CONTRACT_END` · `OVERDUE`

โครงสร้างเหมือน snapshot ของ `CONTRACT` พร้อม timestamp = log การเปลี่ยนสถานะ `[อนุมาน]`
แต่ **239.7M ÷ 288k = 832 แถวต่อสัญญา** ซึ่งมากผิดปกติสำหรับ log สถานะ

> **นี่คือความเสี่ยงต้นทุนอันดับหนึ่งของการ ingest K2** — ตารางเดียวใหญ่กว่าตารางอื่นทั้งหมดรวมกัน ต้องถาม MIS-Fintech ก่อนว่าเขียนบ่อยแค่ไหนและ analytics ต้องใช้จริงไหม

---

## เชื่อมกับโน้ตอื่น

[[K2 Overview]] · [[K2 - Data Dictionary]] · [[K2 - Query Cookbook]] · [[K2 - Business Rules]] · [[K2 - Payment & Invoice]] · [[K2 - Collection & OD]] · [[K2 - Master & Setup]] · [[K2 - Customer & Address]]
