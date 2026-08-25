# Decisions

สิ่งที่ตัดสินใจไปแล้ว พร้อมเหตุผล
ถ้ายังถกกันอยู่ ให้อยู่ใน [[Open Questions & Risks]] ไม่ใช่ที่นี่

---

## D-01 · Region หลักคือ ap-southeast-7

**ที่มา:** AWS Proposal (4 ส.ค. 2026)

Storage, ingestion, transformation, analytics deploy ที่ AWS Asia Pacific (Thailand)

**หลักฐานเสริมจากการวัด:** query ข้าม region ช้ากว่า 2.6 เท่าบนข้อมูลเดียวกัน → [[../7 Reference/Athena Benchmark|Athena Benchmark]]

---

## D-02 · ใช้ Medallion architecture บน S3

**ที่มา:** AWS Proposal + บันทึกออกแบบของทีม

Raw → Bronze → Silver → Gold พร้อม Quarantine zone
*(เส้นแบ่งแต่ละ layer ยังไม่ตกลง → [[Architecture]])*

---

## D-03 · ใช้ Parquet + Iceberg

**ที่มา:** PoC review

Columnar format สำหรับงาน analytics ช่วยลดข้อมูลที่ต้อง scan และลด cost ของ Athena

**ข้อควรรู้จากการวัด:** Iceberg ช้ากว่า Hive-style partition บน query เล็กที่กรองแล้ว (2.44 vs 1.71 วินาที) แต่ใกล้เคียงกันบน full scan → เลือก Iceberg เพราะความสามารถ (ACID update/delete, schema evolution, time travel) ไม่ใช่เพราะเร็วกว่า `[อนุมาน]`

---

## D-04 · ใช้ Power BI ใน Phase 1 ไม่ใช่ QuickSight

**ที่มา:** PoC review ข้อ 6 และ 7 (ทั้งคู่สถานะ Complete)

QuickSight ไม่มี region ในไทย ผลทดสอบพบว่า cross-region ทำให้ runtime, latency และค่าใช้จ่ายเพิ่มอย่างมีนัยสำคัญ โดยค่าใช้จ่ายส่วนใหญ่มาจาก Amazon Q

Athena → Power BI ทดสอบแล้วเชื่อมได้ผ่าน Athena ODBC ด้วย Access Key และ Secret Key ที่ admin สร้างให้

**ทบทวนเมื่อ:** QuickSight เปิดให้บริการใน Thailand Region

---

## D-05 · ไม่ scan malware ทุก object

**สถานะ: เสนอไว้ ยังไม่เห็นการอนุมัติเป็นทางการในเอกสาร**
**ที่มา:** PoC review ข้อ 2

Scan ทุก object ทำให้ GuardDuty อย่างเดียวประมาณ 3,500 USD/เดือน และข้อมูลส่วนใหญ่มาจาก internal database ผ่าน VPN

**แนวทาง:** ทำ Data Classification / Threat Model ก่อน แล้ว scan ตามความเสี่ยงราย source

**ข้อแม้ที่บันทึกไว้เอง:** *"VPN ไม่ได้ทำหน้าที่ Scan Malware โดยตรง"* — เป็นการยอมรับความเสี่ยง ไม่ใช่การรับประกันความปลอดภัย

---

## D-06 · เริ่มด้วย Athena เลื่อน Redshift ไปก่อน

**สถานะ: เสนอไว้ กำลังทดสอบ**
**ที่มา:** PoC review ข้อ 4

เริ่มจาก `S3 (Silver, Gold) → Iceberg + Parquet → Athena → BI` แล้วทำ performance test

**จะพิจารณา Redshift เมื่อพบว่า:** query ใช้เวลานานเกิน requirement · มี query จำนวนมาก · query มี join/aggregation ซับซ้อน · dashboard ต้องการ response time ต่ำ (โดยเฉพาะรายงานผู้บริหาร) · Athena cost จาก query volume สูง

---

## D-07 · สร้าง customer_id ใหม่แต่เก็บ source ไว้

**ที่มา:** บันทึกประชุม GI+EV7 (21 ส.ค. 2026)

> "gen customer_id ตัวใหม่แต่ยังเก็บ source ไว้"

หลักการเดียวกันปรากฏในงาน K2/ITOS ด้วย โดยใส่คอลัมน์ `SOURCE_SYSTEM` ในคิวรี่ union

---

## D-08 · Dedupe ลูกค้าด้วยเลขบัตรประชาชนเป็นหลัก

**ที่มา:** บันทึกประชุม GI+EV7

> "ต้องกำหนดหลักในการ Deduplicate เช่น ใช้เลขบัตรประชาชน(ถ้ามี)/email/เบอร์โทร"

ลำดับ: เลขบัตร → email → เบอร์โทร

**ยังไม่ตอบ:** ถ้าไม่มีเลขบัตรจะทำยังไง (GI Core `IdentityCard` เป็น nullable)

---

## D-09 · Clean และ migrate ข้อมูล GI/EV7 ก่อน แล้วค่อย integrate เข้า 7Club

**ที่มา:** บันทึกประชุม GI+EV7

> "data ของ EV7&GI ยังไม่สะอาดเท่าที่ควร บวกกับยังไม่ได้ทำการ standardize ให้เข้ากับ 7club ทางที่ประชุมจึงเห็นว่าควรเริ่มจากการ migrate เเละ clean data ก่อน"

---

## D-10 · รวม K2 กับ ITOS เป็นระบบเดียว

**สถานะ: กำลังทำ (Data Preparation)**
**ที่มา:** ClickUp `K2 & ITOS Integrated Loan System.txt`

สร้าง full loan system ครอบคลุม `APP In → Scoring → Approve → Collection → Close Case`

**แผน migrate 3 ช่วง:** ทั้งคู่ป้อน Unified → ตรวจสอบข้อมูล → K2 ค่อยๆ ลดการใช้งาน → เลิกใช้ K2 เหลือ ITOS

มี 2 แผนการสร้างที่บันทึกไว้ (UnionPlan1 กับ UnionPlan2) โดย **UnionPlan2 สร้าง schema เปล่าก่อนแล้วค่อย insert ทีละ table** พร้อมเพิ่มคอลัมน์ระบุว่า migrate มาจากไหน

---

## D-12 · เชื่อม database ผ่าน VPN Client โดย Vanguard แทน Site-to-Site VPN

**ที่มา:** ประชุม 24 ส.ค. 2026

เดิม AWS Proposal ระบุ Site-to-Site VPN 30 encrypted tunnels บน Virtual Private Gateway
ที่ประชุมสรุปว่าจะต่อผ่าน **VPN Client โดย Vanguard** แทน

**ยังไม่รู้:** Vanguard คืออะไร · เหตุผลที่เปลี่ยน · เป็นแนวทางถาวรหรือเฉพาะ PoC · แผน Site-to-Site เดิมยกเลิกหรือเลื่อน

**สิ่งที่ต้องตามต่อ:** VPN Client รองรับการเชื่อมต่อแบบต่อเนื่องของ pipeline (เช่น DMS CDC) ได้ไหม เพราะโดยทั่วไป Client VPN ออกแบบให้ client ต่อเข้าเครือข่าย ต่างจาก Site-to-Site ที่เชื่อมเครือข่ายถึงเครือข่ายแบบเปิดค้าง `[อนุมาน]`

---

## D-11 · Consent PDPA แยกเป็น task ต่างหาก

**ที่มา:** `datacleanplan.txt` + Project Timeline

> "Consent PDPA จะอยู่ในช่วง Standardize ข้อมูล → สร้างTable ใหม่รวมข้อมูล Customer > แยกไปอีก Task"

Timeline ระบุ "Customer Consent for Com7 Group" เป็น Related Project แยก

---

## แบบฟอร์มสำหรับบันทึกครั้งต่อไป

```markdown
## D-XX · <ตัดสินใจอะไร>
**สถานะ:** เสนอ / ตกลงแล้ว / ถูกแทนที่
**วันที่:** · **ใครตัดสิน:** · **ที่มา:**

**บริบท:** ปัญหาอะไรที่ทำให้ต้องตัดสินใจ
**ที่เลือก:**
**ที่ไม่เลือก และทำไม:**
**ทบทวนเมื่อ:**
```

---

## อ่านต่อ

[[Open Questions & Risks]] · [[Status & Phases]] · [[Architecture]]
