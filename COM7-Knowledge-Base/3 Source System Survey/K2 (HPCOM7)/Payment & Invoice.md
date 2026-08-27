# K2 — Payment & Invoice

ค่างวด · ใบแจ้งหนี้ · การรับชำระ · เอกสารภาษี · survey 2026-08-26

---

## เส้นทางการเก็บเงิน

```
CONTRACT ──► CUSTOMER_CARD ──► INVOICE ──► REPAYMENT ──► ACCOUNT
             5,816,540         4,396,632   5,205,081     25,977,656
             ตารางผ่อนรายงวด      ใบแจ้งหนี้     รับชำระจริง     ลงบัญชี

ช่องทางรับเงิน:  LOG_SCB_BILLPAYMENT (8.0M) · LOG_SCB_BILLPAYMENT_AUTO (7.1M)
                 BANK_IMPRORT (4.4M) · TTP_QR_DOWN (237k) · LOG_SCB_DOWNPAYMENT (116k)
เอกสารภาษี:      TAX_INVOICE (5.2M) · TTP_VAT_RPT (4.8M) · TTP_INV_BARCODE (4.5M)
```

---

## `CUSTOMER_CARD` — 5,816,540 แถว · 26 คอลัมน์

### ⚠️ ชื่อหลอก — **ไม่ใช่ตารางลูกค้า**

เป็น **"การ์ดลูกหนี้" 1 แถวต่อ 1 งวดผ่อน** ของ 288,198 สัญญา · `INSTALL_NUM` ตั้งแต่ 1 ถึง **84**

ใครที่เห็นชื่อ `CUSTOMER_CARD` แล้วคิดว่าเป็นทะเบียนลูกค้าจะได้ผลผิดทันที — ข้อมูลลูกค้าอยู่ที่ `PERSON` ดู [[Customer & Address]]

| กลุ่ม | คอลัมน์ |
|---|---|
| คีย์ | `ID`, `CONTRACT_ID`, `CONTRACT_NUMBER`, `APPLICATION_NUMBER`, `INSTALL_NUM` |
| งวด | `DUEDATE`, `INSTALL_AMT`, `PAY_PRINCIPLE`*, `PAY_INTEREST`, `PAY_INSTALL_VAT` |
| ยอดคงเหลือ | `OUTSTD_SUM_PRINCIPLE`, `OUTSTD_SUM_INTEREST`, `SUM_OUTSTAND` |
| ค้างชำระ | `INSTALL_OD_01`, `INSTALL_OD_02`, `INSTALL_OD_SUM`, `SUM_OD_AMT`, `PENALTY_AMT`, `COLLECT_AMT` |
| เอกสาร | `INVOICE_NUMBER`, `RECEIPT_NUMBER` |
| ประกัน/ค่าธรรมเนียม | `REVENUE_INS_MARGIN`, `REVENUE_INS_MARGIN_OUTSTD`, `FEE_INSTALL`, `FEE_SUM` |
| ส่วนลด | `DISCOUNT_AMT` |

\* `PRINCIPLE` ควรเป็น `PRINCIPAL` — typo ที่ vault บันทึกไว้แล้ว

**5.8M ÷ 288k = เฉลี่ย 20 งวดต่อสัญญา** สอดคล้องกับ `MT_INSTALLMENT` ที่เปิดใช้ 9/12/18/24/36 งวด

**`DUEDATE` มีแค่ 2 ค่าทั้งตาราง — วันที่ 1 (3,000,934 งวด) และ 16 (2,815,636 งวด)**
**`RECEIPT_NUMBER IS NOT NULL` = งวดนั้นชำระแล้ว** (4,335,203 ชำระ · 1,481,373 ยังไม่ชำระ)
สองกฎนี้มาจากเอกสารความรู้ของทีม ตรวจกับฐานแล้ว → [[Business Rules]] ข้อ 1–2

**คอลัมน์ยอดค้างเก็บเป็น `nvarchar`** — `INSTALL_OD_01`, `INSTALL_OD_02`, `INSTALL_OD_SUM` เป็นข้อความไม่ใช่ตัวเลข ต้อง cast ก่อนคำนวณ (ปัญหาเดียวกันปรากฏใน `COLLECTION_OD.NUMBER_OF_OD_INSTALLMENT`)

ตัวอย่างจริง (สัญญา 24 งวด ค่างวด 2,062.95): งวด 1 = เงินต้น 666.37 + ดอกเบี้ย 1,261.62 → งวด 4 = เงินต้น 761.01 + ดอกเบี้ย 1,166.98 — **ดอกเบี้ยลดลงตามเงินต้นแบบ effective**

---

## `INVOICE` — 4,396,632 แถว · 24 คอลัมน์

`INVOICE_ID` · `INVOICE_NUMBER` · `CONTRACT_ID` · **`CUSTOMER_CARD_ID`** · `INVOICE_DATE` · `DUE_DATE` · `STATUS_ID` · `INVOICEE_TYPE`

ยอด: `AMOUNT`, `VAT_AMT`, `WHT_AMT`, `SUM_AMT`, `DES_SUM_AMT` (จำนวนเงินเป็นตัวอักษร)
ค้าง: `AMT_OLD`, `INSTALL_NUM_OLD`, `INSTALL_OUTSTAND`, `SUM_OUTSTAND`, `INSTALL_CURRENT`, `INSTALL_OD_01/02/SUM`, `SUM_OD_AMT`, `PENALTY_AMT`, `COLLECT_AMT`

**`CUSTOMER_CARD_ID` คือกาวที่เชื่อมใบแจ้งหนี้กับงวดผ่อน** — ใบแจ้งหนี้ 1 ใบผูกกับ 1 งวด

4.4M ใบแจ้งหนี้ ต่อ 5.8M งวด → **ไม่ใช่ทุกงวดที่ออกใบแจ้งหนี้** (งวดในอนาคตยังไม่ออก) `[อนุมาน]`

---

## `REPAYMENT` — 5,205,081 แถว · 47 คอลัมน์

การรับชำระจริง ครอบคลุม 287,553 สัญญา

**โครงสร้างสองชั้น: `REPAY_*` = ยอดที่ต้องชำระ · `PAY_*` = ยอดที่ชำระจริง**

| ชั้น | คอลัมน์ |
|---|---|
| ต้องชำระ | `REPAY_DATE`, `REPAY_NAME`, `REPAY_AMOUNT`, `REPAY_PENALTY`, `REPAY_COLLECT`, `REPAY_VAT`, `REPAY_WHT`, `REPAY_DISCOUNT`, `REPAY_SUM_AMOUNT` |
| ชำระจริง | `PAY_DATE`, `PAY_NAME`, `PAY_AMT`, `PAY_PENALTY`, `PAY_COLLECT`, `PAY_VAT`, `PAY_DISCOUNT`, `PAY_SUM_AMT` |
| ส่วนต่าง | **`OVER_AMT`** (ชำระเกิน) · **`LACK_AMT`** (ชำระขาด) |
| ยกเว้น | `PENALTY_WAVE_AMT`, `COLLECT_WAVE_AMT` |
| เงินสำรอง | `RESERVE_AMOUNT`, `FLAG_RESERVE`, `USE_RESERVE_AMT` |
| ปิดก่อนกำหนด | **`FLAG_EARLY_CLOSE`** |
| เอกสาร | `RECEIPT_NUMBER`, `TAX_NUMBER`, `PHY_NUMBER`, `CREDIT_NOTE_NUMBER` |
| เชื่อม | `CONTRACT_ID`, `CUSTOMER_CARD_ID`, `APP_ID`, `INVOICE_ID`, `BANK_CODE` |

**`OVER_AMT` / `LACK_AMT` มีอยู่จริง** → ลูกค้าชำระไม่ตรงยอดเป็นเรื่องปกติ ระบบรองรับไว้ ไม่ควรสมมติว่ายอดชำระ = ยอดงวด `[อนุมาน]`

### เงินที่จ่ายเข้ามาถูกตัดแบบแนวนอน

```
ค่าปรับ  →  ค่าติดตามทวงถาม  →  ดอกเบี้ย  →  เงินต้น        (ทีละงวดจนครบ แล้วข้ามไปงวดถัดไป)
```

**ลูกค้าที่จ่ายไม่เต็มจะไม่ได้ลดเงินต้นเลย** เพราะเงินถูกกินโดยค่าปรับกับค่าติดตามก่อน `[อนุมาน]`
เป็นเหตุผลที่ `REPAY_TYPE` ต้องแยกประเภท — เงินก้อนเดียวถูกแตกไปหลายรายการ
→ **ทำรายงาน "จ่ายค่างวดไปเท่าไหร่" ต้องกรอง `REPAY_TYPE` ไม่ใช่รวมทั้งก้อน** · ที่มา [[Fee Policy]]

**`PAY_NAME` มี index (`INNO_PAY_NAME`)** — ชื่อผู้ชำระอาจไม่ใช่ผู้ทำสัญญา ระบบตั้งใจให้ค้นได้

### `REPAY_TYPE` — จาก `MT_REPAY_TYPE`

| รหัส | ความหมาย | จำนวนแถวทั้งฐาน |
|---|---|---:|
| 2 | ค่างวดเช่าซื้อ | 4,396,628 |
| 4 | ค่าติดตามทวงถาม | 515,382 |
| 1 | เงินดาวน์ | 291,263 |
| 3 | ค่าเบี้ยปรับ | (รวมอยู่ใน NULL/อื่น) |
| 5 | ค่าเช่าซื้อ | |
| NULL | | 1,809 |

**ค่าติดตามทวงถาม 515,382 รายการ** ≈ 10% ของรายการรับชำระทั้งหมด — เป็นรายได้ของธุรกิจอีกทาง `[อนุมาน]`

### Index เยอะผิดปกติ

`REPAYMENT` มี **21 index** ส่วนใหญ่เป็น covering index ชื่อยาวแบบ `INDEX_NCL_REPAYMENT_CONTRACT_ID_REPAY_TYPE_STATUS_ID_...`
→ ตารางนี้ถูก query หนักมากในการทำรายงาน และมีคนมานั่ง tune แล้ว `[อนุมาน]` **การเพิ่ม load จาก ETL ต้องระวัง**

### ข้อมูลผิดที่เจอ

`MIN(REPAY_DATE) = 1067-07-09` — **ปีพุทธศักราชถูกกรอกผิดเป็น ค.ศ.** อย่างน้อย 1 แถว
→ ต้องมี date range filter ตอน ingest ไม่งั้น partition จะแตกไปปี 1067

---

## `PAYMENT` — 286,196 แถว · 24 คอลัมน์

**เงินขาออก ไม่ใช่เงินเข้า** — จ่ายให้พาร์ทเนอร์ที่ขายเครื่อง

`PAYMENT_ID` · `APP_ID` · `PV_ID` · `PV_NUMBER` · `PO_NUMBER` · `INV_PN_NUMBER`
`SUBSIDY_PAY` · `REBATE` · `DEDUCT_DOWN_AMT` · `DEDUCT_FEE_HP` · `DEDUCT_SUBSIDY_RECEIPT`
`AMOUNT` · `WHT_AMOUNT` · `VAT_AMOUNT` · `SUM_AMOUNT` · `PAY_TYPE` · `BANK` · `BANK_BRANCH` · `CHEQUE_NUMBER` · `ACCOUNT_NUMBER`

`MT_TYPE_PAYMENT` มีค่าอย่าง "ค่า Commission", "ค่า Commission Extra 1–3" → **จ่ายค่าคอมให้คนขาย**
คู่กับ `PURCHASE_ORDER` (290,213) และ `RECORD_RECEIPT_PAYMENT` (286,258) — ทั้งสามใกล้เคียง 288k สัญญา = **1 ชุดต่อ 1 สัญญา** `[อนุมาน]`

`MT_TYPE_PAYMENT` ยังมี "ค่ารถยนต์" ซึ่งไม่เข้ากับธุรกิจเครื่อง IT — น่าจะเป็น master ที่ copy มาจากระบบเช่าซื้อรถ `[อนุมาน]`

---

## ช่องทางรับชำระ

| ตาราง | แถว | คืออะไร |
|---|---:|---|
| `LOG_SCB_BILLPAYMENT` | 8,046,041 | bill payment ผ่าน SCB |
| `LOG_SCB_BILLPAYMENT_AUTO` | 7,091,407 | หักบัญชีอัตโนมัติ SCB |
| `BANK_IMPRORT`* | 4,411,373 | ไฟล์ import จากธนาคาร |
| `TRANSACTION_REPAY` | 9,726,871 | 7 คอลัมน์ · แก้ล่าสุด 2022-03-17 |
| `TTP_QR_DOWN` | 237,610 | จ่ายดาวน์ด้วย QR |
| `LOG_SCB_DOWNPAYMENT` | 116,117 | จ่ายดาวน์ผ่าน SCB |
| `RESERVER_REPAYMENT` | 619,320 | เงินสำรองรอตัดชำระ |

\* สะกดผิด (`IMPRORT`)

**SCB เป็นธนาคารหลักของช่องทางรับชำระ** — 15.1 ล้านแถวรวมสองตาราง ไม่มีตาราง log ของธนาคารอื่น
`MT_BANK` มี 10 ธนาคาร (BBL, KBANK, KTB, SCB, BAY, GSB, TTB, UOB, BAAC, OTH) แต่ใช้สำหรับบันทึกบัญชีลูกค้า ไม่ใช่ช่องทางรับเงิน `[อนุมาน]`

`TRANSACTION_REPAY` มี 9.7M แถวแต่ **หยุดอัปเดตตั้งแต่ 2022-03-17** — เป็นตารางเก่าที่เลิกใช้แล้วหรือเปล่า ต้องยืนยัน

---

## เอกสารภาษี

| ตาราง | แถว |
|---|---:|
| `TAX_INVOICE` | 5,242,720 |
| `TTP_VAT_RPT` | 4,809,559 |
| `TTP_INV_BARCODE` | 4,477,750 |
| `TTP_CONTRACT_DUTY_RPT` | 576,386 |
| `CONTRACT_DUTY` | 288,609 |
| `LOG_ReGenTAX` | 722,708 |
| `PDF_FORM` | 2,553,530 |

`CONTRACT_DUTY` 288,609 ≈ จำนวนสัญญาพอดี = **อากรแสตมป์ 1 ชุดต่อ 1 สัญญา** `[อนุมาน]`

**`TTP_*` เป็นชั้น reporting/interface ทั้งหมด 42 ตาราง** — `_RPT` ลงท้าย = รายงาน · `TTP_VOUCHER_DETAIL` (14.5M) ใหญ่เป็นอันดับ 4 ของฐาน
ยังไม่รู้ว่า `TTP` ย่อมาจากอะไร

`PDF_FORM` 2.5M แถว — ถ้าเก็บ PDF เป็น binary ในฐาน นี่คือน้ำหนักที่ไม่ควรลาก mai ไป lake `[อนุมาน]`

---

## คำถามที่ยังเปิด

- `TTP_` ย่อมาจากอะไร ใครเป็นเจ้าของชั้นนี้
- `TRANSACTION_REPAY` (9.7M) เลิกใช้แล้วจริงไหม (ไม่อัปเดตตั้งแต่ 2022-03)
- `PDF_FORM` เก็บ binary ในฐานหรือเก็บแค่ path
- `REPAY_TYPE` 3 (ค่าเบี้ยปรับ) กับ 5 (ค่าเช่าซื้อ) ใช้จริงไหม
- แถวที่ `REPAY_DATE` เป็นปี 1067 มีกี่แถว มีข้อมูลผิดปีแบบอื่นอีกไหม
- ช่องทางรับชำระอื่นนอก SCB บันทึกที่ไหน

---

## อ่านต่อ

[[K2 Overview]] · [[Query Cookbook]] · [[Business Rules]] · [[Fee Policy]] · [[Contract & Account]] · [[Collection & OD]] · [[Master & Setup]]
