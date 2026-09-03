# Google Sheet to S3 (Lambda)

> **หมายเหตุที่มา:** บันทึกจากการ deploy จริงบน AWS account `603238661233` เมื่อ 2026-09-02 — ทุกอาการที่เขียนไว้มาจาก CloudWatch log ของฟังก์ชันจริง ไม่ใช่เอกสาร

Pipeline เส้นเล็กที่สุดใน lake ตอนนี้ — ดึงข้อมูลจาก Google Sheet ที่ทีมงานคีย์มือ แล้วลงจอดเป็น CSV บน S3 เพื่อให้ Glue/Athena อ่านต่อได้

---

## Flow

```
Secrets Manager ──► Google OAuth ──► Sheets API ──► CSV (/tmp) ──► S3
   (service acct)    (access token)   (ดึงทั้งชีต)    (แปลงร่าง)    (ปลายทาง)
```

| ส่วน              | ค่า                                                             |
| ----------------- | --------------------------------------------------------------- |
| Spreadsheet ID    | `1ZuZvelevthX1O0bcaWaWfMuh16zteZkbYim8OPgPwn4`                  |
| Sheet (tab)       | `Query` · ช่วง `A:ZZ`                                           |
| ปลายทาง           | `s3://google-sheet-extract/google-sheet-ev7/leads-ev7-2026.csv` |
| Secret            | `com7/google-sheets/service-account`                            |
| Lambda role       | `test-ingest-googlesheet-role-mg3ktraq`                         |
| Runtime           | Python 3.13 · x86_64                                            |
| ไฟล์โค้ดบนเครื่อง | `C:\Users\Sapon.S\lambda-build\` → `lambda-package-linux.zip`   |

**Key ปลายทางชื่อ `leads-ev7`** — เป็นข้อมูลฝั่ง EV7 จึงเกี่ยวกับ [[GI + EV7 to 7Club]] โดยตรง

---

## โครงโค้ด

### boto3 client วางนอก handler

```python
secrets = boto3.client("secretsmanager")
s3 = boto3.client("s3")

def lambda_handler(event, context):
    ...
```

โค้ดนอก handler รันเฉพาะตอน **cold start** พอถูกเรียกซ้ำ Lambda ใช้ container เดิมและข้ามส่วนนี้ไป — ในการทดสอบจริงเห็นเป็น `Init Duration: 800 ms` ที่หายไปในรอบถัดมา

### credential อยู่ใน Secrets Manager ไม่ใช่ในโค้ด

```python
secret_response = secrets.get_secret_value(SecretId=SECRET_NAME)
credentials = json.loads(secret_response["SecretString"])
```

ไฟล์ service account JSON ของ Google มี private key อยู่ข้างใน ถ้าฝังใน zip ใครอ่านโค้ดฟังก์ชันได้ก็ได้กุญแจไปด้วย — ตรงกับกติกาข้อมูลอ่อนไหวที่ห้ามเก็บ credential ในโน้ตหรือ repo

### แลก private key เป็น access token

```python
scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
creds = service_account.Credentials.from_service_account_info(credentials, scopes=scopes)
creds.refresh(Request())
access_token = creds.token
```

Google ไม่รับ private key ตรง ๆ ต้องเอาไปเซ็น JWT แล้วแลกเป็น access token อายุ 1 ชั่วโมง

**ขั้นตอนเซ็น JWT นี่เองที่บังคับให้ต้องมี library `cryptography`** ซึ่งเป็นต้นตอของปัญหา packaging ทั้งหมดข้างล่าง

`readonly` scope = ต่อให้ token หลุด ก็แก้ชีตต้นทางไม่ได้

### เขียน CSV ผ่าน /tmp ไม่ใช่ผ่าน RAM

```python
with open("/tmp/output.csv", "w", encoding="utf-8-sig", newline="") as f:
    writer = csv.writer(f, lineterminator=chr(10))
    writer.writerow(headers)
    for i in range(1, len(values)):
        row = values[i]
        values[i] = None          # ปล่อย memory ทีละแถว
        if len(row) < width:
            row = row + [""] * (width - len(row))
        writer.writerow(row[:width])
```

| จุด | เหตุผล |
|---|---|
| เขียนลง `/tmp` | `/tmp` มี 512 MB **แยกจาก memory ของฟังก์ชัน** ขนาดชีตจึงแทบไม่กระทบ RAM |
| `utf-8-sig` | ใส่ BOM ให้ Excel เปิดภาษาไทยไม่เพี้ยน |
| `lineterminator=chr(10)` | บังคับ LF — ค่า default ของ `csv` คือ CRLF ซึ่งทำให้ Athena/Glue ติดอักขระ CR ค้างท้ายคอลัมน์สุดท้าย |
| `csv.writer` | escape เครื่องหมายคำพูดให้เอง ค่าที่มี `"` หรือ `,` ข้างในจึงไม่ทำไฟล์พัง |
| `values[i] = None` | ทิ้ง reference ทีละแถวระหว่างวน ไม่ถือข้อมูลทั้งชุดค้างไว้ |

**Google ตัดช่องว่างท้ายแถวทิ้ง** — แถวที่ 3 ช่องท้ายว่างจะส่งมาสั้นกว่าแถวอื่น ต้องเติมเองให้ครบ `width` ไม่งั้นคอลัมน์เลื่อนตอน Athena อ่าน

### upload_file ไม่ใช่ put_object

```python
s3.upload_file(tmp_path, S3_BUCKET, S3_KEY, ExtraArgs={"ContentType": "text/csv"})
```

`upload_file` สตรีมจากดิสก์และแบ่ง multipart ให้อัตโนมัติ · `put_object` ต้องโหลดทั้งก้อนเข้า RAM ก่อน

---

## Packaging — ทำไมต้อง zip และทำไมต้อง Linux

**บทเรียนที่ใช้ซ้ำได้กับทุก Lambda ที่ต้องใช้ library นอก stdlib**

### ทำไมต้อง zip

Lambda ให้ Python มาแค่ **standard library + boto3** ไม่มี `google-auth`, `requests`, `cryptography` และไม่มี `pip install` บนเซิร์ฟเวอร์ให้เรียก — ต้องแพ็ก library ไปพร้อมโค้ด แล้ว Lambda จะแตก zip ลง `/var/task/` ซึ่งเป็น import path แรก

### ทำไมต้อง Linux

Library แบ่งเป็น 2 แบบ

| แบบ                            | ตัวอย่าง                                           | ย้ายข้ามเครื่อง |
| ------------------------------ | -------------------------------------------------- | --------------- |
| Pure Python                    | `google-auth` · `pyasn1` · `requests`              | ได้             |
| **มี native code คอมไพล์แล้ว** | **`cryptography`** · `cffi` · `charset_normalizer` | **ไม่ได้**      |

`cryptography` มีโค้ด Rust/C คอมไพล์ไว้ ซึ่งผูกกับทั้ง **OS และเวอร์ชัน Python**

`pip install` บน Windows + Python 3.14 จะได้ `_cffi_backend.cp314-win_amd64.pyd` (นามสกุล `.pyd` คือ DLL ของ Windows) แต่ Lambda คือ Amazon Linux + Python 3.13 อ่านไฟล์นั้นไม่ออก

### คำสั่ง build ที่ถูกต้อง

```
pip install --target lambda-build --platform manylinux2014_x86_64 --implementation cp --python-version 3.13 --only-binary=:all: google-auth requests
```

| flag | หน้าที่ |
|---|---|
| `--platform manylinux2014_x86_64` | ดาวน์โหลด wheel ของ Linux x86_64 แทนของเครื่องตัวเอง |
| `--python-version 3.13` | ให้ตรงกับ runtime ของ Lambda |
| `--only-binary=:all:` | ห้าม pip build จาก source (ถ้า build จะได้ของ Windows อีก) |
| `--target` | ลงในโฟลเดอร์แทน site-packages |

**ตรวจว่า build ถูก** — ต้องไม่มี `.pyd` `.exe` `.dll` เหลือ และไฟล์ `.so` ต้องลงท้ายด้วย `linux-gnu` หรือ `abi3`

```
_cffi_backend.cpython-313-x86_64-linux-gnu.so     ถูก
cryptography/hazmat/bindings/_rust.abi3.so        ถูก
```

pip บน Windows ยังแถมโฟลเดอร์ `bin/` ที่มี `.exe` มาด้วย — ลบทิ้งได้

### 3 ค่าที่ต้องตรงกันเสมอ

| ตอน build | ตอนตั้งค่า Lambda |
|---|---|
| `--platform manylinux2014_x86_64` | Architecture = x86_64 (ถ้าใช้ Graviton ต้องเป็น `aarch64`) |
| `--python-version 3.13` | Runtime = Python 3.13 |
| ชื่อไฟล์ `.py` + ชื่อฟังก์ชัน | Handler = `lambda_function.lambda_handler` |

### zip ต้องใช้ path แบบ POSIX

ที่ใช้จริงคือ Python `zipfile` เขียน arcname ด้วยเครื่องหมาย `/` และตั้ง permission 755 ให้ไฟล์ `.so` — ปลอดภัยกว่าปล่อยให้เครื่องมือฝั่ง Windows จัดการ path ให้เอง

---

## ปัญหาที่เจอจริง 5 ข้อ

| # | Error ที่ขึ้น | สาเหตุจริง | วิธีแก้ |
|---|---|---|---|
| 1 | `Runtime.ImportModuleError: cannot import name 'exceptions' from 'cryptography.hazmat.bindings._rust'` | build บน Windows + Python 3.14 | รีบิลด์ด้วย manylinux wheel |
| 2 | `AccessDeniedException` ตอน `GetSecretValue` | Lambda role ไม่มี policy | เพิ่ม inline policy |
| 3 | `HTTP Error 404` จาก Sheets API | Spreadsheet ID พิมพ์เกิน (46 ตัวอักษร แทนที่จะเป็น 44) | แก้ ID |
| 4 | `Task timed out after 3.00 seconds` | timeout default 3 วินาที | ตั้ง 5 นาที |
| 5 | `Runtime.OutOfMemory` ที่ 127/128 MB | ถือข้อมูลชุดเดียวซ้อนกัน 3 ชุด | เขียนผ่าน `/tmp` + `del` |

### กับดักที่ควรจำ

**404 ของ Sheets API ไม่ได้แปลว่าไฟล์ไม่มี** — ถ้า service account ยังไม่ถูก share เข้าชีต Google จะตอบ 404 ไม่ใช่ 403 (จงใจไม่บอกว่าไฟล์มีจริงไหม) จึงแยกไม่ออกระหว่าง "ID ผิด" กับ "ไม่มีสิทธิ์" ต้องเช็กทั้งสองทาง

**`urlopen` ทิ้ง error body ของ Google** — Python ขึ้นแค่ `HTTP Error 404: Not Found` ทั้งที่ Google ส่งคำอธิบายมาใน body ต้องดักเองถึงจะเห็น

```python
except urllib.error.HTTPError as e:
    print("Google API says:", e.read().decode("utf-8", "replace"))
    print("Spreadsheet ID used:", SPREADSHEET_ID)
    print("Service account:", credentials.get("client_email"))
    raise
```

**Spreadsheet ID ของ Google ยาว 44 ตัวอักษรเสมอ** — นับความยาวก่อนคือวิธีจับ typo ที่เร็วที่สุด

**128 MB ให้ CPU น้อยมาก** — Lambda จัดสรร CPU ตามสัดส่วน memory การเพิ่มเป็น 1024 MB มักถูกลงด้วยซ้ำเพราะคิดค่าใช้จ่ายตาม GB-วินาที งานเสร็จเร็วกว่าหลายเท่า

---

## IAM policy ที่ต้องมี

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadGoogleServiceAccountSecret",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": "arn:aws:secretsmanager:*:603238661233:secret:com7/google-sheets/service-account-*"
    },
    {
      "Sid": "WriteCsvToS3",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::google-sheet-extract/google-sheet-ev7/*"
    }
  ]
}
```

**ARN ของ secret มี suffix สุ่มต่อท้าย** ที่ AWS เติมให้ตอนสร้าง จึงต้องปิดท้ายด้วย `*` ไม่งั้นไม่ match

ถ้า secret เข้ารหัสด้วย customer-managed KMS key ต้องเพิ่ม `kms:Decrypt` ด้วย — เคสนี้ใช้ `aws/secretsmanager` จึงไม่ต้อง

---

## ค่าตั้งที่ใช้อยู่

| ค่า          | ตั้งเป็น                         |
| ------------ | -------------------------------- |
| Runtime      | Python 3.13                      |
| Architecture | x86_64                           |
| Handler      | `lambda_function.lambda_handler` |
| Timeout      | 5 นาที                           |
| Memory       | 1024 MB                          |

---

## ยังไม่ครบตามข้อกำหนด log ของทีม

ข้อกำหนดที่ตกลงกัน 2026-08-27 บอกว่าทุก job ต้องบันทึกปริมาณต้นทาง · ปริมาณปลายทาง · เวลาเริ่ม-เสร็จ · โหมดเขียน · ชื่อตาราง → [[ETL & Spark]]

ตอนนี้ฟังก์ชันนี้ print ออก CloudWatch แค่

- จำนวนแถวต้นทาง (`Google Sheet Rows:`)
- ขนาดไฟล์ CSV (`CSV bytes:`)
- ผลการอัปโหลดและ `head_object` ยืนยันว่าไฟล์ขึ้นจริง

**ยังขาด** จำนวนแถวปลายทางเทียบต้นทาง · timestamp เริ่ม-เสร็จ · การระบุโหมดเขียน → งานค้างอยู่ที่ [[Pipeline Issues]]

**โหมดเขียนคือ rewrite เสมอ** — key ปลายทางเป็นชื่อคงที่ ทุกรอบเขียนทับของเดิมทั้งไฟล์ ไม่มีประวัติย้อนหลัง `[อนุมาน จากโค้ด]`

---

## ข้อควรระวัง

**ไฟล์ปลายทางชื่อ `leads-ev7-2026.csv` น่าจะเป็นข้อมูลลูกค้าที่มี PII** ถ้าใช่ ต้องอยู่ใต้กติกาเดียวกับข้อมูลลูกค้าอื่นใน lake → [[Consent & PDPA]] · [[Customer Identity]] `[อนุมาน จากชื่อไฟล์ ยังไม่ได้ดูเนื้อข้อมูลจริง]`

**Google Sheet เป็นต้นทางที่ไม่มี schema บังคับ** — คนแก้ชีตเพิ่ม ลบ หรือสลับคอลัมน์เมื่อไหร่ก็ได้ และ pipeline จะไม่รู้ตัว เพราะโค้ดยึด `values[0]` เป็น header เสมอ ปัญหาชุดเดียวกับ [[Data Standardization & Quality]]

**ยังเป็น manual trigger** — ยังไม่ได้ผูก EventBridge schedule เข้ากับรอบ 23:30 น. ที่ทีมตกลงกันไว้

---

## เชื่อมกับโน้ตอื่น

[[ETL & Spark]] · [[AWS Services]] · [[Architecture]] · [[GI + EV7 to 7Club]] · [[EV Systems]] · [[Consent & PDPA]] · [[Data Standardization & Quality]] · [[Pipeline Issues]]
