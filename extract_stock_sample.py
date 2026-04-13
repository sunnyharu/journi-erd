import prestodb
import pandas as pd

# ===== [셀 1] 접속 설정 =====
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

SCHEMA      = 'ods_commerce_production'
START_DATE  = '2026-03-23'
END_DATE    = '2026-03-29'
SKU_START   = '2025-11-20'
OUTPUT_FILE = './stock_sample.xlsx'

print(f"✅ 접속 완료 | 기간: {START_DATE} ~ {END_DATE}")

# ===== [셀 2] 쿼리 정의 =====
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
            s.sku_id  AS id,
            s.sku_name AS name,
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
        WHERE (
              -- stock_usage_ro에 등장한 SKU: 삭제 여부 무관하게 포함 (재고 이력이 있으면 표시)
              s.sku_id IN (
                  SELECT DISTINCT sku_id
                  FROM {SCHEMA}.stock_usage_ro
                  WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
              )
              -- BOM 완제품 SKU: 삭제되지 않은 것만
              OR (
                  s.deleted_at IS NULL
                  AND s.sku_id IN (
                      SELECT DISTINCT sku_id
                      FROM {SCHEMA}.bundled_sku_ro
                  )
              )
          )
    """,

    # 배송 헤더: 기간 내 outgoing_ro와 연결된 배송
    "delivery_ro": f"""
        SELECT
            d.id,
            d.created_at,
            d.updated_at,
            d.status,
            d.type,
            d.method,
            d.region,
            d.biz_partner_id,
            d.warehouse_id,
            d.order_id,
            d.ref_id,
            d.ref_type,
            d.outgoing_id,
            d.started_at,
            d.completed_at,
            d.receiver_country
        FROM {SCHEMA}.delivery_ro d
        INNER JOIN (
            SELECT id
            FROM {SCHEMA}.outgoing_ro
            WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) og ON d.outgoing_id = og.id
        WHERE date(d.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 배송 상세: delivery_ro 기준
    "delivery_item_ro": f"""
        SELECT
            di.id,
            di.delivery_id,
            di.sku_id,
            di.quantity,
            di.product_id,
            di.ref_id,
            di.ref_type,
            json_extract_scalar(di.item_info, '$.name') AS item_name,
            json_extract_scalar(di.item_info, '$.optionName') AS option_name
        FROM {SCHEMA}.delivery_item_ro di
        INNER JOIN (
            SELECT d.id
            FROM {SCHEMA}.delivery_ro d
            INNER JOIN (
                SELECT id
                FROM {SCHEMA}.outgoing_ro
                WHERE date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
            ) og ON d.outgoing_id = og.id
            WHERE date(d.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) d ON di.delivery_id = d.id
        WHERE date(di.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 주문 묶음: outgoing_ro.ref_id (ref_type='ORDER_BUNDLE')
    "order_bundle_ro": f"""
        SELECT
            ob.id,
            ob.order_id,
            ob.biz_partner_id,
            ob.shipping_warehouse_id,
            ob.created_at,
            ob.updated_at,
            ob.receiver_country,
            ob.receiving_type,
            ob.delivery_fee,
            ob.base_currency_delivery_fee,
            ob.bundle_delivery_group_id,
            ob.delivery_fee_currency
        FROM {SCHEMA}.order_bundle_ro ob
        INNER JOIN (
            SELECT DISTINCT CAST(ref_id AS BIGINT) AS ref_id
            FROM {SCHEMA}.outgoing_ro
            WHERE ref_type = 'ORDER_BUNDLE'
              AND date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
        ) og ON ob.id = og.ref_id
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{START_DATE}')) AND date_add('day', 1, date('{END_DATE}'))
          AND date(ob.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # 주문 헤더: order_bundle_ro.order_id 기준
    "orders_ro": f"""
        SELECT
            o.id,
            o.created_at,
            o.updated_at,
            o.completed_at,
            o.status,
            o.payment_amount,
            o.payment_currency,
            o.base_currency_payment_amount,
            o.exchange_rates,
            o.base_currency,
            o.device,
            o.user_id
        FROM {SCHEMA}.orders_ro o
        INNER JOIN (
            SELECT DISTINCT ob.order_id
            FROM {SCHEMA}.order_bundle_ro ob
            INNER JOIN (
                SELECT DISTINCT CAST(ref_id AS BIGINT) AS ref_id
                FROM {SCHEMA}.outgoing_ro
                WHERE ref_type = 'ORDER_BUNDLE'
                  AND date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
            ) og ON ob.id = og.ref_id
        ) ob ON o.id = ob.order_id
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{START_DATE}')) AND date_add('day', 1, date('{END_DATE}'))
    """,

    # 주문 라인: order_bundle_ro 기준 (sku_id, 수량, 금액)
    "order_line_ro": f"""
        SELECT
            ol.id,
            ol.order_bundle_id,
            ol.order_product_id,
            ol.product_item_id,
            ol.sku_id,
            ol.quantity,
            ol.amount,
            ol.base_currency_amount,
            ol.base_currency,
            ol.option_name,
            ol.product_item_type,
            ol.created_at,
            ol.updated_at
        FROM {SCHEMA}.order_line_ro ol
        INNER JOIN (
            SELECT DISTINCT ob.id
            FROM {SCHEMA}.order_bundle_ro ob
            INNER JOIN (
                SELECT DISTINCT CAST(ref_id AS BIGINT) AS ref_id
                FROM {SCHEMA}.outgoing_ro
                WHERE ref_type = 'ORDER_BUNDLE'
                  AND date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
            ) og ON ob.id = og.ref_id
        ) ob ON ol.order_bundle_id = ob.id
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{START_DATE}')) AND date_add('day', 1, date('{END_DATE}'))
          AND date(ol.created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date('{START_DATE}') AND date('{END_DATE}')
    """,

    # BOM 구성: 완제품 SKU → 구성요소 SKU 매핑
    "bundled_sku_ro": f"""
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

print(f"✅ 쿼리 정의 완료 | 총 {len(QUERIES)}개 테이블")

# ===== [셀 3] 실행 및 엑셀 저장 =====
with pd.ExcelWriter(OUTPUT_FILE, engine='openpyxl') as writer:
    for table, sql in QUERIES.items():
        try:
            print(f"[{table}] 쿼리 실행 중...")
            cur.execute(sql)
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description]
            df   = pd.DataFrame(rows, columns=cols)
            df.to_excel(writer, sheet_name=table[:31], index=False)
            print(f"[{table}] {len(df):,}행 저장 완료")
        except Exception as e:
            print(f"[{table}] ❌ 실패: {e}")

cur.cancel()
conn.close()
print(f"\n✅ 완료: {OUTPUT_FILE}")
