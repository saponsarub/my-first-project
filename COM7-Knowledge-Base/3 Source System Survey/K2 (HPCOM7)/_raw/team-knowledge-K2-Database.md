# K2 Database

## Frequently Used Tables & Fields

### CONTRACT

`HPCOM7.dbo.CONTRACT`

* `CONTRACT_ID`
* `CONTRACT_NUMBER`
* `CONTRACT_START`
* `PRODUDCT_ID`
* `CUSTOMER_NAME`
* `STATUS_ID`
* `PERSON_ID`
* `UPDATE_DATE`

### PRODUCT

`HPCOM7.dbo.PRODUCT`

* `PRODUCT_ID`
* `MODEL_NAME`
* `SERIAL_NUMBER`
* `Balloon_Type`

### CUSTOMER_CARD

`HPCOM7.dbo.CUSTOMER_CARD`

* `CONTRACT_ID`
* `CONTRACT_NUMBER`
* `INSTALL_NUM`
* `INSTALL_AMT`
* `PAY_PRINCIPLE`
* `PAY_INTEREST`
* `PAY_INSTALL_VAT`
* `DUEDATE`
* `RECEIPT_NUMBER`

### INVOICE

`HPCOM7.dbo.INVOICE`

* `CONTRACT_ID`
* `INVOICE_NUMBER`
* `INVOICE_DATE`
* `DUE_DATE`
* `INSTALL_OD_SUM`
* `SUM_OD_AMT`
* `PENALTY_AMT`
* `COLLECT_AMT`

### REPAYMENT

`HPCOM7.dbo.REPAYMENT`

* `CONTRACT_NUMBER`
* `REPAY_DATE`
* `PAY_DATE`
* `PAY_SUM_AMT`
* `STATUS_ID`
* `REPAY_TYPE`

### PERSON

`HPCOM7.dbo.PERSON`

* `PERSON_ID`
* `BIRTHDAY`
* `PHONE`
* `OCCUPATION_CODE`

### ADDRESS

`HPCOM7.dbo.ADDRESS`

#### A1 — ทะเบียนบ้าน

* `PERSON_ID`
* `A1_NO`
* `A1_MOI`
* `A1_VILLAGE`
* `A1_BUILDING`
* `A1_FLOOR`
* `A1_ROOM_NO`
* `A1_SOI`
* `A1_ROAD`
* `A1_PROVINCE`
* `A1_DISTRICT`
* `A1_SUBDISTRICT`
* `A1_POSTALCODE`

#### A2 — ที่อยู่ปัจจุบัน

* `A2_NO`
* `A2_MOI`
* `A2_VILLAGE`
* `A2_BUILDING`
* `A2_FLOOR`
* `A2_ROOM_NO`
* `A2_SOI`
* `A2_ROAD`
* `A2_PROVINCE`
* `A2_DISTRICT`
* `A2_SUBDISTRICT`
* `A2_POSTALCODE`

#### A3 — ที่อยู่จัดส่ง

* `A3_NO`
* `A3_MOI`
* `A3_VILLAGE`
* `A3_BUILDING`
* `A3_FLOOR`
* `A3_ROOM_NO`
* `A3_SOI`
* `A3_ROAD`
* `A3_PROVINCE`
* `A3_DISTRICT`
* `A3_SUBDISTRICT`
* `A3_POSTALCODE`

### GUARANTOR

`HPCOM7.dbo.GUARANTOR`

**ความหมาย:** ผู้ค้ำประกัน

* `CONTRACT_ID`
* `FIRST_NAME`
* `LAST_NAME`
* `RELATION_REF_DES`
* `MOBILE`

### MT_STATUS

`HPCOM7.dbo.MT_STATUS`

* `HP_STA_ID`
* `STA_NAME`

### MT_OCCUPATION

`HPCOM7.dbo.MT_OCCUPATION`

* `Ocpt_ID`
* `Ocpt_name`

### MT_COLLECTION_COLLECTOR

`HPCOM7.dbo.MT_COLLECTION_COLLECTOR`

**ความหมาย:** พนักงานทวงหนี้ในบริษัท

* `CURRENT_DUE_DATE`
* `EMP_Code`
* `EMP_Name`
* `Team`
* `OA_Score`
* `OA_Rank`
* `Percent_OA_Assign`
* `OA_Performance_Date`

### COLLECTION_OD

`HPCOM7.dbo.COLLECTION_OD`

* `EXTRACT_DATE`

---

# Business Rules / Known Conditions

## Address

```text
A1 = ทะเบียนบ้าน
A2 = ที่อยู่ปัจจุบัน
A3 = ที่อยู่จัดส่ง
```

## Overdue (OD)

```text
OD = Overdue
ระดับสูงสุด = OD6

OD1
OD2
OD3
OD4
OD5
OD6
```

## Payment Date

```text
วันชำระเงิน = วันที่ 1 และ 16
```

## RECEIPT_NUMBER

ใน `CUSTOMER_CARD`:

```text
RECEIPT_NUMBER IS NOT NULL
```

= งวดนั้นมีการชำระเงินแล้ว

```text
RECEIPT_NUMBER IS NULL
```

= งวดนั้นยังไม่มีการชำระเงิน

---

# Known Relationships

```text
CONTRACT.PRODUDCT_ID
    → PRODUCT.PRODUCT_ID

CONTRACT.CONTRACT_ID
    → INVOICE.CONTRACT_ID
    → CUSTOMER_CARD.CONTRACT_ID
    → GUARANTOR.CONTRACT_ID

CONTRACT.CONTRACT_NUMBER
    → CUSTOMER_CARD.CONTRACT_NUMBER
    → REPAYMENT.CONTRACT_NUMBER

CONTRACT.PERSON_ID
    → PERSON.PERSON_ID
    → ADDRESS.PERSON_ID

PERSON.OCCUPATION_CODE
    → MT_OCCUPATION.Ocpt_ID

CONTRACT.STATUS_ID
    → MT_STATUS.HP_STA_ID
```

# Important Notes for AI

* Database นี้ใช้ `HPCOM7`
* `GUARANTOR` = ผู้ค้ำประกัน
* `MT_COLLECTION_COLLECTOR` = พนักงานทวงหนี้ในบริษัท
* `A1` = ทะเบียนบ้าน
* `A2` = ที่อยู่ปัจจุบัน
* `A3` = ที่อยู่จัดส่ง
* `OD` สูงสุดคือ `OD6`
* วันชำระเงินคือวันที่ `1` และ `16`
* `RECEIPT_NUMBER IS NOT NULL` = งวดนั้นมีการชำระเงินแล้ว
* หากข้อมูลใดไม่ได้ระบุในไฟล์นี้ ให้ถือว่ายังไม่มีข้อมูลยืนยัน และไม่ควรสมมติความหมายเพิ่มเติม
