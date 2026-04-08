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
SCHEMA     = 'ods_commerce_production'
DATE_FROM  = '20260323'   # 재고 변동 테이블 시작일 (dt 파티션 형식)
DATE_TO    = '20260329'   # 재고 변동 테이블 종료일
SKU_FROM   = '20251120'   # SKU 마스터 테이블 시작일
SKU_TO     = '20260329'   # SKU 마스터 테이블 종료일
OUTPUT_DIR = './stock_sample'
LIMIT      = 0            # 0이면 전체, 느리면 10000 등으로 제한
# =================

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ===== 테이블별 쿼리 정의 =====
QUERIES = {

    # 재고 변동 이력: 입고완료/출고요청/출고취소/조정 delta 기록
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
        WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
    """,

    # 재고 스냅샷: SKU별 실물/가용/예약 재고
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
        WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
    """,

    # 입고 헤더: 완료된 입고 (발주/반품 등 유형 포함)
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
        WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
          AND status = 'COMPLETED'
    """,

    # 입고 상세: SKU별 입고 수량
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
            WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
              AND status = 'COMPLETED'
        ) b ON a.incoming_id = b.id
        WHERE a.dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
    """,

    # 출고 헤더: 출고 (주문/B2B 등 유형 포함)
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
        WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
    """,

    # 출고 상세: SKU별 출고 수량
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
            WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
        ) b ON a.outgoing_id = b.id
        WHERE a.dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
    """,

    # 재고 조정: 실사/손망실/이관 등
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
        WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
          AND status = 'COMPLETED'
    """,

    # SKU 마스터: stock_usage_ro에 등장한 모든 sku_id 기준으로 필터
    "sku_ro": f"""
        SELECT DISTINCT
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
        INNER JOIN (
            SELECT DISTINCT sku_id
            FROM {SCHEMA}.stock_usage_ro
            WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
        ) u ON s.id = u.sku_id
        WHERE s.dt BETWEEN '{SKU_FROM}' AND '{SKU_TO}'
          AND s.deleted_at IS NULL
    """,

    # SKU 그룹: sku_ro에 등장한 sku_group_id 기준으로 필터
    "sku_group_ro": f"""
        SELECT DISTINCT
            sg.id,
            sg.biz_partner_id,
            sg.code,
            sg.code_name,
            sg.deleted_at
        FROM {SCHEMA}.sku_group_ro sg
        INNER JOIN (
            SELECT DISTINCT sku_group_id
            FROM {SCHEMA}.sku_ro s
            INNER JOIN (
                SELECT DISTINCT sku_id
                FROM {SCHEMA}.stock_usage_ro
                WHERE dt BETWEEN '{DATE_FROM}' AND '{DATE_TO}'
            ) u ON s.id = u.sku_id
            WHERE s.dt BETWEEN '{SKU_FROM}' AND '{SKU_TO}'
              AND s.deleted_at IS NULL
        ) s ON sg.id = s.sku_group_id
        WHERE sg.dt BETWEEN '{SKU_FROM}' AND '{SKU_TO}'
          AND sg.deleted_at IS NULL
    """,
}

# ===== 실행 및 CSV 저장 =====
for table, sql in QUERIES.items():
    try:
        print(f"[{table}] 쿼리 실행 중...")
        limited_sql = f"SELECT * FROM ({sql}) t LIMIT {LIMIT}" if LIMIT > 0 else sql
        cur.execute(limited_sql)
        rows = cur.fetchall()
        cols = [d[0] for d in cur.description]
        df   = pd.DataFrame(rows, columns=cols)
        path = os.path.join(OUTPUT_DIR, f"{table}.csv")
        df.to_csv(path, index=False, encoding='utf-8-sig')
        print(f"[{table}] {len(df)}행 → {path}")
    except Exception as e:
        print(f"[{table}] ❌ 실패: {e}")

cur.cancel()
conn.close()
print(f"\n✅ 완료: {OUTPUT_DIR}/")
