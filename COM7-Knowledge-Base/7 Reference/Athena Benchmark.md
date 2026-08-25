# Athena Benchmark

ที่มา: `D:\aws\etl-lab\athena_performance.pptx` (45 query runs) สรุปใน `athena performance.xlsx`

---

## วิธีทดสอบ

- Dataset: **Itec sale**
- Storage: S3 ที่ `ap-southeast-7`
- Engine: Amazon Athena
- แต่ละ test รัน query เดิม **8–10 ครั้งติดต่อกัน** ปิด query-result cache แล้วอ่านค่าจากแท็บ Query stats ใน Athena console

ตัวแปรที่ทดสอบ 2 ตัวแยกกัน: **schema type** (Iceberg vs Hive-style partition) และ **region**

---

## ผล

### Test 1 — Schema type บน full scan

6.15M แถว / 433 MB · ทั้งคู่อยู่ที่ ap-southeast-7

| Schema | เวลาเฉลี่ย |
|---|---|
| Iceberg | 15.58 วินาที |
| Partitions (Crawler) | 14.34 วินาที |

ต่างกันไม่ถึง 9%

### Test 2 — Schema type บน query ที่กรองแล้ว

374.95K แถว / 26.35 MB (`WHERE year=2026 AND month=3`) · ทั้งคู่ที่ ap-southeast-7

| Schema | เวลาเฉลี่ย | ส่วนเบี่ยงเบน |
|---|---|---|
| Partitions (Crawler) | **1.71 วินาที** | 0.08 |
| Iceberg | **2.44 วินาที** | **0.63** |

Iceberg ช้ากว่า 43% และแปรปรวนกว่ามาก — บาง run มีสัดส่วน Planning สูงถึง 19–23%

### Test 3 — Cross-region

ข้อมูลเดียวกัน (374.95K แถว / 26.35 MB) schema เดียวกัน (Partitions)

| Region ที่รัน Athena | เวลาเฉลี่ย | สัดส่วน Planning |
|---|---|---|
| ap-southeast-7 | **1.71 วินาที** | 8.7% |
| us-east-1 (cross-region) | **4.39 วินาที** | **19.2%** |

**ช้ากว่า 157% หรือ 2.6 เท่า**

---

## ข้อสังเกต

**Cross-region:** ปริมาณ bytes ที่ scan **ไม่เปลี่ยนเลย** เปลี่ยนแค่เวลา และสัดส่วน Planning เพิ่มจาก 8.7% เป็น 19.2%

Query planning ต้องคุยกับ metadata หลายรอบ จึงน่าจะเป็นส่วนที่ไวต่อ latency ที่สุด `[อนุมาน]`

**Iceberg บน query เล็ก:** Iceberg ต้องอ่าน snapshot/manifest metadata ก่อนจึงจะ prune ไฟล์ได้ ซึ่งบน scan ใหญ่ไม่สำคัญ แต่บน scan เล็กกลายเป็นสัดส่วนที่ใหญ่ `[อนุมาน]`

---

## ข้อค้นพบที่สำคัญที่สุด

เทียบ Test 1 กับ Test 2 (full scan vs กรอง ที่ region เดียวกัน):

| | Full scan | กรองแล้ว | ต่าง |
|---|---|---|---|
| Iceberg | 15.58 วินาที | 2.44 วินาที | **6.4 เท่า** |
| Partitions | 14.34 วินาที | 1.71 วินาที | **8.4 เท่า** |
| Data scanned | 433 MB | 26.35 MB | **ลด 94%** |

**Partition pruning สำคัญกว่าการเลือก schema format มาก** และเนื่องจาก Athena คิดเงินตาม TB ที่ scan การลด 94% หมายถึงลด cost ในสัดส่วนเดียวกัน

---

## สิ่งที่นำไปตัดสินใจ

1. **ให้ Athena workgroup อยู่ region เดียวกับข้อมูลบน S3 และ Glue Data Catalog** — ค่าปรับ 2.6 เท่าเกิดกับทุก query
2. **ใช้ Power BI ใน Phase 1** แทน QuickSight → [[../2 AWS Data Lake/Decisions|D-04]]
3. **กรอง partition column ใน dashboard เสมอ**
4. **เลือก Iceberg เพราะความสามารถ ไม่ใช่ความเร็ว** — ACID update/delete, schema evolution, time travel `[อนุมาน]`

---

## ข้อจำกัดของการทดสอบ

จำนวน run ต่อ test อยู่ที่ 8–10 ครั้ง — พอเห็นทิศทางชัด แต่ยังไม่แน่นพอสำหรับช่วงความเชื่อมั่นที่แคบ

ถ้าจะใช้ประกอบการตัดสินใจด้าน capacity หรือ cost อย่างเป็นทางการ ควรทดสอบซ้ำด้วย run ที่มากขึ้นและขนาดข้อมูลที่กรองแล้วใหญ่ขึ้น

---

## อ่านต่อ

[[../6 Technical/AWS Services|AWS Services]] · [[../6 Technical/ETL & Spark|ETL & Spark]] · [[../2 AWS Data Lake/Architecture|Architecture]] · [[../2 AWS Data Lake/Decisions|Decisions]]
