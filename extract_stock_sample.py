import prestodb
import pandas as pd
import os

# 접속 설정
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

# ===== 설정값 =====
SCHEMA      = 'ods_commerce_production'
START_DATE  = '2026-03-23'
END_DATE    = '2026-03-29'
SKU_START   = '2025-11-20'
OUTPUT_FILE = './stock_sample.xlsx'
# =================

# ===== 테이블별 쿼리 정의 =====
QUERIES = {

    # 재고 변동 이력
    "stock_usage_ro": f"""
        SELECT
            id,
            updated_at,
            sku_id,
            stock_id,
            ref_id,
            ref_type,
            type,
            before_quantity,
            after_quantity,
            delta
        FROM {SCHEMA}.stock_usage_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 현재 재고 스냅샷
    "stock_ro": f"""
        SELECT
            id,
            sku_id,
            warehouse_id,
            physical_quantity,
            available_quantity,
            reserved_quantity,
            updated_at
        FROM {SCHEMA}.stock_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 입고 헤더
    "incoming_ro": f"""
        SELECT
            id,
            completed_at,
            warehouse_id,
            type,
            status,
            transport_type,
            biz_partner_id,
            ref_type,
            ref_id
        FROM {SCHEMA}.incoming_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          AND status = 'COMPLETED'
          AND date(completed_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 입고 상세
    "incoming_item_ro": f"""
        SELECT
            a.id,
            a.incoming_id,
            a.sku_id,
            a.requested_quantity,
            a.incoming_quantity,
            a.damaged_quantity,
            a.missing_quantity,
            a.sale_type,
            a.ref_type
        FROM {SCHEMA}.incoming_item_ro a
        INNER JOIN (
            SELECT id
            FROM {SCHEMA}.incoming_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
              AND status = 'COMPLETED'
              AND date(completed_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) b ON a.incoming_id = b.id
        WHERE date(a.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 출고 헤더
    "outgoing_ro": f"""
        SELECT
            id,
            status,
            warehouse_id,
            type,
            fulfillment_type,
            method,
            ref_type,
            ref_id,
            biz_partner_id,
            updated_at
        FROM {SCHEMA}.outgoing_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          AND date(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 출고 상세
    "outgoing_item_ro": f"""
        SELECT
            a.id,
            a.outgoing_id,
            a.sku_id,
            a.quantity,
            a.outgoing_quantity,
            a.ref_type,
            a.ref_id,
            a.sale_type,
            a.product_id
        FROM {SCHEMA}.outgoing_item_ro a
        INNER JOIN (
            SELECT id
            FROM {SCHEMA}.outgoing_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
              AND date(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) b ON a.outgoing_id = b.id
        WHERE date(a.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 재고 조정
    "adjustment_ro": f"""
        SELECT
            id,
            warehouse_id,
            sku_id,
            status,
            type,
            reason,
            adjusted_quantity,
            adjusting_quantity,
            updated_at
        FROM {SCHEMA}.adjustment_ro
        WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          AND status = 'COMPLETED'
          AND date(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # SKU 마스터: stock_usage_ro에 존재하는 모든 SKU (출고/조정 포함)
    "sku_ro": f"""
        SELECT
            s.id,
            s.name,
            s.sku_code,
            s.barcode,
            s.status,
            s.type,
            s.composition_type,
            s.sku_group_id,
            s.price_amount,
            s.currency,
            s.country_of_origin,
            s.usage_type,
            s.deleted_at
        FROM {SCHEMA}.sku_ro s
        WHERE date(s.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{SKU_START}') AND date('{END_DATE}')
          AND s.deleted_at IS NULL
          AND s.id IN (
              SELECT DISTINCT sku_id
              FROM {SCHEMA}.stock_usage_ro
              WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
          )
    """,

    # SKU 그룹: stock_usage_ro 기준 SKU의 그룹만
    "sku_group_ro": f"""
        SELECT
            g.id,
            g.biz_partner_id,
            g.code,
            g.code_name,
            g.deleted_at
        FROM {SCHEMA}.sku_group_ro g
        WHERE date(g.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{SKU_START}') AND date('{END_DATE}')
          AND g.deleted_at IS NULL
          AND g.id IN (
              SELECT DISTINCT s.sku_group_id
              FROM {SCHEMA}.sku_ro s
              WHERE date(s.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{SKU_START}') AND date('{END_DATE}')
                AND s.deleted_at IS NULL
                AND s.id IN (
                    SELECT DISTINCT sku_id
                    FROM {SCHEMA}.stock_usage_ro
                    WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
                )
          )
    """,
}

# ===== 실행 및 엑셀 저장 =====
with pd.ExcelWriter(OUTPUT_FILE, engine='openpyxl') as writer:
    for table, sql in QUERIES.items():
        try:
            print(f"[{table}] 쿼리 실행 중...")
            cur.execute(sql)
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description]
            df   = pd.DataFrame(rows, columns=cols)
            df.to_excel(writer, sheet_name=table[:31], index=False)
            print(f"[{table}] {len(df)}행 저장 완료")
        except Exception as e:
            print(f"[{table}] ❌ 실패: {e}")

cur.cancel()
conn.close()
print(f"\n✅ 완료: {OUTPUT_FILE}")
