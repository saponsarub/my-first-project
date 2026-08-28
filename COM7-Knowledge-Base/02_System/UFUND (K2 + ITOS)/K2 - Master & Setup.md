# K2 — Master & Setup

ตาราง master (`MT_*`) และ setup (`SETUP_*`) พร้อมค่าจริง · survey 2026-08-26

ค่าในหน้านี้ไม่ใช่ PII จึงเก็บค่าจริงได้ · ใช้เป็น lookup ตอนอ่านผลคิวรี่จาก [[K2 - Query Cookbook]]

---

## `MT_STATUS` — 61 statuses shared system-wide

ตารางเดียวนี้ถูกใช้เป็น `STATUS_ID` ของทั้งใบเสนอราคา ใบคำขอ สัญญา การชำระ และการทวงถาม
join ด้วย `MT_STATUS.HP_STA_ID`

| ช่วง | สถานะ | ใช้กับ |
|---|---|---|
| 1–6 | Save draft · Wait Checker · Wait Approve · **Approve** · Rework · Reject | ใบคำขอ |
| 7–12 | Wait Registration ABM · Wait Deliver · **ลูกหนี้ปกติ (9)** · Delived · Auto Approve · Wait Key Serial Number | ส่งมอบเครื่อง |
| 13–18 | Approve/Rework/Reject Return Assets · Wait Registration ABM · Wait Deliver · Wait Return Assets | คืนเครื่อง |
| 19–26 | Wait Generate · Generate · Wait Deposit Contract · Deposit Complete · Wait Welcome Call · Wait Contact Again · New Import · Import Complete | งานเอกสาร |
| 27–30 | Quotation · Convert Application · Active · In active | ใบเสนอราคา |
| 31–42 | Wait Repay · Repay Complete · Confirm Payment Complete · Wait Payment · **Close Contract (40)** · Record Receipt Complete · Complete | การชำระ |
| **43–48** | **Overdue 1 · 2 · 3 · 4 · 5 · 6** | ค้างชำระ |
| 49–56 | Cancel Contract · Collection · Reserver · Reserver Complete · **ลูกหนี้ปิดบัญชีล่วงหน้า (53)** · **ลูกหนี้บอกเลิกสัญญา (54)** · Open · **ขายหนี้ (56)** | จบสัญญา |
| 60–63 | Regen PO · Quotation NewHP · **Write Off (62)** · Write Off (ปิดบัญชี) (63) | ตัดหนี้สูญ |
| 999 | Pre Approve | |

**ปนกันระหว่างไทยกับอังกฤษในตารางเดียว** — 9, 53, 54, 63 เป็นภาษาไทย ที่เหลือเป็นอังกฤษ · มีชื่อซ้ำ (7 กับ 16 = "Wait Registration ABM", 8 กับ 17 = "Wait Deliver", 19 กับ 34 = "Wait Generate")
→ ถ้าจะทำ dimension ของสถานะที่ Silver ต้อง map ใหม่ ไม่ควรใช้ชื่อดิบ `[อนุมาน]`

**Overdue มี 6 ขั้น (bucket)** สอดคล้องกับ ITOS ที่มี `M_BUCKETAREA`

---

## Geography — the most used masters

| ตาราง             |   แถว | คอลัมน์                                                |
| ----------------- | ----: | ------------------------------------------------------ |
| `MT_PROVINCE`     |    77 | `PROVINCE_ID`, `PROVINCE_NAME`, `ZONE_ID`              |
| `MT_DISTRICT`     |   928 | `DISTRICT_ID`, `DISTRICT_NAME`, `PROVINCE_ID`          |
| `MT_SUB_DISTRICT` | 7,436 | `SUB_DISTRICT_ID`, `SUB_DISTRICT_NAME`, `DISTRICT_ID`  |
| `MT_POST_CODE`    | 7,537 | `POST_CODE_ID`, `SUB_DISTRICT_ID`, `SUB_DISTRICT_NAME` |
| `MT_ZONE`         |     7 | โซนภูมิภาค                                             |
| `MT_HUB`          |     7 |                                                        |
| `MT_RSM_ASM`      |   427 | พื้นที่ขาย                                             |

รหัสเป็นแบบมาตรฐานไทย: จังหวัด 2 หลัก (กรุงเทพ = 10) · อำเภอ 4 หลัก (1001 = พระนคร) · ตำบล 6 หลัก (100101 = พระบรมมหาราชวัง)

**77 จังหวัด** — ไม่รวมบึงกาฬ (จริงมี 77 จังหวัด ตัวเลขถูกแล้ว)

> ⚠️ `ADDRESS.A*_PROVINCE` เก็บรหัสเป็น **ข้อความ** ต้อง `TRY_CAST(... AS int)` ก่อน join
> มีตารางคู่ขนาน `TTA_PROVINCE` (77) / `TTA_DISTRICT` (928) / `TTA_SUB_DISTRICT` (7,537) ที่มีคอลัมน์เยอะกว่า — ยังไม่รู้ว่าใช้ต่างกันยังไง

---

## `MT_ADDRESS_TYPE` — 5 values

| ID | ชื่อ | ตรงกับคอลัมน์ |
|---|---|---|
| 1 | ที่อยู่ตามทะเบียน | `A1_*` |
| 2 | ที่อยู่ปัจจุบัน | `A2_*` |
| 3 | ที่อยู่ติดต่อได้ | `A3_*` |
| 4 | ที่อยู่จัดส่งเอกสาร | `A4_*` |
| 5 | อื่น ๆ | (ไม่มีคอลัมน์คู่) |

ยืนยันด้วยค่า `A1_MASTER = 1` และ `A2_MASTER = 2` ในข้อมูลจริง

---

## Products

### `MT_CATEGORY` — device category

`Smart Phone` · `Tablet` · `Laptop` · `Other Category`
มี 2 ชุด (`GROUP_CATE_ID` 1 และ 2) โดยชุด 2 ปิดใช้งานแล้ว (`ACTIVE_STATUS = F`)

### `MT_BRAND` — 39 rows

`Apple` · `Samsung` · `Xiaomi` · `Vivo` · `OPPO` · `Realme` · `Lenovo` · `Apple (UFicon)`

คอลัมน์ `ACTIVE_STATUS` / `ACTIVE_STATUS_PFUND` / `UPhone_Active` แยกกัน → **แบรนด์ที่เปิดให้ผ่อนไม่เหมือนกันในแต่ละผลิตภัณฑ์**

### `MT_PRODUCT_TYPE` — 2 values

`01 New Product` · `02 Used Product` → **มีสินเชื่อเครื่องมือสอง**

ตารางลูก: `MT_SERIES` (1,071) · `MT_SUB_SERIES` (1,800) · `MT_COLOR` (2,640) · `MT_GROUP_BRAND` (39)

---

## Credit terms

### `MT_INSTALLMENT` — enabled instalment counts

| งวด | UFund | PFund |
|---|---|---|
| 3 | ✗ | ✗ |
| 6 | ✗ | ✗ |
| **9** | ✓ | ✓ |
| **12** | ✓ | ✓ |
| 15 | ✗ | ✗ |
| **18** | ✓ | ✓ |
| **24** | ✓ | ✓ |
| **36** | ✓ | ✓ |
| 48 | ✗ | **✓** |

**มีผลิตภัณฑ์ที่สองชื่อ PFund** ที่ผ่อนได้ถึง 48 งวด — ยังไม่รู้ว่าคืออะไร (`ASSETS_INFORMATION_PFUND` 974 แถว · `EFFECTIVE_RATE_PFUND` 98)

ตารางเงื่อนไขอื่น: `MT_DownPercent` (5,801) · `MT_DOWN` (7) · `MT_BALLOON_INSTALLMENT` (22) · `SETUP_CREDIT_LIMIT` (27) + `SETUP_CREDIT_LIMIT_DETAIL` (12,995) · `MT_SALARY_RANGE` (11) · `SETUP_UW_APR_CRITERIA` (24) · `SETUP_GUARANTOR_CONDITION` (10) · `MT_HP_TRADE_IN_CAMPAIGN` (1,083)

---

## Occupation and education

### `MT_OCCUPATION` — 43 rows

| ID | ชื่อ | `GROUP_RISK` |
|---|---|---|
| 0 | อื่นๆ | 3 |
| 1 | **นักเรียน/นักศึกษา** | 3 |
| 2 | ข้าราชการ | 1 |
| 3 | พนักงานรัฐวิสาหกิจ | 1 |
| 4 | ข้าราชการเกษียณอายุ | 2 |

มี `GROUP_INCOME`, `GROUP_TYPE`, `GROUP_RISK` และชื่ออังกฤษ (`Ascend_Name_En`)
→ **อาชีพถูกใช้ในการให้คะแนนความเสี่ยงโดยตรง** นักศึกษาอยู่กลุ่มเสี่ยงสูงสุด (3) เท่ากับ "อื่นๆ" `[อนุมาน]`

`Ascend_Name_En` — "Ascend" เป็นชื่อบริษัทฟินเทค อาจเป็น mapping ไปยังระบบภายนอก `[อนุมาน]`

### Education

`MT_FACULTY` (39,475) · `MT_UNIVERSITY_NAME` (1,149) · `MT_LEVEL` (8) · `MT_LEVEL_TYPE` (8)

**39,475 คณะ** — ละเอียดผิดปกติสำหรับ master table เข้าเค้าว่าเป็นข้อมูลคณะ×มหาวิทยาลัยที่ import มา `[อนุมาน]`

---

## Banks — `MT_BANK`, 10 rows

| ID | ชื่อ | ABBV |
|---|---|---|
| 1 | ธนาคารกรุงเทพ | BBL |
| 2 | ธนาคารกสิกรไทย | KBANK |
| 3 | ธนาคารกรุงไทย | KTB |
| 4 | ธนาคารไทยพาณิชย์ | SCB |
| 5 | ธนาคารกรุงศรีอยุธยา | BAY |
| 6 | ธนาคารออมสิน | GSB |
| 7 | ธนาคารทหารไทยธนชาต | TTB |
| 8 | ธนาคารยูโอบี | UOB |
| 9 | ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร | BAAC |
| 10 | สถาบันการเงินอื่นๆ | OTH |

`MT_BANK_ACCOUNT` (11) แยกต่างหาก

---

## Companies and branches

### `SETUP_COMPANY` — the lender

id 121 = **บริษัท ธันเดอร์ ฟินฟิน จำกัด**
เลขนิติบุคคล `0105558011806` · ทุนจดทะเบียน 150,000,000 บาท · จดทะเบียน 2015-06-21 · `info@thunderfinfin.com` · เว็บ `www.comseven.com`

> เก็บ **ไฟล์แนบเป็น base64 ในคอลัมน์จริง** — โลโก้ (`C_LOGO`), ลายเซ็นผู้มีอำนาจ (`C_DS_FILE_AUTHORIZED`), หนังสือรับรองบริษัท PDF (`REGISTRATION_DOC`)
> เป็นหลักฐานยืนยันว่าฐานนี้เก็บไฟล์เป็น base64 จริง ไม่ใช่แค่ path — สำคัญต่อการประเมินขนาด ingestion

### `SETUP_PARTNER` — selling stores

| ID | บริษัท | สัญญา |
|---|---|---:|
| 1024 | บริษัท คอมเซเว่น จำกัด (มหาชน) | 283,144 |
| 1029 | บริษัท ยูฟิคอน จำกัด | 2,968 |
| 1030 | บริษัท เอส พี วี ไอ จำกัด (มหาชน) | 1,885 |
| 1026 | บริษัท ไพร์ม โซลูชั่น แอนด์ เซอร์วิส จำกัด | 1 |
| 1027, 1028 | (ชื่อว่าง) | |

`SETUP_PARTNER_BRANCH` 1,927 สาขา · `SETUP_COMPANY_BRANCH` 1,926 · `MT_BRANCH_TYPE` 13

**~1,900 สาขา** เป็นตัวเลขที่ยืนยันจากฐานจริง — ต่างจาก "1,000 สาขา" ที่ [[Home|README]] เตือนว่าเป็นตัวเลขที่ AI แต่งขึ้นในเวอร์ชันแรก **ตัวเลขนี้มาจาก `SETUP_PARTNER_BRANCH` และเป็นจำนวนสาขาในระบบ K2 ไม่ใช่จำนวนสาขาทั้งเครือ**

---

## Other masters found

| ตาราง | แถว | คืออะไร |
|---|---:|---|
| **`FeeControl`** | **3** | **อัตราค่าธรรมเนียม** — late fee 100 · track fee 50 · discount 50 · มี `EffectiveDate`/`ExpiryDate` → [[K2 - Fee Policy]] |
| `MT_PACKAGE_SIM` | 13,018 | แพ็กเกจซิมพ่วง |
| `MT_UTM` | 2,496 | รหัส campaign |
| `MT_INSURE` (+ `_REVENUE`, `_COMPANY`, `_BRAND`) | 332 / 420 / 5 / 8 | ประกันภัยเครื่อง |
| `MT_Icare_InsurancePercent` | 46 | ประกัน iCare |
| `MT_PREFIX` / `MT_PREFIX_ENG` | — | **คำนำหน้าชื่อ** — `PERSON.PREFIX` เก็บรหัส ต้อง join `Prefix_ID` ถึงได้คำว่า นาย/นาง/นางสาว |
| `MT_MARITAL_STATUS` | 6 | สถานภาพสมรส |
| `MT_RESIDENCE_STATUS` | 16 | สถานะที่อยู่อาศัย |
| `MT_RELATIONSHIP_REF` | 5 | ความสัมพันธ์ผู้อ้างอิง |
| `MT_DISEASE` | 9 | **โรคประจำตัว** |
| `MT_BLACKLIST_LEVEL` | 5 | ระดับ blacklist |
| `MT_APPROVE_CUSTOMER` | 9 | ระดับอนุมัติลูกค้า |
| `MT_Ufund_Acknwoledge`* | 24 | ข้อความรับทราบ |
| `MT_CUSTOMER_SIM` | 3 | |
| `MT_HOLIDAY` | — | (ไม่พบ ต่างจาก ITOS ที่มี 730) |

\* สะกดผิด (`Acknwoledge`)

**`MT_DISEASE` 9 แถว + `PERSON.Disease_ID` / `Narcotic_ID`** = ระบบเก็บข้อมูลสุขภาพและประวัติยาเสพติด
→ ตาม PDPA มาตรา 26 นี่คือข้อมูลอ่อนไหวชั้นสูงที่ต้องมีฐานทางกฎหมายแยกจาก consent ทั่วไป `[อนุมาน]` — ควรยกเป็นประเด็นถาม legal ดู [[Consent & PDPA]]

---

## Naming observations

| prefix | ความหมาย | ตัวอย่าง |
|---|---|---|
| `MT_` | master / lookup | `MT_STATUS`, `MT_PROVINCE` |
| `SETUP_` | ค่าตั้งค่าระบบและองค์กร | `SETUP_PARTNER`, `SETUP_CREDIT_LIMIT` |
| `TTP_` | ชั้น reporting / interface (42 ตาราง) | `TTP_VAT_RPT` |
| `LOG_` / `LOGS_` | log | `LOG_SCB_BILLPAYMENT` |
| `NCAP_` | interface ภายนอก (ยังไม่รู้ว่าอะไร) | `NCAP_INFORMATION` |
| `HPAP_` | ตารางเล็กมาก 54–219 แถว | `HPAP_CUSTOMER_MAST` |
| `Report_` | รายงานที่ materialize ไว้ | `Report_Aging` |
| `EGG_` | **views 65 ตัว** | `EGG_PERSON`, `EGG_MDM` |

**ไม่มีระบบตั้งชื่อที่สม่ำเสมอเท่า ITOS** (ที่ใช้ `M_` master · `S_` core · `T_` transaction · `R_` report)
K2 ผสม PascalCase (`CreditScrolling_Logs_Contract`), UPPER_SNAKE (`CUSTOMER_CARD`), และ camelCase (`MT_DebtContactStatus`) ในฐานเดียว
→ **การ normalize ชื่อที่ Bronze จะต้องมีกฎมากกว่าที่ใช้กับ ITOS** `[อนุมาน]`

---

## เชื่อมกับโน้ตอื่น

[[K2 Overview]] · [[K2 - Query Cookbook]] · [[K2 - Table Inventory]] · [[K2 - Customer & Address]] · [[K2 - Contract & Account]]
