-- ============================================================
-- 재고수불부 (Stock Ledger) Query
-- DB: Presto / ods_commerce_production
-- 파티션 파라미터: {{시작일}}, {{종료일}} (예: '2026-03-23', '2026-03-25')
--
-- 테이블 연결 관계:
--   stock_usage_ro.stock_id = stock_ro.id
--   stock_usage_ro.sku_id   = stock_ro.sku_id  (직접 연결 가능)
--   stock_ro.sku_id         = sku_ro.id
--   sku_ro.sku_group_id     = sku_group_ro.id
--
-- stock_usage_ro.type 종류:
--   INCOMING_COMPLETED    : 입고 완료
--   ADJUSTMENT_COMPLETED  : 조정 완료
--   OUTGOING_REQUESTED    : 출고 요청 (재고 예약)
--   OUTGOING_CANCELLED    : 출고 취소 (예약 해제)
--   OUTGOING_COMPLETED    : 출고 완료
-- ============================================================

WITH

-- 1. 날짜별 SKU별 재고 이동 이벤트 (KST 기준)
daily_usage AS (
    SELECT
        CAST(
            date_format(
                at_timezone(
                    from_unixtime(CAST(updated_at AS DOUBLE) / 1000),
                    'Asia/Seoul'
                ),
                '%Y-%m-%d'
            ) AS VARCHAR
        )                                                         AS dt,
        sku_id,
        stock_id,
        type,
        before_quantity,
        after_quantity,
        delta,
        -- 행 번호: 하루 중 첫 번째 / 마지막 이벤트 구분용
        ROW_NUMBER() OVER (
            PARTITION BY
                CAST(
                    date_format(
                        at_timezone(
                            from_unixtime(CAST(updated_at AS DOUBLE) / 1000),
                            'Asia/Seoul'
                        ),
                        '%Y-%m-%d'
                    ) AS VARCHAR
                ),
                sku_id
            ORDER BY updated_at ASC
        ) AS rn_asc,
        ROW_NUMBER() OVER (
            PARTITION BY
                CAST(
                    date_format(
                        at_timezone(
                            from_unixtime(CAST(updated_at AS DOUBLE) / 1000),
                            'Asia/Seoul'
                        ),
                        '%Y-%m-%d'
                    ) AS VARCHAR
                ),
                sku_id
            ORDER BY updated_at DESC
        ) AS rn_desc
    FROM ods_commerce_production.stock_usage_ro
    WHERE dt BETWEEN '{{시작일}}' AND '{{종료일}}'
),

-- 2. 기초재고: 당일 첫 번째 이벤트의 before_quantity
opening_stock AS (
    SELECT
        dt,
        sku_id,
        before_quantity AS opening_qty
    FROM daily_usage
    WHERE rn_asc = 1
),

-- 3. 기말재고: 당일 마지막 이벤트의 after_quantity
closing_stock AS (
    SELECT
        dt,
        sku_id,
        after_quantity AS closing_qty
    FROM daily_usage
    WHERE rn_desc = 1
),

-- 4. type별 delta 합계
movement AS (
    SELECT
        dt,
        sku_id,
        SUM(CASE WHEN type = 'INCOMING_COMPLETED'   THEN delta ELSE 0 END) AS incoming_qty,
        SUM(CASE WHEN type = 'ADJUSTMENT_COMPLETED' THEN delta ELSE 0 END) AS adjustment_qty,
        SUM(CASE WHEN type = 'OUTGOING_REQUESTED'   THEN delta ELSE 0 END) AS outgoing_requested_qty,
        SUM(CASE WHEN type = 'OUTGOING_CANCELLED'   THEN delta ELSE 0 END) AS outgoing_cancelled_qty,
        SUM(delta)                                                           AS net_delta
    FROM daily_usage
    GROUP BY dt, sku_id
),

-- 5. SKU 정보 조인
sku_info AS (
    SELECT
        s.id          AS sku_id,
        s.name        AS sku_nm,
        s.sku_code,
        s.sku_group_id,
        sg.biz_partner_id
    FROM ods_commerce_production.sku_ro       s
    JOIN ods_commerce_production.sku_group_ro sg
      ON s.sku_group_id = sg.id
    WHERE s.dt  = '{{종료일}}'   -- sku_ro 최신 파티션
      AND sg.dt = '{{종료일}}'   -- sku_group_ro 최신 파티션
      AND s.deleted_at IS NULL
      AND sg.deleted_at IS NULL
)

-- 최종 재고수불부
SELECT
    m.dt,
    m.sku_id,
    si.sku_nm,
    si.sku_code,
    si.biz_partner_id,
    o.opening_qty                   AS 기초재고,
    m.incoming_qty                  AS 입고수량,
    m.adjustment_qty                AS 조정수량,
    m.outgoing_requested_qty        AS 출고요청,
    m.outgoing_cancelled_qty        AS 출고취소,
    m.net_delta                     AS 순변동,
    c.closing_qty                   AS 기말재고
FROM movement         m
LEFT JOIN opening_stock  o  ON m.dt = o.dt  AND m.sku_id = o.sku_id
LEFT JOIN closing_stock  c  ON m.dt = c.dt  AND m.sku_id = c.sku_id
LEFT JOIN sku_info        si ON m.sku_id = si.sku_id
ORDER BY m.dt, si.biz_partner_id, m.sku_id
;
