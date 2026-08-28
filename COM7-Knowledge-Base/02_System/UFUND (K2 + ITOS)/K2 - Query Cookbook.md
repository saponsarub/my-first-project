# K2 — Query Cookbook

คิวรี่ที่ **รันจริงบน `HPCOM7` แล้วได้ผล** เมื่อ 2026-08-26 · ทุกอันบอกเวลาที่ใช้และจำนวนแถวที่ได้
คัดลอกไปใช้ได้เลย เปลี่ยนแค่ค่าที่ค้นหา

> ⚠️ ทุกคิวรี่ในหน้านี้ดึง **ข้อมูลส่วนบุคคลจริง** — ชื่อ เลขบัตร ที่อยู่ เบอร์โทร
> อย่า export ลงไฟล์ที่ commit เข้า git · ดู [[Consent & PDPA]]

**ต้องรู้ก่อน 3 ข้อ**

1. ใส่ `N` นำหน้า literal ภาษาไทยเสมอ — `WHERE FIRST_NAME = N'สมชาย'` ไม่ใช่ `'สมชาย'` เพราะฐานใช้ collation `SQL_Latin1_General_CP1_CI_AS`
2. `A*_PROVINCE` เก็บ **รหัสจังหวัดเป็นข้อความ** ต้อง `TRY_CAST(... AS int)` ก่อน join `MT_PROVINCE` ส่วน `A*_DISTRICT` / `A*_SUBDISTRICT` เป็น `int` อยู่แล้ว
3. `PERSON` **ไม่ใช่ทะเบียนลูกค้าที่ไม่ซ้ำ** — คนเดียวมีได้หลาย `PERSON_ID` ค้นด้วย `TAX_ID` ถ้าต้องการทุกใบของคนเดียวกัน ดู [[K2 - Customer & Address]]

---

## 1 · All address blocks for a customer, by `PERSON_ID`

**คิวรี่หลักของหน้านี้** — คืนที่อยู่ทุกชุดที่กรอกไว้ พร้อมชื่อจังหวัด/อำเภอ/ตำบลจริง

```sql
SELECT
    p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, p.PHONE,
    t.ADRTYPE_NAME AS ADDRESS_TYPE,
    x.A_NO, x.A_MOI, x.A_SOI, x.A_ROAD,
    sub.SUB_DISTRICT_NAME, dist.DISTRICT_NAME, prov.PROVINCE_NAME, x.A_POSTALCODE
FROM PERSON p
JOIN ADDRESS a ON a.PERSON_ID = p.PERSON_ID
CROSS APPLY (VALUES
    (1, a.A1_NO, a.A1_MOI, a.A1_SOI, a.A1_ROAD, a.A1_PROVINCE, a.A1_DISTRICT, a.A1_SUBDISTRICT, a.A1_POSTALCODE),
    (2, a.A2_NO, a.A2_MOI, a.A2_SOI, a.A2_ROAD, a.A2_PROVINCE, a.A2_DISTRICT, a.A2_SUBDISTRICT, a.A2_POSTALCODE),
    (3, a.A3_NO, a.A3_MOI, a.A3_SOI, a.A3_ROAD, a.A3_PROVINCE, a.A3_DISTRICT, a.A3_SUBDISTRICT, a.A3_POSTALCODE),
    (4, a.A4_NO, a.A4_MOI, a.A4_SOI, a.A4_ROAD, a.A4_PROVINCE, a.A4_DISTRICT, a.A4_SUBDISTRICT, a.A4_POSTALCODE)
) x(SLOT, A_NO, A_MOI, A_SOI, A_ROAD, A_PROVINCE, A_DISTRICT, A_SUBDISTRICT, A_POSTALCODE)
JOIN MT_ADDRESS_TYPE      t    ON t.ADRTYPE_ID       = x.SLOT
LEFT JOIN MT_PROVINCE     prov ON prov.PROVINCE_ID   = TRY_CAST(x.A_PROVINCE AS int)
LEFT JOIN MT_DISTRICT     dist ON dist.DISTRICT_ID   = x.A_DISTRICT
LEFT JOIN MT_SUB_DISTRICT sub  ON sub.SUB_DISTRICT_ID = x.A_SUBDISTRICT
WHERE p.PERSON_ID = 405766          -- ← ใส่ PERSON_ID ที่ต้องการ
  AND x.A_NO IS NOT NULL AND LTRIM(x.A_NO) <> ''
ORDER BY x.SLOT;
```

ทดสอบ 2026-08-26 · **3 แถว · 2.3 วินาที** — ได้ที่อยู่ตามทะเบียน / ปัจจุบัน / ติดต่อได้ ทั้งสามชุดชี้ที่เดียวกัน (ต.ดอนยายหอม อ.เมืองนครปฐม จ.นครปฐม 73000)

`A4` (ที่อยู่จัดส่งเอกสาร) กรอกไว้แค่ **93 แถวจาก 403,283** จึงมักไม่ออกมา

---

## 2 · Current address as one line

เวลาจะเอาไปพิมพ์จ่าหน้าหรือส่งต่อ

```sql
SELECT
    p.PERSON_ID,
    LTRIM(RTRIM(ISNULL(p.PREFIX, N'') + N' ' + p.FIRST_NAME + N' ' + p.LAST_NAME)) AS CUSTOMER_NAME,
    p.PHONE,
    CONCAT_WS(N' ',
        NULLIF(a.A2_NO, N''),
        CASE WHEN NULLIF(a.A2_MOI,  N'') IS NOT NULL THEN N'หมู่ ' + a.A2_MOI  END,
        CASE WHEN NULLIF(a.A2_SOI,  N'') IS NOT NULL THEN N'ซ.'   + a.A2_SOI  END,
        CASE WHEN NULLIF(a.A2_ROAD, N'') IS NOT NULL THEN N'ถ.'   + a.A2_ROAD END,
        N'ต.' + sub.SUB_DISTRICT_NAME,
        N'อ.' + dist.DISTRICT_NAME,
        N'จ.' + prov.PROVINCE_NAME,
        CAST(a.A2_POSTALCODE AS nvarchar(10))
    ) AS CUR_LINE
FROM PERSON p
JOIN ADDRESS a ON a.PERSON_ID = p.PERSON_ID
LEFT JOIN MT_PROVINCE     prov ON prov.PROVINCE_ID    = TRY_CAST(a.A2_PROVINCE AS int)
LEFT JOIN MT_DISTRICT     dist ON dist.DISTRICT_ID    = a.A2_DISTRICT
LEFT JOIN MT_SUB_DISTRICT sub  ON sub.SUB_DISTRICT_ID = a.A2_SUBDISTRICT
WHERE p.PERSON_ID = 405766;
```

ทดสอบ 2026-08-26 · **1 แถว · 0.17 วินาที**

เปลี่ยน `A2_` เป็น `A1_` ถ้าต้องการที่อยู่ตามทะเบียนบ้าน · `A_*_WORK` ถ้าต้องการที่ทำงาน

---

## 3 · Find a customer by **name**

```sql
SELECT TOP 50
    p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, p.BIRTHDAY, p.TAX_ID, p.PHONE, p.CREATE_DATE,
    (SELECT COUNT(*) FROM CONTRACT ct WHERE ct.PERSON_ID = p.PERSON_ID) AS N_CONTRACT
FROM PERSON p
WHERE p.FIRST_NAME = N'สมชาย'          -- ← ชื่อ
  AND p.LAST_NAME LIKE N'ส%'           -- ← นามสกุลขึ้นต้นด้วย (ตัดออกได้)
ORDER BY p.CREATE_DATE DESC;
```

ทดสอบ 2026-08-26 · **13 แถว · 0.52 วินาที**

**ข้อควรระวัง**

- `PERSON` **ไม่มี index บน `FIRST_NAME` / `LAST_NAME`** — คิวรี่นี้ scan ทั้งตาราง 404,749 แถว ยังเร็วอยู่เพราะตารางไม่ใหญ่ แต่ถ้าใส่ `LIKE N'%สมชาย%'` ทั้งสองฝั่งจะช้าลงมาก
- ชื่อกับนามสกุลเก็บแยกคอลัมน์ · คำนำหน้าอยู่ที่ `PREFIX` แยกอีกคอลัมน์
- ผลที่ได้มักมีคนเดียวกันหลายแถว — ต่อด้วยข้อ 4 ด้วย `TAX_ID` เพื่อรวม
- `N_CONTRACT = 0` แปลว่าแถวนั้นเป็นผู้ค้ำ / บุคคลอ้างอิง / ใบคำขอที่ไม่ผ่าน ไม่ใช่ลูกหนี้

---

## 4 · Find by **national ID** and pull every record for that person

วิธีที่ถูกต้องที่สุดในการหา "ลูกค้าคนนี้" — ใช้ index `INNO_TAX_ID`

```sql
SELECT p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, p.BIRTHDAY, p.CREATE_DATE,
       ct.CONTRACT_NUMBER, s.STA_NAME
FROM PERSON p
LEFT JOIN CONTRACT ct ON ct.PERSON_ID = p.PERSON_ID
LEFT JOIN MT_STATUS s ON s.HP_STA_ID  = ct.STATUS_ID
WHERE p.TAX_ID = '1234567890123'      -- ← เลขบัตร 13 หลัก ไม่มีขีด
ORDER BY p.CREATE_DATE DESC;
```

ทดสอบ 2026-08-26 · **2 แถว · 0.05 วินาที** — คนเดียวกันมี `PERSON_ID` 178023 (สัญญาปี 2024 ปิดแล้ว) และ 405766 (สัญญาปี 2026 กำลังผ่อน) **เกิดใหม่ทุกครั้งที่ยื่นคำขอ**

`TAX_ID` เก็บเป็น `nvarchar` **ไม่มีขีดคั่น** ยาว 13 หลัก · มีค่าครบ 404,627 จาก 404,749 แถว

---

## 5 · All contracts for a customer + latest arrears

```sql
SELECT
    ct.CONTRACT_NUMBER, s.STA_NAME AS STATUS, ct.CONTRACT_START, ct.CONTRACT_END,
    ct.INSTALL_NUM_FINAL, ct.SERIAL_NUMBER,
    od.REMAINING_OUTSTANDING, od.NUMBER_OF_OD_INSTALLMENT, od.OD_AMOUNT, od.EXTRACT_DATE
FROM CONTRACT ct
LEFT JOIN MT_STATUS s ON s.HP_STA_ID = ct.STATUS_ID
OUTER APPLY (
    SELECT TOP 1 o.REMAINING_OUTSTANDING, o.NUMBER_OF_OD_INSTALLMENT, o.OD_AMOUNT, o.EXTRACT_DATE
    FROM COLLECTION_OD o
    WHERE o.CONTRACT_ID = ct.CONTRACT_ID
    ORDER BY o.EXTRACT_DATE DESC
) od
WHERE ct.PERSON_ID = 405766
ORDER BY ct.CONTRACT_START DESC;
```

ทดสอบ 2026-08-26 · **1 แถว · 2.6 วินาที**

`COLLECTION_OD` มี 15.6 ล้านแถว (snapshot รายวัน) — `OUTER APPLY ... ORDER BY EXTRACT_DATE DESC` คือส่วนที่กินเวลา
ถ้าอยากเร็วขึ้นให้ fix วันที่แทน: `WHERE o.EXTRACT_DATE = '2026-08-26'`

---

## 6 · Instalment schedule for a contract

`CUSTOMER_CARD` = **การ์ดลูกหนี้ 1 แถวต่อ 1 งวด** ไม่ใช่ตารางลูกค้า

```sql
SELECT
    cc.INSTALL_NUM, cc.DUEDATE, cc.INSTALL_AMT, cc.PAY_PRINCIPLE, cc.PAY_INTEREST,
    cc.SUM_OUTSTAND, cc.SUM_OD_AMT, cc.PENALTY_AMT, cc.INVOICE_NUMBER
FROM CUSTOMER_CARD cc
JOIN CONTRACT ct ON ct.CONTRACT_ID = cc.CONTRACT_ID
WHERE ct.CONTRACT_NUMBER = '26291598'
ORDER BY cc.INSTALL_NUM;
```

ทดสอบ 2026-08-26 · **24 แถว (งวดที่ 1–24) · 0.09 วินาที**
งวดที่ 1 ครบกำหนด 2026-09-16 · ค่างวด 2,062.95 (เงินต้น 666.37 + ดอกเบี้ย 1,261.62)

---

## 7 · Payment history for a contract

```sql
SELECT
    r.INSTALL, r.REPAY_DATE, r.PAY_DATE, rt.REPAY_TYPE_NAME, r.PAY_NAME,
    r.PAY_AMT, r.PAY_PENALTY, r.PAY_COLLECT, r.PAY_SUM_AMT, r.RECEIPT_NUMBER, r.BANK_CODE
FROM REPAYMENT r
JOIN CONTRACT ct ON ct.CONTRACT_ID = r.CONTRACT_ID
LEFT JOIN MT_REPAY_TYPE rt ON rt.MT_REPAY_TYPE = r.REPAY_TYPE
WHERE ct.CONTRACT_NUMBER = '2000001'
ORDER BY r.PAY_DATE DESC;
```

ทดสอบ 2026-08-26 · **12 แถว · 0.06 วินาที** (สัญญา `2000001` ปิดแล้ว ผ่อน 12 งวด)

> สัญญาที่เพิ่งทำวันนี้จะได้ **0 แถว** เพราะยังไม่ถึงงวดแรก ไม่ใช่คิวรี่ผิด

`REPAY_TYPE` ทั้งฐาน: ค่างวดเช่าซื้อ 4,396,628 · ค่าติดตามทวงถาม 515,382 · เงินดาวน์ 291,263 · NULL 1,809

---

## 8 · From contract number → customer + address + device

คิวรี่ครบวงจร ไล่จาก `CONTRACT` ย้อนขึ้นไปถึง `QUOTATION` เพื่อดูว่าซื้อเครื่องอะไร

```sql
SELECT
    ct.CONTRACT_NUMBER, s.STA_NAME AS STATUS,
    p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, p.TAX_ID, p.PHONE,
    prov.PROVINCE_NAME AS CUR_PROVINCE, dist.DISTRICT_NAME AS CUR_DISTRICT,
    b.BRAND_NAME, cat.CATEGORY_NAME, ct.SERIAL_NUMBER,
    q.PROD_SUM_PRICE, q.DOWN_SUM_AMT, q.INSTALL_NUM, q.INSTALL_AMT
FROM CONTRACT ct
JOIN PERSON p                ON p.PERSON_ID      = ct.PERSON_ID
LEFT JOIN ADDRESS a          ON a.PERSON_ID      = p.PERSON_ID
LEFT JOIN MT_STATUS s        ON s.HP_STA_ID      = ct.STATUS_ID
LEFT JOIN MT_PROVINCE prov   ON prov.PROVINCE_ID = TRY_CAST(a.A2_PROVINCE AS int)
LEFT JOIN MT_DISTRICT dist   ON dist.DISTRICT_ID = a.A2_DISTRICT
LEFT JOIN APPLICATION app    ON app.APP_ID       = ct.APP_ID
LEFT JOIN QUOTATION q        ON q.QUOTATION_ID   = app.QUOTATION_ID
LEFT JOIN MT_BRAND b         ON b.BRAND_ID       = q.PRODUCT_BAND
LEFT JOIN MT_CATEGORY cat    ON cat.CATEGORY_ID  = q.PRODUCT_CATEGORY
WHERE ct.CONTRACT_NUMBER = '26291598';
```

ทดสอบ 2026-08-26 · **1 แถว · 0.19 วินาที** — Apple Smart Phone ราคา 29,900 · ดาวน์ 5,254.35 · ผ่อน 24 งวด งวดละ 1,927.99

> `q.PRODUCT_BAND` สะกดแบบนี้จริงในฐาน (ที่ควรเป็น `PRODUCT_BRAND`) และ join กับ `MT_BRAND.BRAND_ID`

---

## 9 · Find by phone number

```sql
SELECT p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, p.PHONE, p.CREATE_DATE
FROM PERSON p
WHERE p.PHONE = '0812345678';
```

ทดสอบ 2026-08-26 · **1 แถว · 0.07 วินาที** — ใช้ index `INNO_PHONE`
`PHONE` เก็บเป็นข้อความ ไม่ได้ normalize รูปแบบ (บางแถวมีขีด บางแถวไม่มี) `[อนุมาน]`

---

## 10 · Find duplicate customers (one national ID, many `PERSON_ID`)

```sql
SELECT TOP 20 TAX_ID,
       COUNT(*) AS N_PERSON_ROWS,
       COUNT(DISTINCT LTRIM(RTRIM(FIRST_NAME)) + N'|' + LTRIM(RTRIM(LAST_NAME))) AS N_NAME_SPELLING
FROM PERSON
WHERE LEN(TAX_ID) = 13
GROUP BY TAX_ID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
```

ทดสอบ 2026-08-26 · **2.5 วินาที** — เลขบัตรที่ซ้ำมากที่สุดมี **44 แถว** และมีอีกเลขที่สะกดชื่อไว้ **7 แบบ**
รวมทั้งฐาน: 404,627 แถว → 343,249 เลขบัตรไม่ซ้ำ · **1,577 เลขบัตรที่สะกดชื่อไม่ตรงกัน**

→ นี่คือหลักฐานตรงสำหรับ [[Customer Identity]] — ปัญหาลูกค้าซ้ำ **เกิดในระบบเดียวด้วย** ไม่ใช่แค่ข้ามระบบ

---

## 11 · Which instalments are paid and which are not

```sql
SELECT
    cc.INSTALL_NUM, cc.DUEDATE, cc.INSTALL_AMT, cc.RECEIPT_NUMBER,
    CASE WHEN cc.RECEIPT_NUMBER IS NOT NULL THEN N'ชำระแล้ว' ELSE N'ยังไม่ชำระ' END AS PAY_STATUS
FROM CUSTOMER_CARD cc
JOIN CONTRACT ct ON ct.CONTRACT_ID = cc.CONTRACT_ID
WHERE ct.CONTRACT_NUMBER = '26291598'
ORDER BY cc.INSTALL_NUM;
```

`RECEIPT_NUMBER IS NOT NULL` = งวดนั้นชำระแล้ว (กฎจากเอกสารทีม ตรวจแล้ว)
ทั้งฐาน: ชำระแล้ว 4,335,203 · ยังไม่ชำระ 1,481,373

**`DUEDATE` มีแค่วันที่ 1 กับ 16 เท่านั้น** ทั้ง 5.8 ล้านแถว — ดู [[K2 - Business Rules]] ข้อ 1–2

---

## 12 · What device is this contract (shortcut)

```sql
SELECT
    ct.CONTRACT_NUMBER, ct.CONTRACT_START,
    pr.MODEL_NAME, pr.MODEL_NUMBER, pr.SERIAL_NUMBER,
    b.BRAND_NAME, cat.CATEGORY_NAME,
    pr.PROD_SUM_PRICE, pr.DOWN_SUM_AMT, pr.INTEREST_FLAT
FROM CONTRACT ct
JOIN PRODUCT pr           ON pr.PRODUCT_ID   = ct.PRODUDCT_ID
LEFT JOIN MT_BRAND b      ON b.BRAND_ID      = pr.PRODUCT_BAND
LEFT JOIN MT_CATEGORY cat ON cat.CATEGORY_ID = pr.PRODUCT_CATEGORY
WHERE ct.CONTRACT_NUMBER = '26291598';
```

`CONTRACT.PRODUDCT_ID` → `PRODUCT.PRODUCT_ID` join ติด **288,197 จาก 288,207 สัญญา**
สั้นกว่าข้อ 8 ที่อ้อมผ่าน `APPLICATION` → `QUOTATION`

> `PRODUCT.SERIAL_NUMBER` มีค่า 289,184 แถว · **`CONTRACT.SERIAL_NUMBER` ว่างทั้งตาราง อย่าใช้**

---

## 13 · Guarantor for a contract

```sql
SELECT g.FIRST_NAME, g.LAST_NAME, g.RELATION_REF_DES, g.MOBILE, g.PHONE,
       g.BIRTHDAY, g.MAIN_INCOME, g.OFFICE_NAME
FROM CONTRACT ct
JOIN GUARANTOR g ON g.CONTRACT_ID = ct.CONTRACT_ID OR g.APP_ID = ct.APP_ID
WHERE ct.CONTRACT_NUMBER = '26291598';
```

**ต้อง join ทั้ง `CONTRACT_ID` และ `APP_ID`** — `GUARANTOR` 12,629 แถวมี `CONTRACT_ID` แค่ 1,121 สัญญา
ที่เหลือผูกกับใบคำขอเพราะผู้ค้ำถูกกรอกก่อนสัญญาเกิด ดู [[K2 - Business Rules]] ข้อ 6

---

## 14 · Select contracts for termination letters (Overdue 6)

```sql
DECLARE @extract date = '2026-08-03';   -- วันที่ระบบ refresh OD6 (วันที่ 3 หรือ 18)
DECLARE @due     date = '2026-08-01';   -- งวดที่ครบกำหนดของรอบนั้น (วันที่ 1 หรือ 16)

SELECT ct.CONTRACT_NUMBER,
       LTRIM(RTRIM(ISNULL(pf.Prefix_name, N'') + N' ' + p.FIRST_NAME + N' ' + p.LAST_NAME)) AS CUSTOMER_NAME,
       pr.MODEL_NAME, pr.SERIAL_NUMBER, pr.INSTALL_SUM, pr.INSTALL_NUM, pr.DUEDATE_NUM,
       o.OD_AMOUNT, o.PENALTY_AMT, o.COLLECT_AMT,
       o.OD_AMOUNT + o.PENALTY_AMT + o.COLLECT_AMT AS TOTAL_DUE
FROM COLLECTION_OD o
JOIN CONTRACT ct       ON ct.CONTRACT_ID = o.CONTRACT_ID
JOIN PERSON p          ON p.PERSON_ID    = ct.PERSON_ID
LEFT JOIN MT_PREFIX pf ON pf.Prefix_ID   = p.PREFIX
JOIN PRODUCT pr        ON pr.PRODUCT_ID  = ct.PRODUDCT_ID
WHERE o.EXTRACT_DATE = @extract
  AND o.CONTRACT_STATUS = 48            -- Overdue 6
  AND o.OD_AMOUNT > 0                   -- ตัดคนที่จ่ายครบแล้วแต่สถานะค้าง
  AND EXISTS (SELECT 1 FROM CUSTOMER_CARD k
              WHERE k.CONTRACT_ID = ct.CONTRACT_ID
                AND k.DUEDATE = @due AND k.RECEIPT_NUMBER IS NULL)
ORDER BY ct.CONTRACT_NUMBER;
```

ทดสอบ 2026-08-26 · `3 ส.ค. / 1 ส.ค.` → **236 สัญญา** · `18 ส.ค. / 16 ส.ค.` → **227 สัญญา**

> ⚠️ **ต้องใช้วันที่ 3 และ 18** ไม่ใช่ 2 และ 17 — ระบบ refresh สถานะ OD6 วันถัดจากวันที่ลูกค้าเป็น OD6 จริง
> ใช้วันที่ 2 จะได้ 0 แถว · ใช้วันที่ 17 จะได้ 1 แถว

ช่องอื่นๆ ที่ต้องใช้ในหนังสือ (ที่อยู่ · จำนวนงวดค้าง · ยอดเป็นตัวอักษร) → [[K2 - Termination Letter Mapping]]

---

## Frequently used snippets

**แปลงรหัสที่อยู่เป็นชื่อ** (ใช้กับทั้ง `ADDRESS` และ `ADDRESS_PROSPECT_CUSTOMER`)

```sql
LEFT JOIN MT_PROVINCE     prov ON prov.PROVINCE_ID    = TRY_CAST(a.A2_PROVINCE AS int)
LEFT JOIN MT_DISTRICT     dist ON dist.DISTRICT_ID    = a.A2_DISTRICT
LEFT JOIN MT_SUB_DISTRICT sub  ON sub.SUB_DISTRICT_ID = a.A2_SUBDISTRICT
```

**แปลงรหัสสถานะ**

```sql
LEFT JOIN MT_STATUS s ON s.HP_STA_ID = ct.STATUS_ID   -- ใช้ STATUS_ID ไม่ใช่ STATUS_HP
```

`CONTRACT.STATUS_HP` เป็น NULL 288,201 จาก 288,205 แถว — **คอลัมน์ตายแล้ว อย่าใช้**

**เอา snapshot หนี้ค้างวันล่าสุด**

```sql
WHERE o.EXTRACT_DATE = (SELECT MAX(EXTRACT_DATE) FROM COLLECTION_OD)
```

---

## เชื่อมกับโน้ตอื่น

[[K2 Overview]] · [[K2 - Business Rules]] · [[K2 - Termination Letter Mapping]] · [[K2 - Customer & Address]] · [[K2 - Contract & Account]] · [[K2 - Payment & Invoice]] · [[K2 - Collection & OD]] · [[K2 - Master & Setup]] · [[K2 - Table Inventory]]
