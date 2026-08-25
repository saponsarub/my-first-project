# Other Systems

ระบบที่ยังรู้น้อย — D365 · SAP B1 · iCare · Tech Trade · Azure Synapse

---

# D365

Survey ยังไม่เริ่ม · MIS-ERP

## ที่รู้

**บทบาทฝั่ง GI:** บันทึกประชุมเรียกว่า **"D365 (GI เก่า)"** และ GI Core ยิงข้อมูลไป D365 ผ่าน RPA

**ที่พบใน SQL:** `D365FO_DATALAKE.dbo.*` — ตารางที่เห็น `inventsum`, `inventtrans`, `inventdim`, `purchline`, `vendtable`

ไฟล์ที่อ้างถึง: `GI/FO_All GI Onhand.sql`, `GI/FullSalesReportFinal.sql`, `GI/GI_PhysicalCost.sql`, `GI/SalesReportTuning.sql`, `PODetial.sql`, `PODetial_Com7.sql`, `VendorCom7Final.sql`, `DRPH/LSStatement.sql`

prefix `FO_` ในชื่อไฟล์ และชื่อฐาน `D365FO_DATALAKE` บ่งชี้ว่าเป็น **Dynamics 365 Finance & Operations** `[อนุมาน]`

query ที่พบเน้น inventory, purchasing, vendor, stock costing

## ความสัมพันธ์กับ Synapse

Server `syndpdev001` ปรากฏใน query ข้างเคียง และหลาย query join ข้ามทั้ง `syndpdev001` กับ `D365FO_DATALAKE`

Timeline Pilot item 1: **"MS Synapse จาก D365 to AWS directly"** ยืนยันว่ามีเส้นทาง D365 → Synapse

## ที่ไม่รู้

ใช้ทำอะไรโดยรวม · BU ไหนใช้บ้าง · ยัง active หรือ legacy แล้ว (เรียกว่า "GI เก่า" แต่ `D365FO_DATALAKE` ยังถูก query อยู่) · ข้อมูลอยู่ที่ไหนจริง · เชื่อมกับ Azure/ADLS ไหม · **มีข้อมูลลูกค้าไหม** (query ที่พบเป็น inventory/vendor/purchasing ล้วน)

---

# SAP B1

Survey ยังไม่เริ่ม · K.Benz

## ที่รู้

Timeline ระบุเป็น **main system 1.1.7** — แค่นั้น

การถูกจัดเป็น Main System (1.1) แทนที่จะเป็น Other Legacy (1.2) บ่งชี้ว่าน่าจะยังใช้งานอยู่ `[อนุมาน]`

## ที่ไม่รู้

**เกือบทั้งหมด** — BU ไหนใช้ · มีข้อมูลลูกค้าไหม · product/sales/financial data · อยู่ on-prem หรือ cloud · integration กับระบบอื่น · **ความสัมพันธ์กับ D365**

COM7 ดูเหมือนมี ERP สองระบบ (D365 F&O และ SAP B1) ซึ่งกระทบขอบเขต Finance & Accounting ของ Data Framework ที่ต้องการงบการเงินรวม — 2 ERP อาจแปลว่าต้อง reconcile chart of accounts สองชุด `[อนุมาน]`

---

# iCare

Survey ยังไม่เริ่ม · P.Pui · แยกเป็น 2 track

| Ref | Track |
|---|---|
| 1.1.6.1 | Insurance |
| 1.1.6.2 | Mobile Service |

## ข้อมูลสุขภาพ — ไม่เกี่ยว

เคยมีข้อกังวลว่า iCare Insurance อาจมีข้อมูลสุขภาพซึ่งเป็นข้อมูลอ่อนไหวตาม PDPA ม.26

**ได้รับการชี้แจงแล้วว่าเป็นประกันอุปกรณ์ ไม่ใช่ประกันคน** → ข้อกังวลเรื่อง ม.26 ไม่เกี่ยวข้อง

## ทำไม iCare สำคัญ

Gap Review ระบุว่า iCare เป็นเจ้าของ 2 field ในหมวด Device Ownership ซึ่งเป็นหมวดที่รายงานจัดเป็น**ช่องว่างอันดับ 1 ของทั้งโปรแกรม**

| ID | Field | สถานะ | เหตุผลในรายงาน |
|---|---|---|---|
| `DEV-03` | Warranty Expiry Date | ขาด | "ใช้ trigger ขายประกันขยายและบริการหลังการขาย" |
| `DEV-05` | Service / Repair / Claim History | ขาด | "สะท้อนความพึงพอใจและความเสี่ยง churn โดยตรง" |

## ที่ไม่รู้

**iCare รันบนระบบอะไร** — ไม่มีชื่อระบบในเอกสารไหนเลย · Insurance กับ Mobile Service เป็นคนละระบบหรือระบบเดียว · เป็นนิติบุคคลแยกไหม · ใช้ customer identifier อะไร · เก็บ serial/IMEI ของเครื่องไหม

---

# Tech Trade

Survey ยังไม่เริ่ม · K.Koj, K.Poj · เขียนว่า **Tectrade** ด้วย

**ไม่อยู่ใน project brief เดิม** — เจอจากการตรวจเอกสาร

## เจอที่ไหน

1. Timeline item `1.2.2` — "Tech Trade" ใต้ Other Legacy System
2. Gap Review `DEV-04` — Source System และ Owner ระบุว่า "Tectrade"

## เป็นเจ้าของอะไร

`DEV-04` **Trade-in History + Eligibility** — สถานะ **ขาด**, P2
เหตุผลในรายงาน: *"ใช้คำนวณข้อเสนอเทิร์นรายบุคคล"*

## ทำไมสำคัญ

Data Framework slide 7 ระบุ historical transaction ที่ CRM ต้องการว่า *"buy, sale, **trade-in**, trn-amt, trn-frequency, first-last trn"*

เทิร์นเครื่องถูกระบุระดับ framework แต่ระบบที่ถือข้อมูลนี้ไม่อยู่ใน brief เดิม `[อนุมาน]`

GI Core มี model `buyback_iphone` ด้วย — กิจกรรมรับซื้อคืนเกิดอย่างน้อย 2 ที่

## ที่ไม่รู้

รันบนระบบอะไร · เป็น BU หรือระบบ หรือทั้งคู่ · เป็นนิติบุคคลแยกไหม · ถือ customer identifier อะไร · เก็บ serial/IMEI ไหม · สัมพันธ์กับ `buyback_iphone` ยังไง · ทำไมถูกจัดเป็น Other Legacy System

---

# Azure Synapse + ADLS

กำลังย้ายมา AWS · PoC issue ข้อ 8

## ที่รู้

**เอกสาร:** PDF 2 ไฟล์ใน `D:\Azure\` เขียนโดย vendor **Alphametrics**
- COM7-02 Enterprise Analytics Platform — Synapse Analytics user manual (31 หน้า)
- COM7-02 Training material — Azure Synapse

**Server:** `syndpdev001` · ตารางที่เห็นใน SQL: `tm_Item`, `tb_SalesInvoice`, `tb_PurchInvoice`, `tm_FinDimValueSet`

prefix `tm_` / `tb_` น่าจะเป็น convention master / transaction `[อนุมาน]`

**Source ที่ป้อนเข้ามา** ตาม PoC review:
> "ปัจจุบันข้อมูลจาก SharePoint 365 / Azure Data Lake Storage ใช้ Azure Synapse"

## แนวทาง migration

> "สำรวจการใช้งานระบบเดิมก่อนว่าใช้ Service และ Function ใดบ้าง จากนั้นนำมาเปรียบเทียบกับ AWS Services ที่เหมาะสม เช่น S3, Glue, Athena และ Redshift และออกแบบ Flow ใหม่"

## ลำดับความสำคัญ

Timeline Pilot item 1 — เป็นงานแรกของ Pilot นำหน้าแม้แต่ ITEC replication
tag ที่ระบุ: `RPA/GLUE/ AI AGENT`

tag `RPA` บ่งชี้ว่ามี RPA อยู่ในเส้นทาง D365→Synapse ปัจจุบัน `[อนุมาน]`

## ที่ไม่รู้

ADLS Gen1 หรือ Gen2 · BU ไหนที่ข้อมูลผ่าน Synapse · ใช้ service/function ไหนบ้าง · มี Azure Data Factory ไหม · data format อะไร · RPA ทำอะไร · `syndpdev001` เป็น dev environment ไหม (ชื่อมี `dev`) มี production แยกไหม · Alphametrics ยังทำงานด้วยกันอยู่ไหม

---

## อ่านต่อ

[[System Inventory]] · [[ITEC]] · [[EV Business (GI Core & EV7)]] · [[../2 AWS Data Lake/Status & Phases|Status & Phases]]
