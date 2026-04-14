-- ============================================================
-- 재고수불부 Redash 쿼리 모음
-- DB: Presto / ods_commerce_production
-- 파라미터: {{시작일}}, {{종료일}} (예: 2026-03-23, 2026-03-29)
--
-- [날짜 컬럼 규칙]
-- stock_usage_ro: _at 컬럼은 updated_at 하나뿐 (샘플 데이터 확인 기준)
-- WHERE 절 : DATE(updated_at AT TIME ZONE 'Asia/Seoul') BETWEEN DATE('{{시작일}}') AND DATE('{{종료일}}')
-- dt alias : DATE(updated_at AT TIME ZONE 'Asia/Seoul') AS dt
--
-- [Presto 한글 식별자 규칙]
-- CTE 내부 컬럼명은 영문 사용, 최종 SELECT에서만 한글 alias를 ""로 감쌈
-- 예) AS "기초재고"  /  'BOM완제품' 같은 문자열 리터럴은 그대로 사용 가능
--
-- [주요 로직]
-- 기초재고/기말재고: 체인 집합 방식 (LEFT JOIN anti-join)
--   - before_quantity 중 어떤 이벤트의 after_quantity에도 없는 값 → 기초재고
--   - after_quantity 중 어떤 이벤트의 before_quantity에도 없는 값  → 기말재고
--   - 멀티창고 SKU: stock_id별 계산 후 합산
-- 검증식: 기초재고 + 순변동 = 기말재고
-- ============================================================


-- ============================================================
-- [쿼리 1] 재고수불부 SKU별 상세 (구 쿼리1 + 구 쿼리3 통합)
-- Redash 파라미터: {{조회 기간}} (date range)
-- 선택 필터: {{거래처ID}}, {{sku_id}} (둘 다 비워두면 전체 조회)
--
-- [기초/기말 계산 방식: 누적 방식]
-- 체인셋으로 각 (sku_id, stock_id)별 초기재고 파악 →
-- SKU별 전체 초기재고 합산 → 누적 순변동으로 기초/기말 계산
-- → 멀티창고 환경에서도 전일기말 = 당일기초 연속성 보장
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
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN date '{{조회 기간.start}}' AND date '{{조회 기간.end}}'
),

-- 체인셋: (dt, sku_id, stock_id)별 기초재고 (당일 첫 이벤트 before_quantity)
opening AS (
    SELECT s1.dt, s1.sku_id, s1.stock_id, MIN(s1.before_quantity) AS opening_stock
    FROM su s1
    LEFT JOIN su s2
        ON  s1.dt = s2.dt AND s1.sku_id = s2.sku_id AND s1.stock_id = s2.stock_id
        AND s1.before_quantity = s2.after_quantity
    WHERE s2.sku_id IS NULL
    GROUP BY s1.dt, s1.sku_id, s1.stock_id
),

-- (sku_id, stock_id)별 초기재고: 처음 활동한 날의 체인셋 opening
-- 멀티창고 SKU는 창고별로 각각 초기재고를 구함
per_stock_initial AS (
    SELECT o.sku_id, o.stock_id, o.opening_stock AS initial_balance
    FROM opening o
    INNER JOIN (
        SELECT sku_id, stock_id, MIN(dt) AS first_dt
        FROM opening
        GROUP BY sku_id, stock_id
    ) fi ON o.sku_id = fi.sku_id AND o.stock_id = fi.stock_id AND o.dt = fi.first_dt
),

-- SKU별 전체 초기재고 합계 (모든 창고 합산)
sku_initial_total AS (
    SELECT sku_id, SUM(initial_balance) AS total_initial
    FROM per_stock_initial
    GROUP BY sku_id
),

-- type별 delta 집계 (모든 stock_id 합산)
movement AS (
    SELECT
        dt,
        sku_id,
        SUM(CASE WHEN type = 'INCOMING_COMPLETED'   THEN delta ELSE 0 END) AS incoming,
        SUM(CASE WHEN type = 'ADJUSTMENT_COMPLETED' THEN delta ELSE 0 END) AS adjustment,
        SUM(CASE WHEN type = 'OUTGOING_COMPLETED'   THEN delta ELSE 0 END) AS out_complete,
        SUM(CASE WHEN type = 'OUTGOING_REQUESTED'   THEN delta ELSE 0 END) AS out_request,
        SUM(CASE WHEN type = 'OUTGOING_CANCELLED'   THEN delta ELSE 0 END) AS out_cancel,
        SUM(delta)                                                           AS net_delta
    FROM su
    GROUP BY dt, sku_id
),

-- SKU 마스터 (거래처 포함)
sku_info AS (
    SELECT s.id AS sku_id, s.name AS sku_nm, s.sku_code, s.composition_type, sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg ON s.sku_group_id = sg.id
    WHERE s.deleted_at IS NULL AND sg.deleted_at IS NULL
),

-- BOM 유형 분류
bom_type AS (
    SELECT sku_id, 'BOM완제품' AS bom_type_nm
    FROM ods_commerce_production.bundled_sku_ro GROUP BY sku_id
    UNION ALL
    SELECT bundled_sku_id AS sku_id, 'BOM구성요소' AS bom_type_nm
    FROM ods_commerce_production.bundled_sku_ro GROUP BY bundled_sku_id
),

-- BOM 전개 소요수량
bom_req_agg AS (
    SELECT su.sku_id, SUM(ABS(su.delta)) AS bom_req_qty
    FROM su
    WHERE su.type = 'OUTGOING_COMPLETED'
      AND su.sku_id IN (SELECT bundled_sku_id FROM ods_commerce_production.bundled_sku_ro)
    GROUP BY su.sku_id
)

SELECT
    m.dt                                                                     AS "날짜",
    m.sku_id,
    si.sku_nm                                                                AS "SKU명",
    si.sku_code                                                              AS "SKU코드",
    si.biz_partner_id                                                        AS "거래처ID",
    si.composition_type                                                      AS "구성유형",
    COALESCE(bt.bom_type_nm, 'SINGLE')                                       AS "BOM유형",
    -- 기초재고 = 전체 초기재고 + 전날까지 누적 순변동 (PARTITION BY sku_id → 멀티창고 연속성)
    uit.total_initial + COALESCE(
        SUM(m.net_delta) OVER (
            PARTITION BY m.sku_id
            ORDER BY m.dt
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ), 0
    )                                                                        AS "기초재고",
    COALESCE(m.incoming,     0)                                              AS "입고수량",
    COALESCE(m.adjustment,   0)                                              AS "조정수량",
    COALESCE(m.out_complete, 0)                                              AS "출고완료",
    COALESCE(m.out_request,  0)                                              AS "출고요청",
    COALESCE(m.out_cancel,   0)                                              AS "출고취소",
    COALESCE(m.net_delta,    0)                                              AS "순변동",
    -- 기말재고 = 전체 초기재고 + 당일까지 누적 순변동
    uit.total_initial + SUM(m.net_delta) OVER (
        PARTITION BY m.sku_id
        ORDER BY m.dt
    )                                                                        AS "기말재고",
    COALESCE(br.bom_req_qty, 0)                                              AS "BOM전개소요수량"
FROM movement m
JOIN sku_initial_total uit ON m.sku_id = uit.sku_id
LEFT JOIN sku_info    si ON m.sku_id = si.sku_id
LEFT JOIN bom_type    bt ON m.sku_id = bt.sku_id
LEFT JOIN bom_req_agg br ON m.sku_id = br.sku_id
WHERE (
    '{{거래처ID}}' = ''
    OR CAST(si.biz_partner_id AS VARCHAR) = '{{거래처ID}}'
)
AND (
    '{{sku_id}}' = ''
    OR CAST(m.sku_id AS VARCHAR) = '{{sku_id}}'
)
ORDER BY m.dt, si.biz_partner_id, m.sku_id
;


-- ============================================================
-- [쿼리 2] 일별 요약 (거래처별, 전일기말 = 당일기초 완벽 일치)
-- Redash 파라미터: {{조회 기간}} (date range)
-- 선택 필터: {{거래처ID}} (비워두면 전체 거래처 조회)
--
-- [로직]
-- biz_partner_id별로 전체 SKU 초기재고 합산 → 기준값으로 사용
-- 기초재고합계 = 기준값 + 전날까지 누적 순변동  (PARTITION BY biz_partner_id)
-- 기말재고합계 = 기준값 + 당일까지 누적 순변동  (PARTITION BY biz_partner_id)
-- → 거래처별로 전일기말 = 당일기초 연속성 보장
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
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN date '{{조회 기간.start}}' AND date '{{조회 기간.end}}'
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
        SUM(o.opening_stock) AS opening,
        SUM(c.closing_stock) AS closing
    FROM opening o
    JOIN closing c ON o.dt = c.dt AND o.sku_id = c.sku_id AND o.stock_id = c.stock_id
    GROUP BY o.dt, o.sku_id
),

-- SKU → 거래처 매핑
sku_info AS (
    SELECT s.id AS sku_id, sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg ON s.sku_group_id = sg.id
    WHERE s.deleted_at IS NULL AND sg.deleted_at IS NULL
),

-- 각 SKU의 초기재고 (biz_partner_id 포함)
sku_initial AS (
    SELECT sb.sku_id, sb.opening AS initial_stock, si.biz_partner_id
    FROM stock_bounds sb
    JOIN sku_info si ON sb.sku_id = si.sku_id
    INNER JOIN (
        SELECT sku_id, MIN(dt) AS first_dt
        FROM stock_bounds
        GROUP BY sku_id
    ) fi ON sb.sku_id = fi.sku_id AND sb.dt = fi.first_dt
),

-- 거래처별 전체 초기재고 합계 (기준값)
total_initial AS (
    SELECT biz_partner_id, SUM(initial_stock) AS total
    FROM sku_initial
    GROUP BY biz_partner_id
),

-- 날짜별 + 거래처별 움직임 집계
movement AS (
    SELECT
        su.dt,
        si.biz_partner_id,
        COUNT(DISTINCT su.sku_id)                                                AS active_sku_cnt,
        SUM(CASE WHEN su.type = 'INCOMING_COMPLETED'   THEN su.delta ELSE 0 END) AS incoming,
        SUM(CASE WHEN su.type = 'ADJUSTMENT_COMPLETED' THEN su.delta ELSE 0 END) AS adjustment,
        SUM(CASE WHEN su.type = 'OUTGOING_COMPLETED'   THEN su.delta ELSE 0 END) AS out_complete,
        SUM(CASE WHEN su.type = 'OUTGOING_REQUESTED'   THEN su.delta ELSE 0 END) AS out_request,
        SUM(CASE WHEN su.type = 'OUTGOING_CANCELLED'   THEN su.delta ELSE 0 END) AS out_cancel,
        SUM(su.delta)                                                             AS net_delta
    FROM su
    JOIN sku_info si ON su.sku_id = si.sku_id
    GROUP BY su.dt, si.biz_partner_id
)

SELECT
    m.dt                                                                          AS "날짜",
    m.biz_partner_id                                                              AS "거래처ID",
    m.active_sku_cnt                                                              AS "활동SKU수",
    -- 기초재고합계 = 거래처별 기준값 + 전날까지 누적 순변동
    ti.total + COALESCE(
        SUM(m.net_delta) OVER (
            PARTITION BY m.biz_partner_id
            ORDER BY m.dt
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ), 0
    )                                                                             AS "기초재고합계",
    m.incoming                                                                    AS "입고합계",
    m.adjustment                                                                  AS "조정합계",
    m.out_complete                                                                AS "출고완료합계",
    m.out_request                                                                 AS "출고요청합계",
    m.out_cancel                                                                  AS "출고취소합계",
    m.net_delta                                                                   AS "순변동합계",
    -- 기말재고합계 = 거래처별 기준값 + 당일까지 누적 순변동
    ti.total + SUM(m.net_delta) OVER (
        PARTITION BY m.biz_partner_id
        ORDER BY m.dt
    )                                                                             AS "기말재고합계"
FROM movement m
JOIN total_initial ti ON m.biz_partner_id = ti.biz_partner_id
WHERE (
    '{{거래처ID}}' = ''
    OR CAST(m.biz_partner_id AS VARCHAR) = '{{거래처ID}}'
)
ORDER BY m.biz_partner_id, m.dt
;


-- ============================================================
-- [쿼리 3] BOM 구조 조회
-- 특정 SKU가 속한 BOM 완제품과 전체 구성요소 목록을 보여줌
--
-- [사용법]
-- sku_id: 완제품 또는 구성요소 sku_id 입력
--         → 해당 SKU가 속한 모든 BOM 세트 구조를 출력
-- 조회 기간: 기간 내 실제 출고완료 수량도 함께 표시
--
-- [출력 행 구성]
-- 하나의 BOM 세트당 구성요소 수만큼 행 출력
-- 조회한 sku_id 행은 "★ 조회 SKU" 표시
-- ============================================================

WITH

-- 입력 SKU가 완제품인 경우 → 해당 sku_id가 부모
-- 입력 SKU가 구성요소인 경우 → bundled_sku_ro에서 부모(sku_id) 찾기
parent_ids AS (
    SELECT sku_id AS bom_parent_id
    FROM ods_commerce_production.bundled_sku_ro
    WHERE sku_id = CAST('{{sku_id}}' AS BIGINT)           -- 완제품으로 직접 입력한 경우
    UNION
    SELECT sku_id AS bom_parent_id
    FROM ods_commerce_production.bundled_sku_ro
    WHERE bundled_sku_id = CAST('{{sku_id}}' AS BIGINT)   -- 구성요소로 입력한 경우 → 부모 찾기
),

-- 해당 부모(들)의 전체 구성요소 목록
bom_all AS (
    SELECT
        b.sku_id         AS bom_parent_id,
        b.bundled_sku_id AS component_id,
        b.quantity        AS unit_qty
    FROM ods_commerce_production.bundled_sku_ro b
    JOIN parent_ids p ON b.sku_id = p.bom_parent_id
),

-- 조회 기간 내 구성요소별 실제 출고완료 수량
su AS (
    SELECT sku_id, SUM(ABS(delta)) AS actual_outgoing
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN date '{{조회 기간.start}}' AND date '{{조회 기간.end}}'
      AND type = 'OUTGOING_COMPLETED'
    GROUP BY sku_id
),

-- 완제품(BOM 부모 SKU) 기준 조회기간.end 이전 누적 판매수량
parent_sales AS (
    SELECT sku_id, SUM(ABS(delta)) AS cumul_sales
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul') <= date '{{조회 기간.end}}'
      AND type = 'OUTGOING_COMPLETED'
      AND sku_id IN (SELECT bom_parent_id FROM parent_ids)
    GROUP BY sku_id
),

-- SKU 마스터 (완제품/구성요소 이름 조회용)
sku_info AS (
    SELECT s.id AS sku_id, s.name AS sku_nm, s.sku_code, sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg ON s.sku_group_id = sg.id
    WHERE s.deleted_at IS NULL AND sg.deleted_at IS NULL
)

SELECT
    pi_parent.biz_partner_id                              AS "거래처ID",
    b.bom_parent_id                                       AS "BOM완제품_SKU_ID",
    pi_parent.sku_nm                                      AS "BOM완제품명",
    pi_parent.sku_code                                    AS "BOM완제품코드",
    b.component_id                                        AS "구성요소_SKU_ID",
    pi_comp.sku_nm                                        AS "구성요소명",
    pi_comp.sku_code                                      AS "구성요소코드",
    b.unit_qty                                            AS "단위구성수량",
    COALESCE(ps.cumul_sales, 0)                            AS "완제품누적판매수량(기간종료일기준)",
    COALESCE(su.actual_outgoing, 0)                       AS "기간내출고완료수량",
    CASE
        WHEN b.unit_qty > 0
        THEN COALESCE(su.actual_outgoing, 0) / b.unit_qty
        ELSE 0
    END                                                   AS "완제품판매역산수량",
    CASE
        WHEN b.component_id = CAST('{{sku_id}}' AS BIGINT)
        THEN '★ 조회 SKU'
        ELSE ''
    END                                                   AS "비고"
FROM bom_all b
LEFT JOIN sku_info pi_parent ON b.bom_parent_id = pi_parent.sku_id
LEFT JOIN sku_info pi_comp   ON b.component_id  = pi_comp.sku_id
LEFT JOIN su                 ON b.component_id  = su.sku_id
LEFT JOIN parent_sales ps    ON b.bom_parent_id = ps.sku_id
ORDER BY b.bom_parent_id, b.component_id
;
