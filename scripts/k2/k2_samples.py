"""ดึงตัวอย่างข้อมูล (TOP 5) ของตารางแกน K2 แล้ว **mask PII ทุกครั้ง** ก่อนเขียนไฟล์

ผลลง _raw/samples-masked.md — ปลอดภัยพอที่จะ commit เพราะไม่มีค่า PII จริง

รันด้วย:  $env:K2_USER="..."; $env:K2_PWD="..."; python k2_samples.py
"""

import os
import re
import sys

import pyodbc

SERVER = os.environ.get("K2_SERVER", "43.254.133.123")
DATABASE = os.environ.get("K2_DB", "HPCOM7")
USERNAME = os.environ.get("K2_USER")
PASSWORD = os.environ.get("K2_PWD")

if not USERNAME or not PASSWORD:
    sys.exit(
        "ต้องตั้ง credential ก่อนรัน (ไม่ hardcode ไว้ในไฟล์นี้เพราะอยู่ใน git repo)\n"
        '  PowerShell:  $env:K2_USER="..."; $env:K2_PWD="..."\n'
        "  bash:        export K2_USER=... K2_PWD=..."
    )

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(
    ROOT, "COM7-Knowledge-Base", "3 Source System Survey", "K2 (HPCOM7)", "_raw"
)

# ตารางแกนที่คัดจาก row count + ชื่อที่สื่อโดเมน
TABLES = [
    # ลูกค้า
    "PERSON", "ADDRESS", "PROSPECT_CUSTOMER", "ADDRESS_PROSPECT_CUSTOMER",
    # ใบเสนอราคา → ใบคำขอ → สัญญา
    "QUOTATION", "APPLICATION", "PRODUCT", "CONTRACT", "CHECKER", "CHECKER_GUARANTOR",
    # ผ่อน / รับชำระ / เอกสารภาษี
    "CUSTOMER_CARD", "INVOICE", "REPAYMENT", "PAYMENT", "TAX_INVOICE",
    "ACCOUNT", "ACCOUNT_RECEIVABLE", "TRANSACTION_REPAY",
    # ติดตามหนี้
    "COLLECTION_OD", "COLLECTION_OD_ASSIGNMENT", "CONTACT_DEBT_COLLECTION",
    # master
    "MT_STATUS", "MT_ADDRESS_TYPE", "MT_PROVINCE", "MT_DISTRICT", "MT_SUB_DISTRICT",
    "MT_BRAND", "MT_CATEGORY", "MT_SERIES", "MT_OCCUPATION", "MT_BANK",
    "MT_REPAY_TYPE", "MT_TYPE_PAYMENT", "MT_MARITAL_STATUS", "MT_INSTALLMENT",
    "MT_COLLECTION", "MT_DebtContactStatus", "MT_SALARY_RANGE", "MT_RESIDENCE_STATUS",
    "SETUP_PARTNER", "SETUP_PARTNER_BRANCH",
]

# คอลัมน์ที่ตัดทิ้งทั้งช่อง — ไฟล์แนบ base64 / รูป / ลายเซ็น
DROP = re.compile(
    r"(_FILE|_FILE_|FILE_PATH|_PATH|_IMAGE|LOGO|_DOC|PASSWORD|SIGNATURE)", re.IGNORECASE
)

# ชื่อคอลัมน์ -> วิธี mask
NAME_COLS = re.compile(r"(FIRST_?NAME|LAST_?NAME|CUSTOMER_NAME|FULL_?NAME|SPOUSE_|REF_(TITLE|FIRSTNAME|LASTNAME)|_NAME_TH|PAY_NAME|REPAY_NAME|RECEIPT_NAME|EMP_NAME|COLLECTION_NAME|C_AUTHORIZED_NAME)", re.IGNORECASE)
ID_COLS = re.compile(r"(TAX_ID|CARD_NO|CITIZEN|IDCARD|REGIST_NO|ACCOUNT_NUMBER|CHEQUE_NUMBER)", re.IGNORECASE)
PHONE_COLS = re.compile(r"(PHONE|MOBILE|TEL)", re.IGNORECASE)
EMAIL_COLS = re.compile(r"(EMAIL|LINEID|FACEBOOK)", re.IGNORECASE)
ADDR_COLS = re.compile(r"(_NO$|_MOI$|_VILLAGE$|_BUILDING$|_ROOM_NO$|_SOI$|_ROAD$|ADDRESS_REGISTER|ADDRESS_CURRENT|ADDRESS_DELIVERY|ADDR)", re.IGNORECASE)
GEO_COLS = re.compile(r"(LATITUDE|LONGITUDE|LAT$|LONG$|URLMAP|ADR_MAP)", re.IGNORECASE)
# ช่องข้อความอิสระที่พนักงานพิมพ์เอง — เบอร์โทรและชื่อลูกค้าปนอยู่ในนั้นเสมอ
FREETEXT = re.compile(r"(REMARK|NOTE|DESCRIPTION|DESCIPTION|COMMENT|RESULT_COLLECTION|DES_SUM_AMT)", re.IGNORECASE)


def mask(col, val):
    if val is None:
        return "NULL"
    s = str(val)
    if s == "":
        return ""
    if DROP.search(col):
        return f"<ตัดออก {len(s)} ตัวอักษร>"
    # ID_COLS ต้องมาก่อนกฎ _ID เพราะ TAX_ID ลงท้ายด้วย _ID แต่เป็นเลขบัตรประชาชน
    if ID_COLS.search(col):
        return (s[0] + "-XXXX-XXXXX-XX-X") if len(s) == 13 else "X" * len(s)
    if FREETEXT.search(col):
        # ข้อความอิสระที่พนักงานพิมพ์เอง — มี PII ปนแน่นอน ตัดทั้งช่อง
        return f"<ข้อความอิสระ ตัดออก {len(s)} ตัวอักษร>"
    if col.upper().endswith("_ID"):  # surrogate key ไม่ใช่ PII เก็บค่าจริงเพื่อให้ตาม join ได้
        return s
    if PHONE_COLS.search(col):
        return ("XXX-XXX-" + s[-4:]) if len(s) >= 7 else "XXXX"
    if EMAIL_COLS.search(col):
        if "@" in s:
            u, d = s.split("@", 1)
            return (u[0] if u else "") + "***@" + d
        return s[0] + "***"
    if NAME_COLS.search(col):
        return " ".join((w[0] + "***") if w else "" for w in s.split()[:2])
    if GEO_COLS.search(col):
        return "<ตัดออก>"
    if ADDR_COLS.search(col):
        return "***"
    if len(s) > 60:
        return s[:57] + "..."
    return s


def main():
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};"
        f"UID={USERNAME};PWD={PASSWORD};TrustServerCertificate=yes;",
        timeout=60,
    )
    cur = conn.cursor()
    lines = [
        "# ตัวอย่างข้อมูล K2 (HPCOM7) — mask แล้ว",
        "",
        "สร้างโดย `k2_samples.py` · ทุกค่าที่เป็น PII ถูกปิดบังก่อนเขียนไฟล์",
        "ชื่อ → `ก***` · เลขบัตร → `1-XXXX-XXXXX-XX-X` · เบอร์ → `XXX-XXX-1234` ",
        "ที่อยู่บรรทัด (บ้านเลขที่/หมู่/ซอย/ถนน) → `***` · ไฟล์แนบ/พิกัด → ตัดออก",
        "**เงิน · วันที่ · รหัสสถานะ · id → เก็บค่าจริง** เพราะจำเป็นต่อการเข้าใจ business",
        "",
        "---",
        "",
    ]
    for t in TABLES:
        try:
            cur.execute(f"SELECT TOP 5 * FROM [{t}]")
            cols = [d[0] for d in cur.description]
            rows = cur.fetchall()
        except Exception as e:
            lines += [f"## {t}", "", f"อ่านไม่ได้ — {str(e)[:120]}", ""]
            continue
        keep = [i for i, cn in enumerate(cols) if not DROP.search(cn)]
        if len(keep) > 22:
            keep = keep[:22]
            note = f" · แสดง 22 คอลัมน์แรกจาก {len(cols)}"
        else:
            note = f" · {len(cols)} คอลัมน์"
        lines += [f"## {t}", "", f"{len(rows)} แถวตัวอย่าง{note}", ""]
        lines.append("| " + " | ".join(cols[i] for i in keep) + " |")
        lines.append("|" + "---|" * len(keep))
        for r in rows:
            lines.append(
                "| " + " | ".join(mask(cols[i], r[i]).replace("|", "/").replace("\n", " ") for i in keep) + " |"
            )
        lines.append("")
        print(f"  {t:<32} {len(rows)} rows")

    path = os.path.join(OUT, "samples-masked.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("written:", path)
    conn.close()


if __name__ == "__main__":
    main()
