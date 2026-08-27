"""สำรวจ metadata ของฐาน K2 (HPCOM7) แบบอ่านอย่างเดียว

ผลลัพธ์ลงที่ COM7-Knowledge-Base/3 Source System Survey/K2 (HPCOM7)/_raw/

รันด้วย:  $env:K2_USER="..."; $env:K2_PWD="..."; python k2_survey.py
credential อ่านจาก env K2_USER / K2_PWD (ไม่ hardcode — ไฟล์นี้อยู่ใน git repo)
"""

import csv
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

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(
    HERE, "COM7-Knowledge-Base", "3 Source System Survey", "K2 (HPCOM7)", "_raw"
)

# ตารางขยะ: backup / temp / test / ลงท้ายด้วยวันที่ ใช้กฎเดียวกับ schema wiki ของ ITOS
JUNK_PATTERNS = [
    re.compile(p, re.IGNORECASE)
    for p in (
        r"_BACKUP$", r"_BK$", r"_BK_\d+$", r"^BK_", r"_BAK$",
        r"_TEMP\d*$", r"_TMP$", r"_TEST\d*$", r"_DEMO$", r"_OLD$",
        r"_\d{6}$", r"_\d{8}$", r"_\d{4}_\d{1,2}$",
    )
]


def is_junk(name):
    return any(p.search(name) for p in JUNK_PATTERNS)


def connect():
    return pyodbc.connect(
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={SERVER};DATABASE={DATABASE};"
        f"UID={USERNAME};PWD={PASSWORD};TrustServerCertificate=yes;",
        timeout=30,
    )


def dump(cur, filename, sql, header, transform=None):
    cur.execute(sql)
    rows = cur.fetchall()
    path = os.path.join(OUT, filename)
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in rows:
            w.writerow(transform(r) if transform else list(r))
    print(f"  {filename:<20} {len(rows):>6,} rows")
    return rows


Q_TABLES = """
SELECT t.name,
       ISNULL(p.rows, 0)                AS row_count,
       (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = t.object_id) AS n_cols,
       CONVERT(varchar(10), t.create_date, 120),
       CONVERT(varchar(10), t.modify_date, 120)
FROM sys.tables t
OUTER APPLY (
    SELECT SUM(pt.rows) AS rows FROM sys.partitions pt
    WHERE pt.object_id = t.object_id AND pt.index_id IN (0, 1)
) p
ORDER BY p.rows DESC
"""

Q_COLUMNS = """
SELECT t.name, c.column_id, c.name, ty.name,
       c.max_length, c.precision, c.scale, c.is_nullable, c.is_identity
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.types ty  ON ty.user_type_id = c.user_type_id
ORDER BY t.name, c.column_id
"""

Q_INDEXES = """
SELECT t.name, i.name, i.type_desc, i.is_primary_key, i.is_unique,
       STUFF((SELECT ', ' + c2.name
              FROM sys.index_columns ic2
              JOIN sys.columns c2 ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
              WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
              ORDER BY ic2.key_ordinal
              FOR XML PATH('')), 1, 2, '')
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
WHERE i.type > 0
ORDER BY t.name, i.is_primary_key DESC, i.name
"""

Q_FK = """
SELECT fk.name, tp.name, cp.name, tr.name, cr.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables tp  ON tp.object_id = fk.parent_object_id
JOIN sys.columns cp ON cp.object_id = fkc.parent_object_id AND cp.column_id = fkc.parent_column_id
JOIN sys.tables tr  ON tr.object_id = fk.referenced_object_id
JOIN sys.columns cr ON cr.object_id = fkc.referenced_object_id AND cr.column_id = fkc.referenced_column_id
ORDER BY tp.name
"""

Q_USAGE = """
SELECT t.name,
       SUM(s.user_seeks + s.user_scans + s.user_lookups) AS reads,
       SUM(s.user_updates)                               AS writes,
       CONVERT(varchar(19), MAX(s.last_user_seek), 120),
       CONVERT(varchar(19), MAX(s.last_user_scan), 120),
       CONVERT(varchar(19), MAX(s.last_user_update), 120)
FROM sys.dm_db_index_usage_stats s
JOIN sys.tables t ON t.object_id = s.object_id
WHERE s.database_id = DB_ID()
GROUP BY t.name
ORDER BY reads DESC
"""

Q_VIEWS = """
SELECT v.name,
       (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = v.object_id),
       CONVERT(varchar(10), v.modify_date, 120)
FROM sys.views v
ORDER BY v.name
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    print(f"connecting {SERVER}/{DATABASE} ...")
    conn = connect()
    cur = conn.cursor()
    print("connected. dumping metadata ->", OUT)

    tables = dump(
        cur, "tables.csv", Q_TABLES,
        ["table", "row_count", "n_cols", "created", "modified", "is_junk"],
        lambda r: list(r) + ["junk" if is_junk(r[0]) else ""],
    )

    live = {r[0] for r in tables if not is_junk(r[0]) and (r[1] or 0) > 0}
    print(f"  -> ตารางที่ไม่ใช่ขยะและมีข้อมูล: {len(live):,} จาก {len(tables):,}")

    cur.execute(Q_COLUMNS)
    cols = [r for r in cur.fetchall() if r[0] in live]
    with open(os.path.join(OUT, "columns.csv"), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["table", "ordinal", "column", "type", "max_length",
                    "precision", "scale", "is_nullable", "is_identity"])
        w.writerows([list(r) for r in cols])
    print(f"  {'columns.csv':<20} {len(cols):>6,} rows")

    dump(cur, "indexes.csv", Q_INDEXES,
         ["table", "index", "type", "is_pk", "is_unique", "columns"])
    dump(cur, "foreign_keys.csv", Q_FK,
         ["fk_name", "from_table", "from_column", "to_table", "to_column"])
    # usage stats ต้องมีสิทธิ์ VIEW SERVER STATE ซึ่ง user นี้ไม่มี — ข้ามได้ ไม่ใช่ตัวหยุดงาน
    try:
        dump(cur, "usage.csv", Q_USAGE,
             ["table", "reads", "writes", "last_seek", "last_scan", "last_update"])
    except pyodbc.Error as e:
        print(f"  usage.csv            ข้าม — {e.args[1][:80]}")
        cur = conn.cursor()
    dump(cur, "views.csv", Q_VIEWS, ["view", "n_cols", "modified"])

    conn.close()
    print("done.")


if __name__ == "__main__":
    sys.exit(main())
