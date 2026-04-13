import prestodb
import pandas as pd

conn = prestodb.dbapi.connect(
    host='presto-adhoc.ka.io',
    port=8443,
    user='journi-y222',
    catalog='hadoop_kent',
    schema='ods_commerce_production',
    http_scheme='https',
    auth=prestodb.auth.BasicAuthentication("", ""),
)
cur = conn.cursor()

SCHEMA     = 'ods_commerce_production'
START_DATE = '2026-03-23'
END_DATE   = '2026-03-29'
INPUT_FILE = './stock_sample_v3.xlsx'
OUTPUT_FILE = './stock_sample_v3.xlsx'

sql = f"""
    SELECT
        b.id,
        b.sku_id,
        b.bundled_sku_id,
        b.quantity
    FROM {SCHEMA}.bundled_sku_ro b
    WHERE b.sku_id IN (
        SELECT DISTINCT sku_id
        FROM {SCHEMA}.stock_usage_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    )
       OR b.bundled_sku_id IN (
        SELECT DISTINCT sku_id
        FROM {SCHEMA}.stock_usage_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    )
"""

print("[bundled_sku_ro] 쿼리 실행 중...")
cur.execute(sql)
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
df = pd.DataFrame(rows, columns=cols)
print(f"[bundled_sku_ro] {len(df):,}행 조회 완료")

# 기존 stock_sample_v3.xlsx에 bundled_sku_ro 시트 추가
from openpyxl import load_workbook
book = load_workbook(INPUT_FILE)

with pd.ExcelWriter(OUTPUT_FILE, engine='openpyxl') as writer:
    writer.book = book
    writer.sheets = {ws.title: ws for ws in book.worksheets}
    if 'bundled_sku_ro' in writer.sheets:
        del writer.book['bundled_sku_ro']
        writer.sheets.pop('bundled_sku_ro')
    df.to_excel(writer, sheet_name='bundled_sku_ro', index=False)

print(f"✅ 저장 완료: {OUTPUT_FILE} (bundled_sku_ro 시트 추가/갱신)")

cur.cancel()
conn.close()
