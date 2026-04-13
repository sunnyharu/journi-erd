import prestodb

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
SKU_START  = '2025-11-20'

COUNTS = {

    "stock_usage_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.stock_usage_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "stock_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.stock_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "incoming_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.incoming_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          AND status = 'COMPLETED'
          AND date(completed_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "incoming_item_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.incoming_item_ro a
        INNER JOIN (
            SELECT id FROM {SCHEMA}.incoming_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
              AND status = 'COMPLETED'
              AND date(completed_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) b ON a.incoming_id = b.id
        WHERE date(a.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "outgoing_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.outgoing_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          AND date(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "outgoing_item_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.outgoing_item_ro a
        INNER JOIN (
            SELECT id FROM {SCHEMA}.outgoing_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
              AND date(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) b ON a.outgoing_id = b.id
        WHERE date(a.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "adjustment_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.adjustment_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          AND status = 'COMPLETED'
          AND date(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "sku_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.sku_ro s
        WHERE date(s.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{SKU_START}') AND date('{END_DATE}')
          AND s.deleted_at IS NULL
          AND s.id IN (
              SELECT DISTINCT sku_id FROM {SCHEMA}.stock_usage_ro
              WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          )
    """,

    "delivery_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.delivery_ro d
        INNER JOIN (
            SELECT id FROM {SCHEMA}.outgoing_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) og ON d.outgoing_id = og.id
        WHERE date(d.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "delivery_item_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.delivery_item_ro di
        INNER JOIN (
            SELECT d.id FROM {SCHEMA}.delivery_ro d
            INNER JOIN (
                SELECT id FROM {SCHEMA}.outgoing_ro
                WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
            ) og ON d.outgoing_id = og.id
            WHERE date(d.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) d ON di.delivery_id = d.id
        WHERE date(di.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "order_bundle_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.order_bundle_ro ob
        INNER JOIN (
            SELECT DISTINCT CAST(ref_id AS BIGINT) AS ref_id FROM {SCHEMA}.outgoing_ro
            WHERE ref_type = 'ORDER_BUNDLE'
              AND date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) og ON ob.id = og.ref_id
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{START_DATE}')) AND date_add('day', 1, date('{END_DATE}'))
          AND date(ob.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "orders_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.orders_ro o
        INNER JOIN (
            SELECT DISTINCT ob.order_id FROM {SCHEMA}.order_bundle_ro ob
            INNER JOIN (
                SELECT DISTINCT CAST(ref_id AS BIGINT) AS ref_id FROM {SCHEMA}.outgoing_ro
                WHERE ref_type = 'ORDER_BUNDLE'
                  AND date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
            ) og ON ob.id = og.ref_id
        ) ob ON o.id = ob.order_id
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{START_DATE}')) AND date_add('day', 1, date('{END_DATE}'))
    """,

    "order_line_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.order_line_ro ol
        INNER JOIN (
            SELECT DISTINCT ob.id FROM {SCHEMA}.order_bundle_ro ob
            INNER JOIN (
                SELECT DISTINCT CAST(ref_id AS BIGINT) AS ref_id FROM {SCHEMA}.outgoing_ro
                WHERE ref_type = 'ORDER_BUNDLE'
                  AND date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
            ) og ON ob.id = og.ref_id
        ) ob ON ol.order_bundle_id = ob.id
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{START_DATE}')) AND date_add('day', 1, date('{END_DATE}'))
          AND date(ol.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    "bundled_sku_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.bundled_sku_ro b
        WHERE b.sku_id IN (
            SELECT DISTINCT sku_id FROM {SCHEMA}.stock_usage_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        )
           OR b.bundled_sku_id IN (
            SELECT DISTINCT sku_id FROM {SCHEMA}.stock_usage_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        )
    """,

    "sku_group_ro": f"""
        SELECT COUNT(*) FROM {SCHEMA}.sku_group_ro g
        WHERE date(g.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{SKU_START}') AND date('{END_DATE}')
          AND g.deleted_at IS NULL
          AND g.id IN (
              SELECT DISTINCT s.sku_group_id FROM {SCHEMA}.sku_ro s
              WHERE date(s.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{SKU_START}') AND date('{END_DATE}')
                AND s.deleted_at IS NULL
                AND s.id IN (
                    SELECT DISTINCT sku_id FROM {SCHEMA}.stock_usage_ro
                    WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
                )
          )
    """,
}

print(f"\n{'='*45}")
print(f"  행 수 확인 ({START_DATE} ~ {END_DATE})")
print(f"{'='*45}")
print(f"{'테이블':<22} {'행 수':>10}")
print(f"{'-'*45}")

total_ok = 0
errors = []
for table, sql in COUNTS.items():
    try:
        cur.execute(sql)
        count = cur.fetchone()[0]
        print(f"{table:<22} {count:>10,}")
        total_ok += 1
    except Exception as e:
        print(f"{table:<22} {'❌ 실패':>10}  ({e})")
        errors.append(table)

print(f"{'='*45}")
print(f"총 {total_ok}개 테이블 조회 완료" + (f", {len(errors)}개 실패: {errors}" if errors else ""))

cur.cancel()
conn.close()
