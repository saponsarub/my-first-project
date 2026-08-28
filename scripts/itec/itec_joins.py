# -*- coding: utf-8 -*-
"""ทดสอบเส้นทาง join และ grain ของ view หลัก — read-only · ไม่ดึงค่าที่เป็น PII

    $env:MIS_USER="..."; $env:MIS_PWD="..."; python scripts/itec/itec_joins.py
"""
import os
import sys
import time

import pyodbc

sys.stdout.reconfigure(encoding="utf-8")

SERVER = os.environ.get("MIS_SERVER", "192.168.43.250,18963")
USER = os.environ.get("MIS_USER")
PWD = os.environ.get("MIS_PWD")
DB = os.environ.get("MIS_DB", "_db1_3f9c2a7e-8b41-4d6f-9c25-1a7e5c0d2b8f")
if not USER or not PWD:
    sys.exit('ต้องตั้ง credential ก่อน:  $env:MIS_USER="..."; $env:MIS_PWD="..."')

cn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DB};"
    f"UID={USER};PWD={PWD};TrustServerCertificate=yes;", timeout=180)
cur = cn.cursor()

Q = [
    ("รูปแบบ memcode / crmid (นับอย่างเดียว ไม่ดึงค่า)",
     """SELECT LEN(memcode) AS len_memcode, COUNT_BIG(*) AS n,
               SUM(CASE WHEN memcode LIKE '0%' THEN 1 ELSE 0 END) AS start_zero,
               SUM(CASE WHEN memcode NOT LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS all_digit
        FROM rpt.dim_mem_itec GROUP BY LEN(memcode) ORDER BY 2 DESC"""),
    ("รูปแบบ crmid",
     """SELECT LEN(crmid) AS len_crmid, LEFT(crmid,1) AS first_char, COUNT_BIG(*) AS n
        FROM rpt.dim_mem_itec WHERE crmid IS NOT NULL
        GROUP BY LEN(crmid), LEFT(crmid,1) ORDER BY 3 DESC"""),

    ("grain ของ dim_mem_itec — 1 salesid มีกี่แถว",
     """SELECT n_rows, COUNT_BIG(*) AS n_salesid FROM (
            SELECT salesid, COUNT_BIG(*) AS n_rows
            FROM rpt.dim_mem_itec GROUP BY salesid
        ) t GROUP BY n_rows ORDER BY 2 DESC"""),

    ("grain ของ fact_sales_itec — คีย์คือ SalesId+SalesBranch+ItemId+SerialNo?",
     """SELECT COUNT_BIG(*) AS rows_, COUNT(DISTINCT SalesId) AS d_salesid
        FROM rpt.fact_sales_itec"""),

    ("join · fact_sales_itec -> dim_item_itec",
     """SELECT COUNT_BIG(*) AS sales_rows,
               SUM(CASE WHEN i.ItemId IS NULL THEN 1 ELSE 0 END) AS no_item_match
        FROM (SELECT TOP 500000 ItemId FROM rpt.fact_sales_itec) f
        LEFT JOIN rpt.dim_item_itec i ON i.ItemId = f.ItemId"""),

    ("join · fact_sales_itec -> dim_branch_itec",
     """SELECT COUNT_BIG(*) AS sales_rows,
               SUM(CASE WHEN b.Branch IS NULL THEN 1 ELSE 0 END) AS no_branch_match
        FROM (SELECT TOP 500000 SalesBranch FROM rpt.fact_sales_itec) f
        LEFT JOIN rpt.dim_branch_itec b ON b.Branch = f.SalesBranch"""),

    ("join · fact_sales_itec -> dim_sales_header_itec",
     """SELECT COUNT_BIG(*) AS sales_rows,
               SUM(CASE WHEN h.SalesID IS NULL THEN 1 ELSE 0 END) AS no_header_match
        FROM (SELECT TOP 200000 SalesId, SalesBranch FROM rpt.fact_sales_itec) f
        LEFT JOIN rpt.dim_sales_header_itec h
               ON h.SalesID = f.SalesId AND h.SalesBranch = f.SalesBranch"""),

    ("join · fact_sales_itec -> dim_mem_itec (ระบุตัวลูกค้าได้กี่ %)",
     """SELECT COUNT_BIG(*) AS sales_rows,
               SUM(CASE WHEN m.salesid IS NULL THEN 1 ELSE 0 END) AS no_member_match
        FROM (SELECT TOP 200000 SalesId, SalesBranch FROM rpt.fact_sales_itec) f
        LEFT JOIN (SELECT DISTINCT salesid, salesbranch FROM rpt.dim_mem_itec) m
               ON m.salesid = f.SalesId AND m.salesbranch = f.SalesBranch"""),

    ("join · fact_sales_itec -> dim_officer_itec",
     """SELECT COUNT_BIG(*) AS sales_rows,
               SUM(CASE WHEN o.OfficerID IS NULL THEN 1 ELSE 0 END) AS no_officer_match
        FROM (SELECT TOP 200000 SalesOfficerId FROM rpt.fact_sales_itec) f
        LEFT JOIN rpt.dim_officer_itec o ON o.OfficerID = f.SalesOfficerId"""),

    ("ยอดขายรวมต่อปี (Status=0)",
     """SELECT YEAR(SalesCrDatetime) AS y, COUNT_BIG(*) AS lines_,
               SUM(CAST(SalesQty AS bigint)) AS qty, SUM(SalesAmount) AS amount
        FROM rpt.fact_sales_itec WHERE Status = 0
        GROUP BY YEAR(SalesCrDatetime) ORDER BY 1"""),

    ("Status=1 คืออะไร — เทียบยอด",
     """SELECT Status, COUNT_BIG(*) AS lines_, SUM(CAST(SalesQty AS bigint)) AS qty,
               SUM(SalesAmount) AS amount, MIN(SalesAmount) AS min_amt, MAX(SalesAmount) AS max_amt
        FROM rpt.fact_sales_itec GROUP BY Status"""),

    ("clean_branch vs dim_branch_itec ต่างกันยังไง",
     """SELECT (SELECT COUNT(*) FROM ci.clean_branch) AS clean_rows,
               (SELECT COUNT(*) FROM rpt.dim_branch_itec) AS dim_rows,
               (SELECT COUNT(*) FROM ci.clean_branch c
                  LEFT JOIN rpt.dim_branch_itec d ON d.Branch = c.Branch_ID
                WHERE d.Branch IS NULL) AS clean_not_in_dim"""),
]

for title, sql in Q:
    print("\n" + "=" * 76)
    print("##", title)
    t0 = time.time()
    try:
        cur.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print("   " + " | ".join(cols))
        for r in rows[:25]:
            print("   " + " | ".join("NULL" if v is None else str(v)[:40] for v in r))
        if len(rows) > 25:
            print(f"   ... อีก {len(rows)-25} แถว")
        print(f"   [{round(time.time()-t0,2)}s]")
    except Exception as e:
        print("   ERROR:", str(e)[:170], f"[{round(time.time()-t0,2)}s]")

cn.close()
