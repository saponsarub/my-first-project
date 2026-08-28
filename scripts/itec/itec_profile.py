# -*- coding: utf-8 -*-
"""โปรไฟล์ค่าจริงของ view หลักใน ITEC — read-only

ไม่แตะ view ที่มีเลขบัตรเครดิต (ci.creditcard_*, rpt.raw_bank_trans)
    $env:MIS_USER="..."; $env:MIS_PWD="..."; python scripts/itec/itec_profile.py
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
    f"UID={USER};PWD={PWD};TrustServerCertificate=yes;", timeout=120)
cur = cn.cursor()

QUERIES = [
    ("ช่วงวันที่ · fact_sales_itec",
     "SELECT MIN(SalesCrDatetime), MAX(SalesCrDatetime) FROM rpt.fact_sales_itec"),
    ("ช่วงวันที่ · fact_trans_fo",
     "SELECT MIN(DATEPHYSICAL), MAX(DATEPHYSICAL) FROM rpt.fact_trans_fo"),
    ("ช่วงวันที่ · onhandendmonth_itec",
     "SELECT MIN(OnHandAsOf), MAX(OnHandAsOf) FROM rpt.onhandendmonth_itec"),
    ("ช่วงวันที่ · fact_bank_itec",
     "SELECT MIN([TRANS DATE]), MAX([TRANS DATE]) FROM rpt.fact_bank_itec"),
    ("ช่วงเดือน · monthly_item_sale_itec",
     "SELECT MIN(END_MONTH_DATE), MAX(END_MONTH_DATE) FROM ci.monthly_item_sale_itec"),

    ("dim_mem_itec · นับ distinct",
     "SELECT COUNT(*) AS rows_, COUNT(DISTINCT salesid) AS d_salesid, "
     "COUNT(DISTINCT memcode) AS d_memcode, COUNT(DISTINCT crmid) AS d_crmid, "
     "SUM(CASE WHEN memcode IS NULL THEN 1 ELSE 0 END) AS null_memcode, "
     "SUM(CASE WHEN crmid IS NULL THEN 1 ELSE 0 END) AS null_crmid "
     "FROM rpt.dim_mem_itec"),
    ("dim_mem_itec · ตัวอย่างรูปแบบรหัส (mask)",
     "SELECT TOP 5 salesid, salesbranch, LEFT(memcode,3)+'***' AS memcode_pat, "
     "LEFT(crmid,3)+'***' AS crmid_pat, LEN(memcode) AS len_mem, LEN(crmid) AS len_crm "
     "FROM rpt.dim_mem_itec WHERE memcode IS NOT NULL AND crmid IS NOT NULL"),

    ("fact_sales_itec · Status",
     "SELECT Status, COUNT_BIG(*) FROM rpt.fact_sales_itec GROUP BY Status ORDER BY 2 DESC"),

    ("clean_branch · SALE_CHANNEL",
     "SELECT SALE_CHANNEL, COUNT(*) FROM ci.clean_branch GROUP BY SALE_CHANNEL ORDER BY 2 DESC"),
    ("clean_branch · SHOP_BRAND",
     "SELECT TOP 30 SHOP_BRAND, COUNT(*) FROM ci.clean_branch GROUP BY SHOP_BRAND ORDER BY 2 DESC"),
    ("clean_branch · SHOP_TYPE",
     "SELECT TOP 20 SHOP_TYPE, COUNT(*) FROM ci.clean_branch GROUP BY SHOP_TYPE ORDER BY 2 DESC"),
    ("clean_branch · BRANCH_STATUS",
     "SELECT BRANCH_STATUS, COUNT(*) FROM ci.clean_branch GROUP BY BRANCH_STATUS ORDER BY 2 DESC"),
    ("clean_branch · Region_TH",
     "SELECT Region_TH, COUNT(*) FROM ci.clean_branch GROUP BY Region_TH ORDER BY 2 DESC"),

    ("dim_item_itec · Brand ยอดนิยม",
     "SELECT TOP 20 Brand, COUNT(*) FROM rpt.dim_item_itec GROUP BY Brand ORDER BY 2 DESC"),
    ("dim_item_itec · CategoryName ยอดนิยม",
     "SELECT TOP 20 CategoryName, COUNT(*) FROM rpt.dim_item_itec GROUP BY CategoryName ORDER BY 2 DESC"),

    ("clean_item_category_itec · Sale_Type",
     "SELECT Sale_Type, COUNT(*) FROM ci.clean_item_category_itec GROUP BY Sale_Type ORDER BY 2 DESC"),
    ("clean_item_category_itec · Main_Product_Dimension",
     "SELECT TOP 30 Main_Product_Dimension, COUNT(*) FROM ci.clean_item_category_itec "
     "GROUP BY Main_Product_Dimension ORDER BY 2 DESC"),
    ("clean_item_category_itec · Product_Purpose",
     "SELECT TOP 20 Product_Purpose, COUNT(*) FROM ci.clean_item_category_itec "
     "GROUP BY Product_Purpose ORDER BY 2 DESC"),
    ("clean_item_category_itec · Product_Dimension",
     "SELECT TOP 30 Product_Dimension, COUNT(*) FROM ci.clean_item_category_itec "
     "GROUP BY Product_Dimension ORDER BY 2 DESC"),

    ("trn_category_ITEC · ทั้งหมด 44 แถว",
     "SELECT TYPE, PAYMENT_TYPE, INSTALLMENT_TYPE, BANK_NAME FROM ci.trn_category_ITEC"),
    ("trn_category_BANK · ทั้งหมด 38 แถว",
     "SELECT TYPE, PAYMENT_TYPE, INSTALLMENT_TYPE, BANK_NAME FROM ci.trn_category_BANK"),

    ("dim_officer_itec · Status",
     "SELECT Status, COUNT(*) FROM rpt.dim_officer_itec GROUP BY Status ORDER BY 2 DESC"),
    ("dim_branch_itec · BranchType",
     "SELECT TOP 20 BranchType, COUNT(*) FROM rpt.dim_branch_itec GROUP BY BranchType ORDER BY 2 DESC"),
    ("fact_trans_fo · CompanyCode",
     "SELECT TOP 20 CompanyCode, COUNT_BIG(*) FROM rpt.fact_trans_fo GROUP BY CompanyCode ORDER BY 2 DESC"),
    ("fact_trans_fo · Transaction_Type",
     "SELECT TOP 20 Transaction_Type, COUNT_BIG(*) FROM rpt.fact_trans_fo "
     "GROUP BY Transaction_Type ORDER BY 2 DESC"),
]

for title, sql in QUERIES:
    print("\n" + "=" * 76)
    print("##", title)
    t0 = time.time()
    try:
        cur.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print("   " + " | ".join(cols))
        for r in rows[:40]:
            print("   " + " | ".join("NULL" if v is None else str(v)[:45] for v in r))
        if len(rows) > 40:
            print(f"   ... อีก {len(rows)-40} แถว")
        print(f"   [{round(time.time()-t0,2)}s · {len(rows)} แถว]")
    except Exception as e:
        print("   ERROR:", str(e)[:160], f"[{round(time.time()-t0,2)}s]")

cn.close()
