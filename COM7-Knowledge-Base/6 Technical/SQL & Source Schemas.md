# SQL & Source Schemas

---

## ฐานข้อมูลที่พบใน SQL ที่ทีมใช้งาน

| ฐาน / Server | Engine | ระบบ |
|---|---|---|
| `ILOAN_COLLECTION` | MSSQL | ITOS |
| `ILOAN_DATASOURCE` | MSSQL | extract ของ ITOS |
| `HPCOM7` | MSSQL | K2 |
| `D365FO_DATALAKE` | ไม่ระบุ | D365 |
| `syndpdev001` | Azure Synapse | Synapse |
| `PROJECT_1` | MSSQL | view ของ ITEC |
| `TAN_MIS` | MSSQL | MIS |
| (GI Core) | **MySQL** | GI Core |

---

## Collation ต้องตรงกันตอน UNION

```sql
CAST(a.CONTRACT_NUMBER AS nvarchar) COLLATE DATABASE_DEFAULT AS CONTRACT_NUMBER
```

จำเป็นกับทุกคอลัมน์ข้อความตอนรวม K2 กับ ITOS เพราะสองฐานใช้ collation คนละแบบ

Error จาก collation จะชี้ไปที่ `UNION` ไม่ใช่ที่ต้นเหตุ ทำให้วินิจฉัยผิดได้ง่าย — ควรเช็ค collation ตั้งแต่ต้นเมื่อทำงานข้ามฐาน `[อนุมาน]`

---

## เติมคอลัมน์ที่ขาด

```sql
CAST(NULL AS nvarchar) COLLATE DATABASE_DEFAULT AS PRODUCT_MODEL
```

ยังต้อง cast เพราะ `NULL` เปล่าๆ ไม่มี type และ `UNION` ต้องการ type ที่ตรงกัน

---

## เพิ่มคอลัมน์ source

```sql
SELECT ..., 'ITOS' AS SOURCE_SYSTEM FROM ...
UNION ALL
SELECT ..., 'K2'   AS SOURCE_SYSTEM FROM ...
```

---

## ชื่อคอลัมน์ภาษาไทย

ตัวอย่างจริงจาก `PROJECT_1.dbo.view_itec_payment`:

```sql
SELECT ISNULL(vip.ประเภท, 'Total') AS Type,
       FORMAT(SUM(vip.[จำนวนเงินที่ได้รับ]), 'N0') AS ยอดเงินรวม
FROM [PROJECT_1].[dbo].[view_itec_payment] vip
```

ต้อง bracket-quote และระวัง encoding ตลอดเส้นทาง

---

## Typo ที่อยู่ใน production แล้ว

| ที่ควรเป็น | ที่มีจริง | ระบบ |
|---|---|---|
| `PRODUCT_ID` | `PRODUDCT_ID` | K2 |
| `PRINCIPAL` | `PRINCIPLE` | K2 |
| `first_name` | `fisrt_name` | GI Core |

แก้ที่ต้นทางไม่ได้แล้วโดยไม่กระทบผู้ใช้ ต้อง map ให้ถูกที่ Bronze `[อนุมาน]`

---

## Incremental extraction

| วิธี | ต้องมี | หมายเหตุ |
|---|---|---|
| Timestamp watermark | คอลัมน์ `updated_at` | **K2 ไม่มี** |
| CDC จาก transaction log | DB รองรับ CDC | วิธีของ DMS |
| ID watermark | key ที่เพิ่มเรื่อยๆ | ตาราง insert-only |
| Full reload | ไม่ต้องมีอะไร | ตารางเล็กเท่านั้น |

ควรเช็คว่ามี audit column ไหมตอน survey เพราะการไม่มีมันเปลี่ยนวิธี ingest `[อนุมาน]`

---

## อ่าน schema ที่ไม่คุ้นเคย

วิธีที่ใช้กับ ITOS ได้ผล `[อนุมาน]`:

1. **นับแถวก่อน** — เห็นว่าตารางไหนสำคัญจริง (`S_PMTSCHDLE` 3.77M vs `M_PRODUCT` 16)
2. **ดู index usage stats** — `sys.dm_db_index_usage_stats` บอกว่า application อ่านอะไรจริง (แต่ reset เมื่อ restart)
3. **ดู naming convention** — ITOS ใช้ `M_` master · `S_` core · `T_` transaction · `R_` report
4. **ข้าม backup table** — ITOS มีถูกตัด 167 tables เพราะ zero-row หรือชื่อ `BK_*`, `*_BK`, ลงท้ายตัวเลข
5. **ดู sample rows** — schema wiki ของ ITOS มี Top 10 rows ต่อ table ซึ่งเผยข้อมูลจริง เช่น `M_COMPANY` มีชื่อบริษัท และ `M_CHANNEL` มีช่องทางชำระเงิน

---

## Prisma

GI Core ใช้ Prisma — `schema.prisma` เป็น data dictionary ที่อ่านได้ทั้งไฟล์

### อ่านยังไง

```prisma
model customers {
  id_customer   Int       @id @default(autoincrement())
  fisrt_name    String    @db.VarChar(255)     // บังคับ
  last_name     String?   @db.VarChar(255)     // ? = nullable
  email         String    @db.VarChar(255)     // บังคับ
  IdentityCard  String?   @db.VarChar(13)      // nullable
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  districts     districts? @relation(fields: [id_district_2], references: [id_district])
  @@index([id_district_2], map: "customers_id_district_2_fkey")
}
```

| Syntax | ความหมาย |
|---|---|
| `Type?` | nullable |
| `Type[]` | one-to-many |
| `@id` | primary key |
| `@unique` | unique constraint |
| `@default(...)` | ค่า default |
| `@updatedAt` | timestamp อัปเดตอัตโนมัติ |
| `@db.VarChar(n)` | type จริงในฐาน |
| `@relation(...)` | foreign key |
| `enum` | ชุดค่าที่จำกัด |

### สิ่งที่ดึงจาก schema.prisma ของ GI Core ได้

- 166 models
- `provider = "mysql"`
- `IdentityCard` **nullable** — match key อาจไม่มี
- `email` และ `tel` **NOT NULL**
- `address` เป็น `LongText`
- `enum OrgCode { Com7, Aion, DPI1, CFW }`
- model ที่บอกใบ้ integration: `taxi_follow_ufund`, `buyback_iphone`, `taxi_lineman`, `taxi_grab`

**Nullability คือสิ่งที่มีค่าที่สุดที่ดึงออกมาได้** — บอกทันทีว่ากลยุทธ์ dedupe ด้วยเลขบัตรต้องมี fallback `[อนุมาน]`

### ใช้ก่อนเข้าประชุม survey

ถ้าระบบมี Prisma schema ดึงข้อมูลพวกนี้ก่อนได้ `[อนุมาน]`:

- จำนวนและชื่อ model
- model ไหนถือข้อมูลลูกค้า
- nullability ของ match key ทุกตัว
- มี `createdAt` / `updatedAt` ไหม
- enum ที่ต้อง standardize
- relation ที่บอกใบ้ integration

บันทึกประชุมระบุว่าการสร้าง ER จาก Prisma *"ซับซ้อนอยู๋"* · มีไฟล์ `ERD.svg` อยู่ข้าง schema แล้ว

---

## อ่านต่อ

[[ETL & Spark]] · [[AWS Services]] · [[../3 Source System Survey/System Inventory|System Inventory]] · [[../4 SSOT & Customer 360/Data Standardization & Quality|Data Standardization & Quality]]
