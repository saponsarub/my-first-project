import pyodbc
import pandas as pd
server = "43.254.133.123"
database = "HPCOM7"
username = "sapon.s"
password = "8@5tE26#"

conn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "TrustServerCertificate=yes;"
)

print("Connected!")
query = """
SELECT TOP (1000)
    *
FROM [HPCOM7].[dbo].[CUSTOMER_CARD]
"""

df = pd.read_sql(query, conn)

print(df)