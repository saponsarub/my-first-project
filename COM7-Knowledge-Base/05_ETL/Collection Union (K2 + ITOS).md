# Collection Union (K2 + ITOS)

รวมข้อมูลติดตามหนี้ของ **2 ระบบ** ให้เป็นชุดเดียว 58 คอลัมน์ พร้อมแท็กว่ามาจากระบบไหน

**ที่มา:** `collection_Union.txt` (SQL ที่ทีมใช้อยู่จริง) · รับเข้า vault 2026-08-28
งานที่กินผลลัพธ์นี้ → [[OD6 Collection Delivery]] · โครงการภาพรวม → [[K2 + ITOS Integration]]

---

## ทำอะไร

```
ITOS_COLLECTION_DETAIL          COLLECTION_OD_ASSIGNMENT
(ILOAN_DATASOURCE)              (HPCOM7 = K2)
        │                               │
        │  SELECT + CAST + COLLATE      │  SELECT + CAST + COLLATE
        └───────────► UNION ALL ◄───────┘
                         │
              58 คอลัมน์ + SOURCE_SYSTEM ('ITOS' / 'K2')
```

เป็น **query เดียว ไม่มี transformation ทางธุรกิจ** — แค่ปรับชนิดข้อมูลกับ collation ให้ตรงกันแล้วต่อท้ายกัน

---

## ทำไมต้อง CAST และ COLLATE ทุกคอลัมน์

| เหตุผล | รายละเอียด |
|---|---|
| **คนละฐาน คนละ collation** | `COLLATE DATABASE_DEFAULT` บังคับให้คอลัมน์ข้อความมา collation เดียวกัน ไม่งั้น UNION จะ error `cannot resolve collation conflict` |
| **ชนิดข้อมูลไม่ตรงกัน** | เช่น `NUMBER_OF_OD_INSTALLMENT` ฝั่ง K2 ไม่ใช่ int → ต้อง `CAST(... as int)` · `REMAINING_PRINCIPAL` แคสต์เป็น `float` ทั้งสองฝั่ง |
| **ชื่อคอลัมน์สะกดต่างกัน** | ดูตารางด้านล่าง |

### ชื่อที่สะกดต่างกันระหว่าง 2 ระบบ

| ชื่อผลลัพธ์ | ITOS | K2 |
|---|---|---|
| `CONTRACT_STATUS_ID` | `CONTRACT_STATUS_ID` | `CONTRACT_STATUS` |
| `PRODUCT_ID` | `PRODUCT_ID` | `PRODUDCT_ID` ⚠️ สะกดผิดในฐาน K2 |
| `TOTAL_PRINCIPAL` | `TOTAL_PRINCIPAL` | `TOTAL_PRINCIPLE` |
| `PAID_TOTAL_PRINCIPAL` | `PAID_TOTAL_PRINCIPAL` | `PAID_TOTAL_PRINCIPLE` |
| `REMAINING_PRINCIPAL` | `REMAINING_PRINCIPAL` | `REMAINING_PRINCIPLE` |
| `PAID_TOTAL_PRINCIPAL_TO_DUE` | `..._PRINCIPAL_TO_DUE` | `..._PRINCIPLE_TO_DUE` |
| `PRODUCT_NAME` | `PRODUCT_NAME` | `MODEL_NAME` |

> **Principal (เงินต้น) vs Principle (หลักการ)** — ITOS สะกดถูก K2 สะกดผิด
> รายละเอียดคำสะกดผิดอื่นๆ ของ K2 → [[K2 Overview]]

---

## คอลัมน์ที่ฝั่งใดฝั่งหนึ่งไม่มี

| คอลัมน์ | ITOS | K2 |
|---|---|---|
| `PRODUCT_MODEL` | ✅ มี | ❌ `NULL` |
| `PRODUCT_SERIAL_NO` | ✅ มี | ❌ `NULL` |
| `CREATE_DATE` | ✅ มี | ❌ `NULL` |
| `MODIFY_DATE` | ✅ มี | ❌ `NULL` |

**ผลกระทบ:** ทำ **incremental extraction จากฝั่ง K2 ผ่านมุมมองนี้ไม่ได้** เพราะไม่มี timestamp
ต้องใช้ `EXTRACT_DATE` (วันที่ snapshot) เป็นตัวแบ่งแทน — ดู [[K2 - Collection & OD]]

> หมายเหตุ: ตาราง**ต้นทาง**ของ K2 (`CONTRACT`, `PERSON`, `CUSTOMER_CARD`) **มี** `CREATE_DATE`/`UPDATE_DATE`
> ที่ขาดคือตาราง `COLLECTION_OD_ASSIGNMENT` ซึ่งเป็นตาราง snapshot ที่ระบบสร้างขึ้นเอง

---

## ⚠️ ข้อบกพร่องที่เจอใน SQL ปัจจุบัน

ต้องแก้ก่อนเอาเข้า pipeline จริง

| #   | ปัญหา                                                 | ผลกระทบ                                                                                                                                                                                                                    | วิธีแก้                                        |
| --- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| 1   | **`CAST(... AS nvarchar)` ไม่ระบุความยาว**            | SQL Server ใช้ค่า default = **30 ตัวอักษร** → `CUSTOMER_ADDRESS_REGISTER`, `CUSTOMER_ADDRESS_CURRENT`, `CUSTOMER_ADDRESS_DELIVERY`, `CUSTOMER_NAME`, `PRODUCT_NAME` **ถูกตัดปลายทิ้งเงียบๆ** — ที่อยู่ไทยยาวเกิน 30 แน่นอน | ระบุ `nvarchar(255)` / `nvarchar(500)` ตามจริง |
| 2   | `as PRODUCT_NAM` (ตกตัว E) ใน SELECT แรก              | UNION ยึดชื่อจาก SELECT แรก → คอลัมน์ผลลัพธ์ชื่อ `PRODUCT_NAM` ทั้งชุด                                                                                                                                                     | แก้เป็น `PRODUCT_NAME`                         |
| 3   | `b.LAST_REPAY_DATE asLAST_REPAY_DATE` (ไม่มีเว้นวรรค) | ยังรันได้ (ตีความ `asLAST_REPAY_DATE` เป็น alias) แต่สับสน                                                                                                                                                                 | เว้นวรรคให้ถูก                                 |
| 4   | `CAST(a.CONTRACT_ID AS int)` ฝั่ง ITOS                | ถ้ามีค่าที่แปลงเป็น int ไม่ได้ จะ error ทั้ง query                                                                                                                                                                         | ใช้ `TRY_CAST`                                 |
| 5   | ไม่มี `WHERE` กรอง `EXTRACT_DATE`                     | อ่านทุก snapshot ย้อนหลังทั้งหมด — `COLLECTION_OD` ฝั่ง K2 มี 15.6M แถว                                                                                                                                                    | เติม `WHERE EXTRACT_DATE = @snap`              |

> ข้อ 1 คือข้อที่ร้ายแรงที่สุด — **ข้อมูลหายโดยไม่มี error** ที่อยู่ที่ตัดเหลือ 30 ตัวอักษร ใช้ส่งจดหมายไม่ได้

---

## ความต่างเชิงธุรกิจที่ต้องรู้เมื่อรวม 2 ระบบ

| เรื่อง | K2 | ITOS |
|---|---|---|
| รูปแบบเลขสัญญา | ตัวเลขล้วน เช่น `2495733` | ขึ้นต้น **`TFF`** เช่น `TFF2510-005889` |
| วันครบกำหนดชำระ | **วันที่ 1 และ 16 เท่านั้น** | หลากหลาย — พบ 14, 20, 21, 22, 23, 26, 27 |
| ข้อมูลสินค้า | ไม่มีรุ่น/serial ในชุดนี้ | มีครบ |
| Timestamp | ไม่มีในชุดนี้ | มี |

**เลขสัญญาขึ้นต้น `TFF` = ระบบ ITOS** — ใช้เป็นวิธีแยกระบบแบบเร็วเวลาเห็นแค่เลขสัญญา
(นอกจากนี้ยังมีคอลัมน์ `SOURCE_SYSTEM` ให้ใช้ตรงๆ อยู่แล้ว)

---

## กลุ่มคอลัมน์ 58 ตัว

| กลุ่ม | คอลัมน์ |
|---|---|
| **Snapshot** | `EXTRACT_DATE` · `UPDATE_DATE` · `CREATE_DATE` · `MODIFY_DATE` · `SOURCE_SYSTEM` |
| **สัญญา** | `CONTRACT_ID` · `CONTRACT_NUMBER` · `CONTRACT_STATUS_ID` · `CONTRACT_STATUS_DESC` |
| **ยอดรวมทั้งสัญญา** | `TOTAL_OUTSTANDING` · `TOTAL_PRINCIPAL` · `TOTAL_INTEREST` · `TOTAL_VAT` · `NUMBER_OF_PERIOD` · `INSTALLMENT_PER_PERIOD` |
| **ยอดที่จ่ายแล้ว** | `PAID_TOTAL_OUTSTANDING` · `PAID_TOTAL_PRINCIPAL` · `PAID_TOTAL_INTEREST` · `PAID_TOTAL_VAT` · `PAID_NUMBER_OF_PERIOD` |
| **ยอดที่จ่ายแล้ว ณ งวดที่ครบกำหนด** | `PAID_TOTAL_OUTSTANDING_TO_DUE` · `PAID_TOTAL_PRINCIPAL_TO_DUE` · `PAID_TOTAL_INTEREST_TO_DUE` · `PAID_TOTAL_VAT_TO_DUE` |
| **ยอดคงเหลือ** | `REMAINING_OUTSTANDING` · `REMAINING_PRINCIPAL` · `REMAINING_INTEREST` · `REMAINING_VAT` · `REMAINING_PERIOD` |
| **ค้างชำระ** | `NUMBER_OF_OD_INSTALLMENT` · `OD_AMOUNT` · `PENALTY_AMT` · `COLLECT_AMT` · `TOTAL_FOLLOW_UP_AMOUNT` |
| **งวด/ใบแจ้งหนี้** | `PERIOD_DUE_DATE` · `LAST_REPAY_DATE` · `INVOICE_NUMBER` · `INVOICE_DATE` · `IS_FIRST_DUE` · `IS_LAST_DUE` |
| **การมอบหมายงานติดตาม** | `ASSIGN_TO_TEAM` · `EMP_CODE` · `EMP_NAME` |
| **ลูกค้า (PII)** | `CUSTOMER_NAME` · `CUSTOMER_BIRTH_DATE` · `CUSTOMER_PHONE_NUM` · `CUSTOMER_OCCUPATION` · `CUSTOMER_ADDRESS_REGISTER` · `CUSTOMER_ADDRESS_CURRENT` · `CUSTOMER_ADDRESS_DELIVERY` |
| **ผู้ค้ำ (PII)** | `GUARANTOR_NAME` · `GUARANTOR_RELATION` · `GUARANTOR_PHONE_NUM` |
| **สินค้า** | `PRODUCT_ID` · `PRODUCT_TYPE` · `PRODUCT_NAME` · `PRODUCT_MODEL` · `PRODUCT_SERIAL_NO` |

ความหมายรายฟิลด์ฝั่ง K2 → [[K2 - Data Dictionary]] · [[K2 - Collection & OD]]

---

## ⚠️ PII

ชุดนี้มี **ชื่อ · วันเกิด · เบอร์โทร · ที่อยู่ 3 ชุด · อาชีพ · ข้อมูลผู้ค้ำ** ครบ
ห้าม export ออกนอกระบบโดยไม่ mask · ห้าม commit ลง git
กติกา → [[Consent & PDPA]]

---

## เชื่อมกับโน้ตอื่น

[[K2 + ITOS Integration]] · [[OD6 Collection Delivery]] · [[K2 - Collection & OD]] · [[ITOS Overview]] · [[ETL & Spark]] · [[SQL & Source Schemas]]
