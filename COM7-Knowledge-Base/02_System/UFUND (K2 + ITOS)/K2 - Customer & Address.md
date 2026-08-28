# K2 — Customer & Address

ลูกค้าและที่อยู่ในฐาน `HPCOM7` · survey 2026-08-26

---

## `PERSON` — people table · 404,749 rows · 190 columns

**นี่ไม่ใช่ทะเบียนลูกค้า** เป็น **1 แถวต่อ 1 บทบาทในใบคำขอ 1 ใบ** — `APP_ID` ไม่ซ้ำเลยทั้ง 404,749 แถว
ลูกค้าคนเดิมยื่นคำขอใหม่ = ได้ `PERSON_ID` ใหม่ ข้อมูลไม่ถูก merge

| | |
|---|---:|
| แถวทั้งหมด | 404,749 |
| **มีสัญญาจริง** | **288,195** |
| ไม่มีสัญญา (ผู้ค้ำ / บุคคลอ้างอิง / คำขอไม่ผ่าน) | 116,554 |
| `FLAG_GUARANTOR = 1` | 3,217 |
| `FLAG_GUARANTOR` เป็น NULL | 401,519 |

> `FLAG_GUARANTOR` ใช้งานแทบไม่ได้ — NULL 99.2% ผู้ค้ำจริงต้องดูที่ `CHECKER_GUARANTOR` (361,169 แถว) แทน `[อนุมาน]`

### Identity keys

| คอลัมน์ | สิ่งที่เก็บจริง |
|---|---|
| `PERSON_ID` | PK · `PK_HP_PERSON` clustered |
| **`TAX_ID`** | **เลขบัตรประชาชน 13 หลัก** `nvarchar` ไม่มีขีด · มีค่า 404,627 แถว · index `INNO_TAX_ID` |
| `CARD_CODE` | **ไม่ใช่เลขบัตร** — เป็นรหัสประเภทบัตร มีแค่ค่า `1` (328,361) และ `3` (51) · NULL 76,335 |
| `CIF_PERSON_ID` | ตั้งใจให้เป็น CIF แต่ **ว่าง 404,645 จาก 404,749** |
| `CUSTOMER_TYPE` | ว่าง 404,644 จาก 404,749 |
| `PHONE` | index `INNO_PHONE` · ไม่ normalize รูปแบบ `[อนุมาน]` |
| `FIRST_NAME` / `LAST_NAME` | **ไม่มี index** — ค้นด้วยชื่อ = scan ทั้งตาราง |

**ตอบคำถามเดิมของ vault ได้แล้ว:** *"K2 มีเลขบัตรประชาชนที่ไหนนอก collection extract ไหม"* → **มี อยู่ที่ `PERSON.TAX_ID` และมีเกือบครบทุกแถว**

### Duplicate customers, now quantified

| | |
|---|---:|
| แถวที่มีเลขบัตร 13 หลัก | 404,627 |
| **เลขบัตรที่ไม่ซ้ำ** | **343,249** |
| แถวส่วนเกิน (คนเดิมยื่นซ้ำ) | 61,378 |
| เลขบัตรที่ **สะกดชื่อไม่ตรงกัน** ระหว่างแถว | **1,577** |
| เลขบัตรที่ซ้ำมากที่สุด | 44 แถว |
| จำนวนวิธีสะกดชื่อมากที่สุดของคนเดียว | 7 แบบ |

→ **ลูกค้าซ้ำไม่ใช่แค่ปัญหาข้ามระบบ เกิดในระบบเดียวด้วย** และการ dedupe ด้วยชื่อจะพลาดกับ 1,577 เคสนี้ ต้องใช้ `TAX_ID` เป็นหลัก
เชื่อมกับ [[Customer Identity]] · วิธีคิวรี่อยู่ที่ [[K2 - Query Cookbook]] ข้อ 10

### Sensitive data inside `PERSON`

**ตัวตน** — ชื่อไทย + อังกฤษ (`PREFIX_ENG`, `FIRST_NAME_ENG`, `LAST_NAME_ENG`), `BIRTHDAY`, `SEX`, `NATIONALITY_CODE`, `MARITAL_STATUS`, `NUMBER_CHILDREN`, วันออก/หมดอายุบัตร

**การเงิน** — `MAIN_INCOME`, `OTHER_INCOME`, `EXPENSE`, `AMOUNT_INCOME`, `SALARY_RANGE_MIN/MAX`, `FINANCIAL_AMOUNT`, `CREDIT_CARD_LIMIT`, `INSTALLMENT_HOME`, `INSTALLMENT_CAR`, `INSTALLMENT_ETC`, `INSTITUTION_BANK_AMOUNT`

**การศึกษา** — `STUDENT_ID`, `UNIVERSITY_NAME`, `CAMPUS_NAME`, `FACULTY_NAME`, `U_LEVEL`, `LOAN_KYS` → ยืนยันว่ากลุ่มลูกค้าหลักเป็นนักศึกษา (`MT_FACULTY` 39,475 แถว · `MT_UNIVERSITY_NAME` 1,149)

**บุคคลที่สาม** — คู่สมรสชุดเต็ม (`SPOUSE_*` รวมรายได้และที่ทำงาน) และ **บุคคลอ้างอิง 2 ชุด** (`REF_*` และ `REF_*_2`) แต่ละชุดมีเลขบัตร วันเกิด รายได้ เบอร์ อีเมล LINE Facebook
> คนเหล่านี้ไม่ได้ทำสัญญากับ COM7 — ประเด็นเดียวกับที่ ITOS เจอ ดู [[ITOS Overview]]

**สุขภาพ** — `Disease_ID`, `Narcotic_ID` (`MT_DISEASE` 9 แถว) → **ข้อมูลอ่อนไหวชั้นสูงตาม PDPA มาตรา 26** ต้องแยกจัดการ ไม่ใช่ PII ธรรมดา `[อนุมาน]`

**ไฟล์แนบ base64 ในฐานข้อมูล** — `CARD_CODE_FILE`, `FACE_PERSON`, `CONSENT_FILE`, `STATEMENT_FILE`, `BANK_STATE_FILE` (มีถึง FOURTH), `SLIP_FILE`, `DS_PDPA` และคู่ `*_FILE_PATH` อีกชุด
→ **สำเนาบัตรประชาชน รูปหน้า และ statement ธนาคาร อาจเก็บเป็น base64 ในคอลัมน์** ต้องกันไม่ให้หลุดเข้า data lake โดยไม่ตั้งใจ `[อนุมาน]`

**PDPA** — `CONFIRM_PDPA`, `DS_PDPA`, `CONSENT_FILE`, `CONSENT_FILE_PATH` · `QUOTATION` มี `CONSENT_DATE` และ `CONSENT_TIME` (เก็บเป็น `varchar` ทั้งคู่)
→ **K2 มีร่องรอย consent ในฐาน** ซึ่งเป็นมากกว่าที่ [[Consent & PDPA]] บันทึกไว้ตอนนี้ ควรตรวจว่า `CONFIRM_PDPA` มีค่าจริงกี่แถวก่อนสรุป

**`PASSWORD`** — มีคอลัมน์ชื่อนี้ใน `PERSON` ยังไม่ได้ตรวจว่า hash หรือ plaintext

---

## `ADDRESS` — 403,283 rows · 101 columns

**1 แถวต่อ 1 `PERSON_ID`** (403,279 person ไม่ซ้ำ) — join แล้วได้ 403,278 แถว
ต่างจาก ITOS ที่ `S_CUSTADDR` เป็น one-to-many หลายแถวต่อคน → **สองระบบเก็บที่อยู่คนละรูปแบบ รวมกันไม่ตรงไปตรงมา**

### Five address blocks in one row

| ชุด | คอลัมน์ | ความหมาย (จาก `MT_ADDRESS_TYPE`) | กรอกไว้ |
|---|---|---|---:|
| A1 | `A1_*` (`A1_MASTER = 1`) | ที่อยู่ตามทะเบียน | 403,181 |
| A2 | `A2_*` (`A2_MASTER = 2`) | ที่อยู่ปัจจุบัน | 403,174 |
| A3 | `A3_*` | ที่อยู่ติดต่อได้ | 403,154 |
| A4 | `A4_*` | ที่อยู่จัดส่งเอกสาร | **93** |
| WORK | `A_*_WORK` | ที่ทำงาน | 67,533 |

`A*_MASTER` เก็บเลขชุดตัวเอง (1, 2, …) ตรงกับ `MT_ADDRESS_TYPE.ADRTYPE_ID` — ยืนยันการ map แล้ว

> ⚠️ **เอกสารความรู้ของทีมเรียก A3 ว่า "ที่อยู่จัดส่ง" ซึ่งไม่ตรงกับ master** ที่บอกว่า A3 = ติดต่อได้ · A4 = จัดส่งเอกสาร
> แต่ทีมพูดถูกในเชิงการใช้งาน เพราะ **A4 กรอกไว้แค่ 93 แถว** เวลาส่งของจริงจึงต้องใช้ A3
> รายละเอียดและข้อสรุปที่ใช้ได้ → [[K2 - Business Rules]] ข้อ 4

**A1 เท่ากับ A2 ใน 252,194 จาก 403,285 แถว (62.5%)** — คนส่วนใหญ่อยู่ตามทะเบียนบ้าน
**A2 เท่ากับ A3 ใน 360,962 จาก 403,297 แถว (89.5%)** — A3 แทบเป็นสำเนา A2

### Columns in each block

`_NO` `_MOI` `_VILLAGE` `_BUILDING` `_FLOOR` `_ROOM_NO` `_SOI` `_ROAD` `_PROVINCE` `_DISTRICT` `_SUBDISTRICT` `_POSTALCODE` `_OWNER_TYPE` `_LIVEING_TIME` `_PHONE` `_LATITUDE` `_LONGITUDE` `_MASTER` `_COPY`

**ที่อยู่แตกเป็นฟิลด์ย่อยครบ** — ต่างจาก `COLLECTION_OD_ASSIGNMENT` ที่ยัดที่อยู่ทั้งก้อนไว้ 3 คอลัมน์ข้อความ
→ ถ้าจะทำ address standardization ให้ดึงจาก `ADDRESS` ไม่ใช่จาก extract ของ collection `[อนุมาน]`

**มีพิกัด** `_LATITUDE` / `_LONGITUDE` ทุกชุด · `PERSON.ADR_MAP` ด้วย

### Trap: `_PROVINCE` is text holding a numeric code

```
A1_PROVINCE     nvarchar   เก็บ '10', '30', '34' = PROVINCE_ID
A1_DISTRICT     int        = DISTRICT_ID
A1_SUBDISTRICT  int        = SUB_DISTRICT_ID
A1_POSTALCODE   int
```

403,173 จาก 403,285 แถวเป็นตัวเลขล้วน — ต้อง `TRY_CAST(A1_PROVINCE AS int)` ก่อน join `MT_PROVINCE`
ชื่อคอลัมน์บอกว่า "PROVINCE" แต่ข้างในเป็นรหัส **ถ้าเผลอเอาไปแสดงตรงๆ จะได้เลขไม่ใช่ชื่อจังหวัด**

### Index

`PK_Address` (`ADDRESS_ID`) · `INNO_PERSON_ID` · `INNO_QUOTATION_ID` · `INNO_A2_PROVINCE` · `INNO_A2_DISTRICT` · `INNO_A2_SUBDISTRICT` · `INNO_A_PROVINCE_WORK` · `INNO_A_DISTRICT_WORK` · `INNO_A_SUBDISTRICT_WORK`

**มี index เฉพาะ A2 (ที่อยู่ปัจจุบัน) กับที่ทำงาน ไม่มีบน A1/A3/A4** → ระบบใช้ A2 เป็นหลักในการค้น `[อนุมาน]`

---

## `PROSPECT_CUSTOMER` — prospects · 800,283 rows · 132 columns

| | |
|---|---:|
| แถว | 800,283 |
| `PST_CUST_ID` ไม่ซ้ำ | 800,283 |
| `QUOTATION_ID` ไม่ซ้ำ | 800,276 |
| **เลขบัตรไม่ซ้ำ** | **560,893** |
| ช่วงเวลา | 2020-07-03 → 2026-08-26 |

โครงสร้างคล้าย `PERSON` แต่เก็บตอนที่ยังเป็นใบเสนอราคา ยังไม่แปลงเป็นใบคำขอ
คู่กับ `ADDRESS_PROSPECT_CUSTOMER` (987,518 แถว · 80 คอลัมน์ · คีย์ `ADD_CUST_ID`, `QUOTATION_ID`, `PST_CUST_ID`) ที่ใช้ pattern `A1_*` แบบเดียวกัน

**นี่คือแหล่งข้อมูลลูกค้าที่ใหญ่กว่า `PERSON` เกือบเท่าตัว** — 560,893 คนที่เคยสนใจ vs 343,249 คนที่ยื่นคำขอจริง
สำหรับงาน Customer 360 กลุ่มนี้คือ prospect ที่ยังไม่เคยถูกนับ `[อนุมาน]` แต่ **ฐาน consent ของคนกลุ่มนี้ต่างจากลูกค้าที่ทำสัญญา ต้องให้ legal ตอบก่อนเอาไปใช้**

---

## Summary for the SSOT work

| ประเด็น | K2 | ITOS (เทียบ) |
|---|---|---|
| ทะเบียนลูกค้าที่ไม่ซ้ำ | **ไม่มี** — `PERSON` เป็นรายใบคำขอ | `S_CUSTOMER` 165,722 แถว |
| เลขบัตร | `PERSON.TAX_ID` มีเกือบครบ | `CUST_CARDNO` |
| ที่อยู่ | 1 แถว 5 ชุดในคอลัมน์ | `S_CUSTADDR` หลายแถวต่อคน |
| ชื่ออังกฤษ | มี (`*_ENG`) | มี (`CUST_*EN`) |
| รายได้ | มี | มี |
| คู่สมรส | มี | มี (`CUST_SP_*`) |
| **รหัส ธปท.** | **ไม่พบ** | มี 3 คอลัมน์ |
| CIF | มีคอลัมน์แต่ว่าง | ไม่พบ |

**K2 ไม่มีรหัส ธปท. แบบที่ ITOS มี** — ถ้า TFF ต้องรายงาน ธปท. จากทั้งสองระบบ ต้องถามว่าฝั่ง K2 รายงานยังไง `[อนุมาน]`

---

## เชื่อมกับโน้ตอื่น

[[K2 Overview]] · [[K2 - Data Dictionary]] · [[K2 - Query Cookbook]] · [[K2 - Business Rules]] · [[K2 - Contract & Account]] · [[K2 - Master & Setup]] · [[Customer Identity]] · [[Consent & PDPA]]
