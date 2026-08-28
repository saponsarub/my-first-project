# K2 — Collection & OD

หนี้ค้างและการติดตามทวงถาม · survey 2026-08-26

> **อัปเดต 2026-08-28** — ดูไฟล์ที่ส่งทีมติดตามจริงได้ที่ [[OD6 Collection Delivery]]
> และ SQL ที่ union กับฝั่ง ITOS ที่ [[Collection Union (K2 + ITOS)]]

---

## `COLLECTION_OD` — 15,653,423 rows · 33 columns

**Snapshot รายวันของสัญญาที่มีหนี้ค้าง** — คีย์เวลาคือ `EXTRACT_DATE`

| `EXTRACT_DATE` | สัญญา |
|---|---:|
| 2026-08-26 | 120,579 |
| 2026-08-25 | 120,798 |
| 2026-08-24 | 120,937 |
| 2026-08-23 | 120,892 |
| 2026-08-22 | 120,835 |

**~120,800 สัญญาต่อวัน · 15.6M ÷ 120,800 ≈ 130 วัน** สอดคล้องกับที่ตารางถูกสร้างเมื่อ 2026-04-08

**สถานะ Overdue ถูก recompute เดือนละ 2 ครั้ง — วันที่ 3 และ 18** ไม่ใช่ทุกวัน
ยอด OD6 นิ่งที่ 6 ตลอดปลายเดือน แล้วกระโดดเป็น 337 ในวันที่ 3 ส.ค. และ 603 ในวันที่ 18 ส.ค.
→ **ถ้าจะดึงรายชื่อลูกหนี้ตามขั้น OD ต้องเลือกวัน snapshot ให้ถูก** ดู [[K2 - Termination Letter Mapping]]

> ตารางนี้เพิ่งมีมา 4 เดือน — **ประวัติหนี้ค้างก่อน เม.ย. 2026 ไม่อยู่ที่นี่** อาจอยู่ที่ `Temp_History_OD` (5,067,003 แถว) แต่ยังไม่ได้ยืนยัน

**ระวังตอน query** — ถ้าไม่ใส่ `WHERE EXTRACT_DATE = ...` จะได้สัญญาเดียวกันซ้ำ 130 ครั้ง
```sql
WHERE o.EXTRACT_DATE = (SELECT MAX(EXTRACT_DATE) FROM COLLECTION_OD)
```

### Columns

| กลุ่ม | คอลัมน์ |
|---|---|
| คีย์ | `EXTRACT_DATE`, `CONTRACT_ID`, `CONTRACT_NUMBER`, `UPDATE_DATE` |
| สถานะ | `CONTRACT_STATUS`, `CONTRACT_STATUS_DESC`, `PRODUDCT_ID`*, `PRODUCT_TYPE` |
| ยอดตามสัญญา | `TOTAL_OUTSTANDING`, `TOTAL_PRINCIPLE`*, `TOTAL_INTEREST`, `TOTAL_VAT`, `NUMBER_OF_PERIOD`, `INSTALLMENT_PER_PERIOD` |
| ชำระแล้ว | `PAID_TOTAL_OUTSTANDING`, `PAID_TOTAL_PRINCIPLE`, `PAID_TOTAL_INTEREST`, `PAID_TOTAL_VAT`, `PAID_NUMBER_OF_PERIOD` |
| คงเหลือ | `REMAINING_OUTSTANDING`, `REMAINING_PRINCIPLE`, `REMAINING_INTEREST`, `REMAINING_VAT`, `REMAINING_PERIOD` |
| งวด | `PERIOD_DUE_DATE`, `LAST_REPAY_DATE`, `INVOICE_NUMBER`, `INVOICE_DATE` |
| ค้าง | `NUMBER_OF_OD_INSTALLMENT`, `OD_AMOUNT`, `PENALTY_AMT`, `COLLECT_AMT`, `TOTAL_FOLLOW_UP_AMOUNT` |

\* typo เดิม `PRODUDCT_ID` และ `PRINCIPLE`

`NUMBER_OF_OD_INSTALLMENT` เป็น `nvarchar` ไม่ใช่ `int` — ต้อง cast ก่อนคำนวณหรือเรียงลำดับ

### Customer segment — `PRODUCT_TYPE` (snapshot 2026-08-26)

| | สัญญา |
|---|---:|
| **Student** | **73,209** |
| Personal | 47,370 |

**นักศึกษาเป็น 60.7% ของสัญญาที่มีหนี้ค้าง** — ยืนยันว่า UFund เป็นสินเชื่อเครื่อง IT สำหรับนักศึกษาเป็นหลัก
`COLLECTION_OD.PRODUCT_TYPE` แบ่งกลุ่มได้ครบกว่า `CONTRACT.PROJECT_TYPE` ที่ NULL 187,410 แถว

---

## `COLLECTION_OD_ASSIGNMENT` — 98,477 rows

การมอบหมายสัญญาให้ collector — **ตารางเดียวของ K2 ที่ vault เคยยืนยันไว้ก่อน survey นี้**

`ASSIGN_TO_TEAM` · `EMP_CODE` · `EMP_NAME` และคอลัมน์ยอดค้างเหมือน `COLLECTION_OD`

**คอลัมน์ที่อยู่ในตารางนี้เป็นข้อความก้อนเดียว 3 ช่อง**
`CUSTOMER_ADDRESS_REGISTER` · `CUSTOMER_ADDRESS_CURRENT` · `CUSTOMER_ADDRESS_DELIVERY`

> เดิม vault สรุปว่า "K2 เก็บที่อยู่เป็น 3 คอลัมน์ ต่างจาก ITOS ที่แยกเป็นตาราง"
> **survey นี้พบว่านั่นเป็นแค่รูปแบบใน extract ของ collection** — ต้นทางจริง `ADDRESS` แตกที่อยู่เป็นฟิลด์ย่อยครบ (บ้านเลขที่ หมู่ ซอย ถนน ตำบล อำเภอ จังหวัด รหัสไปรษณีย์ พิกัด) และมี 4 ชุด + ที่ทำงาน
> **ถ้าจะทำ address standardization ให้ดึงจาก `ADDRESS` ไม่ใช่จากตารางนี้** ดู [[K2 - Customer & Address]]

เช่นเดียวกัน คำสรุปเดิมว่า "K2 ไม่มี `CREATE_DATE` จึงทำ incremental ไม่ได้" มาจากดูตารางนี้ตารางเดียว — ตารางต้นทางมี timestamp ครบ ดู [[K2 Overview]] · [[K2 - Data Dictionary]]

---

## `CONTACT_DEBT_COLLECTION` — 3,458,409 rows · 14 columns

**บันทึกการติดต่อทวงถามทีละครั้ง** สร้าง 2023-07-27

`ID` · `CONTRACT_ID` · `APP_ID` · `CONTARCT_NUMBER`* · `CONTACT_NUMBER` · `RESULT_COLLECTION` · `REMARK_1` · `REMARK_2` · `DUE_DATE` · `PAYMENT_AMT` · `CreateBy` · `CreateByName` · `CreateByEmail` · `CreateDate`

\* สะกดผิด (`CONTARCT`)

3.46M ครั้ง ต่อสัญญาที่มีหนี้ค้าง ~120k = **เฉลี่ย 29 ครั้งต่อสัญญา** `[อนุมาน]`

**มี `CreateByEmail` — อีเมลพนักงานอยู่ในตาราง** ต้องนับเป็น PII ของพนักงานตอนทำ ingestion `[อนุมาน]`
`REMARK_1` / `REMARK_2` เป็นข้อความอิสระที่ collector พิมพ์เอง — **มีโอกาสสูงที่จะมี PII ปนอยู่ในข้อความอิสระ** ควรกันไว้ก่อน `[อนุมาน]`

---

## Penalty and collection fees

**ค่าปรับ 100 บาท/งวดที่ค้าง** คิดตอน **23:00 ของวันครบกำหนด** · **ค่าติดตามเกิดเมื่อค้างเกิน 7 วัน** และไต่ขั้นตามตาราง แยก 2 กรณีตามว่าค่างวดถึง 1,000 บาทไหม

อัตราต่อหน่วยเก็บที่ตาราง **`FeeControl`** (3 แถว · มี `EffectiveDate`/`ExpiryDate`) ส่วนตรรกะไต่ขั้นอยู่ในแอป
ประวัติการคิด/ยกเว้นอยู่ที่ `LOG_PENALTY_COLLECT` (246,980 แถว)

**`TOTAL_FOLLOW_UP_AMOUNT` = (งวดที่ค้าง + 1) × ค่างวด + ค่าปรับ + ค่าติดตาม** — รวมงวดที่กำลังจะถึงเข้าไปด้วย
→ **อย่าใช้เป็นยอดค้าง ณ วันนี้** ตารางเต็มและผลตรวจ → [[K2 - Fee Policy]]

---

## Collection master tables

### `MT_COLLECTION` — 11 collection outcomes

| | |
|---|---|
| 1 | ติดต่อลูกค้าสำเร็จ |
| 2 | ติดต่อลูกหนี้ไม่ได้ |
| 3 | ยินยอมพร้อมนัดหมายชำระหนี้ |
| 4 | ไม่ชำระหนี้ขอคืนเครื่องพร้อมนัดหมาย |
| 5 | ลูกหนี้ขอเจรจาปรับปรุงโครงสร้างหนี้ |

**"ขอคืนเครื่อง" เป็นทางออกมาตรฐาน** — เพราะหลักประกันคือตัวเครื่องเอง

### `MT_DebtContactStatus` — 15 statuses · created 2023-06-29

| | | กลุ่ม |
|---|---|---|
| 1 | นัดชำระ | 1 |
| 8 | ชำระแล้ว (Already Paid) | 1 |
| 2 | ติดต่อไม่ได้ | 2 |
| 3 | ติดต่อได้แต่ยังไม่นัดชำระ (Not Promise to pay) | 2 |
| 4 | ผิดนัดชำระ (Broken Promise to pay) | 2 |
| 5 | ไม่รับสาย (No Answer) | 2 |
| 6 | ฝากเรื่องให้ติดต่อกลับ (Leave Message) | 2 |
| 7 | ชำระขาด (Partial Payment) | 2 |
| 9 | ติดต่อไม่ได้ทุกกรณี (Skip) | 2 |
| 10 | ติดต่อไม่ได้ทั้งลูกค้าและผู้ค้ำ (CM+Emergency Call) | 2 |
| 11 | หัวหน้างานตรวจสอบ (Sup. Review) | 2 |
| 12 | ลูกค้าฟอร์ด (Fraud customer) | 2 |
| 13 | **ยึดเครื่อง (Repo)** | 2 |
| 14 | ขายขาดทุน (Loss on Sale) | 2 |
| 15 | งานกฎหมาย (Legal Process) | 2 |

`StatusGroup` = 1 คือจบดี · 2 คือยังมีปัญหา `[อนุมาน]`

`MT_COLLECTION_COLLECTOR` มี 100 แถว = **ทีมทวงถามประมาณ 100 คน** พร้อม**คะแนนผลงาน**

`EMP_Code` · `EMP_Name` · `Team` · **`OA_Score`** · **`OA_Rank`** · **`Percent_OA_Assign`** · `CURRENT_DUE_DATE` · `OA_Performance_Date`

**ระบบจัดสรรงานทวงหนี้ตามคะแนน** — คนคะแนนดีได้สัดส่วนงานมากกว่า `[อนุมาน]`
เป็นข้อมูลผลงานพนักงาน ไม่ใช่ข้อมูลลูกค้า → สิทธิ์เข้าถึงต้องคิดแยก ดู [[K2 - Business Rules]] ข้อ 8

---

## Contact-channel signals

| ตาราง | แถว | หมายเหตุ |
|---|---:|---|
| `LOGGED_EMAIL_LISTS` | 2,418,448 | หยุดอัปเดต 2024-02-23 |
| `LOG_SEND_SMS` | 601,475 | ยังใช้อยู่ (2025-07-02) |
| `TTP_SMS_RESULT` | 266,744 | ผลส่ง SMS |
| `LOGS_SEND_INET` | 1,193,966 | สร้าง 2025-09 · อัปเดต 2026-02 |
| `MT_SMS` / `MT_SMS_OTP` | 9 / 6 | เทมเพลตข้อความ |

**การแจ้งเตือนหนี้ใช้ SMS เป็นหลัก อีเมลหยุดไปตั้งแต่ต้นปี 2024** `[อนุมาน]`

---

## Relationship with ITOS

ITOS (`ILOAN_COLLECTION`) เป็นระบบติดตามหนี้อีกตัวที่ทำงานคู่กัน — `S_COLLECTRESP` 166,189 · `T_NOTE` 277,694 · `T_JOBTRANS` 15,684

**สองระบบมีงานทวงถามซ้อนกัน** และยังไม่มีหลักฐานว่าสัญญาชุดไหนอยู่ระบบไหน หรือซ้ำกันไหม — คำถามนี้ยังเปิดอยู่ ดู [[K2 + ITOS Integration]]

**ตัวเลขที่เทียบได้ตอนนี้:** K2 มีสัญญา 288,205 (ค้างชำระ ~120,800/วัน) · ITOS มี `S_CONTRACT` 165,723
รวมกันแล้วจะซ้ำหรือไม่ ยังตอบไม่ได้ **ต้องเทียบด้วยเลขบัตร ไม่ใช่เลขสัญญา** `[อนุมาน]`

---

## เชื่อมกับโน้ตอื่น

[[K2 Overview]] · [[K2 - Query Cookbook]] · [[K2 - Business Rules]] · [[K2 - Fee Policy]] · [[K2 - OD6 Selection Logic]] · [[K2 - Termination Letter Mapping]] · [[K2 - Contract & Account]] · [[K2 - Payment & Invoice]] · [[ITOS Overview]] · [[K2 + ITOS Integration]]
