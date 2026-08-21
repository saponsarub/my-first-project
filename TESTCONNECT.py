import pyodbc
import pandas as pd
from sqlalchemy import create_engine
server = "192.168.43.250,18963"
#atabase = ""
username = "mis_dtsci_s_sapon"
password = "Joeyboy2541#"

conn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={server};"
  # f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "TrustServerCertificate=yes;"
)

print("Connected!")
query = """
SELECT TOP (1000)
    *
FROM rpt.dim_item_itec
"""

df = pd.read_sql(query, conn)
display(df.head(10))

print(df)