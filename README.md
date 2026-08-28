# my-first-project

งานข้อมูลที่ **บริษัท คอมเซเว่น จำกัด (มหาชน)** — สำรวจระบบต้นทาง เตรียมข้อมูลเข้า AWS Data Lake

---

## โครงสร้าง

| โฟลเดอร์ | คืออะไร |
|---|---|
| **`COM7-Knowledge-Base/`** | **Obsidian vault** — ความรู้ทั้งหมดอยู่ที่นี่ เปิดด้วย Obsidian |
| `scripts/k2/` | สคริปต์สำรวจและดึงข้อมูลจากฐาน K2 (`HPCOM7`) |
| `scripts/legacy/` | สคริปต์ทดลองช่วงแรก เก็บไว้อ้างอิง |
| `sql/` | คิวรี่ที่ใช้งานจริง |
| `glue-etl/` | AWS Glue job — ITEC raw → bronze |
| `docs/` | บันทึกและเอกสารเบ็ดเตล็ด |
| `data/` | **ไม่เข้า git** — ไฟล์ข้อมูลลูกค้าจริง |

---

## เริ่มตรงไหน

เปิด vault แล้วอ่าน [`COM7-Knowledge-Base/README.md`](COM7-Knowledge-Base/README.md)

งาน K2 ที่ทำล่าสุด → `COM7-Knowledge-Base/3 Source System Survey/K2 (HPCOM7)/K2 Overview.md`

---

## รันสคริปต์

**credential ไม่ได้ hardcode ในไฟล์** — ต้องตั้ง environment variable ก่อน

```powershell
$env:K2_USER = "..."
$env:K2_PWD  = "..."

python scripts\k2\k2_survey.py                 # ดึง metadata ทั้งฐานลง _raw/
python scripts\k2\k2_samples.py                # ดึง sample rows แบบ mask PII
python scripts\k2\k2_profile_columns.py        # profile ทุกคอลัมน์ของตารางแกน
python scripts\k2\k2_termination_to_excel.py   # ทำรายชื่อบอกเลิกสัญญาลง Excel
```

ทุกสคริปต์ **อ่านฐานอย่างเดียว** ไม่มี INSERT / UPDATE / DDL

---

## กติกาเรื่องข้อมูล

| | |
|---|---|
| **ห้าม commit ไฟล์ที่มีข้อมูลลูกค้าจริง** | ชื่อ · เลขบัตร · ที่อยู่ · เบอร์โทร · อีเมล → เก็บใน `data/` เท่านั้น |
| **ห้าม hardcode รหัสผ่าน** | ใช้ environment variable |
| sample data ที่อยู่ใน vault | mask แล้วทุกช่อง — ดู `scripts/k2/k2_samples.py` |
| `_raw/*.csv` ใน vault | เป็น metadata ของฐาน (ชื่อตาราง/คอลัมน์) ไม่มี PII |

> ⚠️ **รหัสผ่านเวอร์ชันเก่ายังอยู่ใน git history** (commit `586cab2`)
> ไฟล์ปัจจุบันแก้แล้ว แต่ถ้าจะให้ปลอดภัยจริงต้อง **เปลี่ยนรหัสผ่านที่ฝั่งฐานข้อมูล**
