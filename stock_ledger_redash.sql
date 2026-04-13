-- ============================================================
-- 재고수불부 Redash 쿼리 모음
-- DB: Presto / ods_commerce_production
-- 파라미터: {{시작일}}, {{종료일}} (예: 2026-03-23, 2026-03-29)
--
-- [날짜 컬럼 규칙]
-- stock_usage_ro: created_at (Hudi 파티션 키, WHERE 필터용)
--                 updated_at (비즈니스 이벤트 시각, dt 집계 기준)
-- WHERE 절 : DATE(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN DATE('{{시작일}}') AND DATE('{{종료일}}')
-- GROUP BY : DATE(updated_at AT TIME ZONE 'Asia/Seoul') AS dt
--
-- [주요 로직]
-- 기초재고/기말재고: 체인 집합 방식 (LEFT JOIN anti-join)
--   - before_quantity 중 어떤 이벤트의 after_quantity에도 없는 값 → 기초재고
--   - after_quantity 중 어떤 이벤트의 before_quantity에도 없는 값  → 기말재고
--   - 멀티창고 SKU: stock_id별 계산 후 합산
-- 검증식: 기초재고 + 순변동 = 기말재고
-- ============================================================


-- ============================================================
-- [쿼리 1] 재고수불부 (메인, BOM 포함)
-- Redash 파라미터: {{시작일}}, {{종료일}}
-- 선택 필터: {{거래처ID}} (비워두면 전체 조회)
-- ============================================================

WITH

su AS (
    SELECT
        DATE(updated_at AT TIME ZONE 'Asia/Seoul') AS dt,
        sku_id,
        stock_id,
        type,
        before_quantity,
        after_quantity,
        delta,
        updated_at
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(created_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN DATE('{{시작일}}') AND DATE('{{종료일}}')
),

-- 기초재고: before_quantity 중 동일 (dt, sku_id, stock_id) 내 after_quantity에 없는 값
-- → 체인의 시작점 = 당일 첫 재고 수준
opening AS (
    SELECT
        s1.dt,
        s1.sku_id,
        s1.stock_id,
        MIN(s1.before_quantity) AS opening_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt       = s2.dt
        AND s1.sku_id   = s2.sku_id
        AND s1.stock_id = s2.stock_id
        AND s1.before_quantity = s2.after_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

-- 기말재고: after_quantity 중 동일 (dt, sku_id, stock_id) 내 before_quantity에 없는 값
-- → 체인의 끝점 = 당일 마지막 재고 수준
closing AS (
    SELECT
        s1.dt,
        s1.sku_id,
        s1.stock_id,
        MAX(s1.after_quantity) AS closing_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt       = s2.dt
        AND s1.sku_id   = s2.sku_id
        AND s1.stock_id = s2.stock_id
        AND s1.after_quantity = s2.before_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

-- 멀티창고 합산: stock_id별 기초/기말을 (dt, sku_id) 단위로 합산
stock_bounds AS (
    SELECT
        o.dt,
        o.sku_id,
        SUM(o.opening_stock) AS 기초재고,
        SUM(c.closing_stock) AS 기말재고
    FROM opening o
    JOIN closing c
        ON  o.dt       = c.dt
        AND o.sku_id   = c.sku_id
        AND o.stock_id = c.stock_id
    GROUP BY o.dt, o.sku_id
),

-- type별 delta 집계
movement AS (
    SELECT
        dt,
        sku_id,
        SUM(CASE WHEN type = 'INCOMING_COMPLETED'   THEN delta ELSE 0 END) AS 입고수량,
        SUM(CASE WHEN type = 'ADJUSTMENT_COMPLETED' THEN delta ELSE 0 END) AS 조정수량,
        SUM(CASE WHEN type = 'OUTGOING_COMPLETED'   THEN delta ELSE 0 END) AS 출고완료,
        SUM(CASE WHEN type = 'OUTGOING_REQUESTED'   THEN delta ELSE 0 END) AS 출고요청,
        SUM(CASE WHEN type = 'OUTGOING_CANCELLED'   THEN delta ELSE 0 END) AS 출고취소,
        SUM(delta)                                                           AS 순변동
    FROM su
    GROUP BY dt, sku_id
),

-- SKU 마스터 (거래처 포함)
sku_info AS (
    SELECT
        s.id             AS sku_id,
        s.name           AS sku_nm,
        s.sku_code,
        s.composition_type,
        sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg
        ON s.sku_group_id = sg.id
    WHERE s.deleted_at  IS NULL
      AND sg.deleted_at IS NULL
),

-- BOM 유형 분류
-- BOM완제품: bundled_sku_ro.sku_id 에 존재하는 SKU
-- BOM구성요소: bundled_sku_ro.bundled_sku_id 에 존재하는 SKU
bom_type AS (
    SELECT sku_id, 'BOM완제품' AS bom_유형
    FROM ods_commerce_production.bundled_sku_ro
    GROUP BY sku_id
    UNION ALL
    SELECT bundled_sku_id AS sku_id, 'BOM구성요소' AS bom_유형
    FROM ods_commerce_production.bundled_sku_ro
    GROUP BY bundled_sku_id
),

-- BOM 전개 소요수량 (stock_usage_ro OUTGOING_COMPLETED 기준)
-- 완제품 레벨 재고 이동 없이 구성요소 레벨에서만 차감이 발생하는 구조
bom_req_agg AS (
    SELECT
        su.sku_id,
        SUM(ABS(su.delta)) AS BOM전개소요수량
    FROM su
    WHERE su.type = 'OUTGOING_COMPLETED'
      AND su.sku_id IN (SELECT bundled_sku_id FROM ods_commerce_production.bundled_sku_ro)
    GROUP BY su.sku_id
)

SELECT
    m.dt                                        AS 날짜,
    m.sku_id,
    si.sku_nm                                   AS SKU명,
    si.sku_code                                 AS SKU코드,
    si.biz_partner_id                           AS 거래처ID,
    si.composition_type                         AS 구성유형,
    COALESCE(bt.bom_유형, 'SINGLE')             AS BOM유형,
    COALESCE(sb.기초재고, 0)                    AS 기초재고,
    COALESCE(m.입고수량,  0)                    AS 입고수량,
    COALESCE(m.조정수량,  0)                    AS 조정수량,
    COALESCE(m.출고완료,  0)                    AS 출고완료,
    COALESCE(m.출고요청,  0)                    AS 출고요청,
    COALESCE(m.출고취소,  0)                    AS 출고취소,
    COALESCE(m.순변동,    0)                    AS 순변동,
    COALESCE(sb.기말재고, 0)                    AS 기말재고,
    COALESCE(br.BOM전개소요수량, 0)             AS BOM전개소요수량,
    -- 검증 컬럼: 0이 아니면 데이터 이상
    COALESCE(sb.기초재고, 0) + COALESCE(m.순변동, 0)
        - COALESCE(sb.기말재고, 0)             AS 검증_기초+순변동-기말
FROM movement m
LEFT JOIN stock_bounds sb ON m.dt = sb.dt AND m.sku_id = sb.sku_id
LEFT JOIN sku_info     si ON m.sku_id = si.sku_id
LEFT JOIN bom_type     bt ON m.sku_id = bt.sku_id
LEFT JOIN bom_req_agg  br ON m.sku_id = br.sku_id
WHERE 1=1
  -- 거래처 필터 (Redash에서 비워두면 전체 조회)
  AND (
        '{{거래처ID}}' = ''
        OR CAST(si.biz_partner_id AS VARCHAR) = '{{거래처ID}}'
  )
ORDER BY m.dt, si.biz_partner_id, m.sku_id
;


-- ============================================================
-- [쿼리 2] 일별 요약 (전일기말 = 당일기초 완벽 일치)
-- Redash 파라미터: {{시작일}}, {{종료일}}
--
-- [로직]
-- 전체 SKU의 초기재고(처음 등장일 기초재고)를 합산해 기준값으로 사용.
-- 기초재고합계 = 기준값 + 전날까지의 누적 순변동
-- 기말재고합계 = 기준값 + 당일까지의 누적 순변동
-- → 전일기말 = 당일기초 (완벽 연속성 보장)
-- ============================================================

WITH

su AS (
    SELECT
        DATE(updated_at AT TIME ZONE 'Asia/Seoul') AS dt,
        sku_id,
        stock_id,
        type,
        before_quantity,
        after_quantity,
        delta
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(created_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN DATE('{{시작일}}') AND DATE('{{종료일}}')
),

opening AS (
    SELECT s1.dt, s1.sku_id, s1.stock_id, MIN(s1.before_quantity) AS opening_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt = s2.dt AND s1.sku_id = s2.sku_id AND s1.stock_id = s2.stock_id
        AND s1.before_quantity = s2.after_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

closing AS (
    SELECT s1.dt, s1.sku_id, s1.stock_id, MAX(s1.after_quantity) AS closing_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt = s2.dt AND s1.sku_id = s2.sku_id AND s1.stock_id = s2.stock_id
        AND s1.after_quantity = s2.before_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

stock_bounds AS (
    SELECT o.dt, o.sku_id,
        SUM(o.opening_stock) AS 기초재고,
        SUM(c.closing_stock) AS 기말재고
    FROM opening o
    JOIN closing c ON o.dt = c.dt AND o.sku_id = c.sku_id AND o.stock_id = c.stock_id
    GROUP BY o.dt, o.sku_id
),

-- 각 SKU의 초기재고: 기간 내 처음 등장한 날의 기초재고
sku_initial AS (
    SELECT sb.sku_id, sb.기초재고 AS initial_stock
    FROM stock_bounds sb
    INNER JOIN (
        SELECT sku_id, MIN(dt) AS first_dt
        FROM stock_bounds
        GROUP BY sku_id
    ) fi ON sb.sku_id = fi.sku_id AND sb.dt = fi.first_dt
),

-- 전체 SKU 초기재고 합계 (기준값)
total_initial AS (
    SELECT SUM(initial_stock) AS total
    FROM sku_initial
),

-- 날짜별 움직임 집계
movement AS (
    SELECT
        dt,
        COUNT(DISTINCT sku_id)                                               AS 활동SKU수,
        SUM(CASE WHEN type = 'INCOMING_COMPLETED'   THEN delta ELSE 0 END)  AS 입고합계,
        SUM(CASE WHEN type = 'ADJUSTMENT_COMPLETED' THEN delta ELSE 0 END)  AS 조정합계,
        SUM(CASE WHEN type = 'OUTGOING_COMPLETED'   THEN delta ELSE 0 END)  AS 출고완료합계,
        SUM(CASE WHEN type = 'OUTGOING_REQUESTED'   THEN delta ELSE 0 END)  AS 출고요청합계,
        SUM(CASE WHEN type = 'OUTGOING_CANCELLED'   THEN delta ELSE 0 END)  AS 출고취소합계,
        SUM(delta)                                                            AS 순변동합계
    FROM su
    GROUP BY dt
)

SELECT
    m.dt                                                                     AS 날짜,
    m.활동SKU수,
    -- 기초재고합계 = 기준값 + 전날까지 누적 순변동 (ROWS PRECEDING → 현재행 제외)
    ti.total + COALESCE(
        SUM(m.순변동합계) OVER (ORDER BY m.dt ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),
        0
    )                                                                        AS 기초재고합계,
    m.입고합계,
    m.조정합계,
    m.출고완료합계,
    m.출고요청합계,
    m.출고취소합계,
    m.순변동합계,
    -- 기말재고합계 = 기준값 + 당일까지 누적 순변동
    ti.total + SUM(m.순변동합계) OVER (ORDER BY m.dt)                       AS 기말재고합계
FROM movement m
CROSS JOIN total_initial ti
ORDER BY m.dt
;


-- ============================================================
-- [쿼리 3] SKU별 조회 (특정 SKU 상세)
-- Redash 파라미터: {{시작일}}, {{종료일}}, {{sku_id}}
-- ============================================================

WITH

su AS (
    SELECT
        DATE(updated_at AT TIME ZONE 'Asia/Seoul') AS dt,
        sku_id,
        stock_id,
        type,
        before_quantity,
        after_quantity,
        delta,
        updated_at
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(created_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN DATE('{{시작일}}') AND DATE('{{종료일}}')
      AND sku_id = CAST('{{sku_id}}' AS BIGINT)
),

opening AS (
    SELECT s1.dt, s1.sku_id, s1.stock_id, MIN(s1.before_quantity) AS opening_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt = s2.dt AND s1.sku_id = s2.sku_id AND s1.stock_id = s2.stock_id
        AND s1.before_quantity = s2.after_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

closing AS (
    SELECT s1.dt, s1.sku_id, s1.stock_id, MAX(s1.after_quantity) AS closing_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt = s2.dt AND s1.sku_id = s2.sku_id AND s1.stock_id = s2.stock_id
        AND s1.after_quantity = s2.before_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

stock_bounds AS (
    SELECT o.dt, o.sku_id,
        SUM(o.opening_stock) AS 기초재고,
        SUM(c.closing_stock) AS 기말재고
    FROM opening o
    JOIN closing c ON o.dt = c.dt AND o.sku_id = c.sku_id AND o.stock_id = c.stock_id
    GROUP BY o.dt, o.sku_id
),

movement AS (
    SELECT
        dt,
        sku_id,
        SUM(CASE WHEN type = 'INCOMING_COMPLETED'   THEN delta ELSE 0 END) AS 입고수량,
        SUM(CASE WHEN type = 'ADJUSTMENT_COMPLETED' THEN delta ELSE 0 END) AS 조정수량,
        SUM(CASE WHEN type = 'OUTGOING_COMPLETED'   THEN delta ELSE 0 END) AS 출고완료,
        SUM(CASE WHEN type = 'OUTGOING_REQUESTED'   THEN delta ELSE 0 END) AS 출고요청,
        SUM(CASE WHEN type = 'OUTGOING_CANCELLED'   THEN delta ELSE 0 END) AS 출고취소,
        SUM(delta)                                                           AS 순변동
    FROM su
    GROUP BY dt, sku_id
),

sku_info AS (
    SELECT s.id AS sku_id, s.name AS sku_nm, s.sku_code, sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg ON s.sku_group_id = sg.id
    WHERE s.deleted_at IS NULL AND sg.deleted_at IS NULL
)

SELECT
    m.dt                             AS 날짜,
    si.sku_nm                        AS SKU명,
    si.sku_code                      AS SKU코드,
    si.biz_partner_id                AS 거래처ID,
    COALESCE(sb.기초재고, 0)         AS 기초재고,
    COALESCE(m.입고수량,  0)         AS 입고수량,
    COALESCE(m.조정수량,  0)         AS 조정수량,
    COALESCE(m.출고완료,  0)         AS 출고완료,
    COALESCE(m.출고요청,  0)         AS 출고요청,
    COALESCE(m.출고취소,  0)         AS 출고취소,
    COALESCE(m.순변동,    0)         AS 순변동,
    COALESCE(sb.기말재고, 0)         AS 기말재고
FROM movement m
LEFT JOIN stock_bounds sb ON m.dt = sb.dt AND m.sku_id = sb.sku_id
LEFT JOIN sku_info     si ON m.sku_id = si.sku_id
ORDER BY m.dt
;
