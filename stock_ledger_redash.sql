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

-- [stock_ro 역산 방식] SKU별 기준값 계산
-- stock_ro현재 - 종료일이후변동 - 기간내변동 = 조회시작일 직전 SKU별 재고
-- → 멀티창고 합산, 움직임 없는 SKU도 포함

stock_ro_total AS (
    SELECT sku_id, SUM(physical_quantity) AS current_total
    FROM ods_commerce_production.stock_ro
    GROUP BY sku_id
),

post_period AS (
    SELECT sku_id, SUM(delta) AS post_delta
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul') > date '{{조회 기간.end}}'
    GROUP BY sku_id
),

period_net AS (
    SELECT sku_id, SUM(net_delta) AS period_total_delta
    FROM movement
    GROUP BY sku_id
),

sku_initial_total AS (
    SELECT
        srt.sku_id,
        srt.current_total
            - COALESCE(pp.post_delta, 0)
            - COALESCE(pn.period_total_delta, 0) AS total_initial
    FROM stock_ro_total srt
    LEFT JOIN post_period pp ON srt.sku_id = pp.sku_id
    LEFT JOIN period_net  pn ON srt.sku_id = pn.sku_id
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

-- SKU → 거래처 매핑
sku_info AS (
    SELECT s.id AS sku_id, sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg ON s.sku_group_id = sg.id
    WHERE s.deleted_at IS NULL AND sg.deleted_at IS NULL
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
),

-- [stock_ro 역산 방식] 거래처별 기준값 계산
-- 목적: 움직임이 없는 SKU 포함 전체 파트너 재고를 기준값으로 사용
--
-- stock_ro = 현재 시점 전체 재고 스냅샷 (움직임 없는 SKU 포함)
-- post_period = 조회종료일 이후 변동 (역산 대상)
-- period_net  = 조회기간 내 전체 변동 (역산 대상)
--
-- total_initial = stock_ro현재 - 종료일이후변동 - 기간내변동
--              = 조회시작일 직전 파트너 전체 재고
-- → 기말재고합계(마지막날) = total_initial + 기간전체변동 = 종료일 기준 파트너 전체 재고

stock_ro_total AS (
    SELECT si.biz_partner_id, SUM(sr.physical_quantity) AS current_total
    FROM ods_commerce_production.stock_ro sr
    JOIN sku_info si ON sr.sku_id = si.sku_id
    GROUP BY si.biz_partner_id
),

-- 조회종료일 이후 발생한 변동 (stock_ro에서 역산)
post_period AS (
    SELECT si.biz_partner_id, SUM(su2.delta) AS post_delta
    FROM ods_commerce_production.stock_usage_ro su2
    JOIN sku_info si ON su2.sku_id = si.sku_id
    WHERE DATE(su2.updated_at AT TIME ZONE 'Asia/Seoul') > date '{{조회 기간.end}}'
    GROUP BY si.biz_partner_id
),

-- 조회기간 내 전체 순변동 합계
period_net AS (
    SELECT biz_partner_id, SUM(net_delta) AS period_total_delta
    FROM movement
    GROUP BY biz_partner_id
),

-- 기준값: 조회시작일 직전 파트너 전체 재고
total_initial AS (
    SELECT
        srt.biz_partner_id,
        srt.current_total
            - COALESCE(pp.post_delta, 0)
            - COALESCE(pn.period_total_delta, 0) AS total
    FROM stock_ro_total srt
    LEFT JOIN post_period pp ON srt.biz_partner_id = pp.biz_partner_id
    LEFT JOIN period_net  pn ON srt.biz_partner_id = pn.biz_partner_id
)

SELECT
    m.dt                                                                          AS "날짜",
    m.biz_partner_id                                                              AS "거래처ID",
    m.active_sku_cnt                                                              AS "활동SKU수",
    -- 기초재고합계 = 기준값(조회시작일직전전체재고) + 전날까지 누적 순변동
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
-- order_line_ro 기준: status = 'COMPLETED'(주문완료), deleted_at IS NULL
parent_sales AS (
    SELECT sku_id, SUM(quantity) AS cumul_sales
    FROM ods_commerce_production.order_line_ro
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul') <= date '{{조회 기간.end}}'
      AND status = 'COMPLETED'
      AND deleted_at IS NULL
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


-- ============================================================
-- [쿼리 4] 재고수불부 이벤트 상세 (운영부서 요청 포맷)
-- 각 재고 이벤트를 row 단위로 출력 (일별 집계 아님)
-- Redash 파라미터: {{조회 기간}} (date range)
-- 선택 필터: {{거래처ID}}, {{sku_id}}
--
-- [구분 매핑 기준 - ref_type 실제값 확인 후 보완 필요]
-- INCOMING_COMPLETED + ref_type=CLAIM       → 입고 / 반품입고
-- INCOMING_COMPLETED + ref_type=TRANSFER    → 이동 / 이동(입고)
-- INCOMING_COMPLETED + 기타                 → 입고 / 구매입고
-- OUTGOING_COMPLETED + ref_type=TRANSFER    → 이동 / 이동(출고)
-- OUTGOING_COMPLETED + ref_type=CLAIM       → 출고 / 반출
-- OUTGOING_COMPLETED + 기타                 → 출고 / 판매출고
-- ADJUSTMENT_COMPLETED + delta > 0          → 조정 / 재고조정(플러스)
-- ADJUSTMENT_COMPLETED + delta < 0          → 조정 / 재고조정(마이너스)
--
-- [미구현 항목 - 운영 수동 입력 필요]
-- 상세구분2 불량/CS 구분: stock_usage_ro에 품질 구분 없음
-- 출발지/도착지 이름: warehouse_id → 창고명 매핑 테이블 미확인
-- 이동 체번(TR): ref_id 기반 생성 (운영팀 체번 포맷과 다를 수 있음)
-- ============================================================

WITH

su AS (
    SELECT
        DATE(updated_at AT TIME ZONE 'Asia/Seoul') AS dt,
        id,
        sku_id,
        stock_id,
        type,
        ref_id,
        ref_type,
        before_quantity,
        after_quantity,
        delta
    FROM ods_commerce_production.stock_usage_ro
    WHERE DATE(updated_at AT TIME ZONE 'Asia/Seoul')
          BETWEEN date '{{조회 기간.start}}' AND date '{{조회 기간.end}}'
      AND type IN ('INCOMING_COMPLETED', 'OUTGOING_COMPLETED', 'ADJUSTMENT_COMPLETED')
),

sku_info AS (
    SELECT
        s.id          AS sku_id,
        s.name        AS sku_nm,
        s.sku_code,
        s.barcode,
        s.price_amount,
        s.currency,
        sg.biz_partner_id
    FROM ods_commerce_production.sku_ro s
    JOIN ods_commerce_production.sku_group_ro sg ON s.sku_group_id = sg.id
    WHERE s.deleted_at IS NULL AND sg.deleted_at IS NULL
),

-- stock_id → warehouse_id 매핑 (창고명은 별도 테이블 확인 필요)
stock_wh AS (
    SELECT id AS stock_id, warehouse_id
    FROM ods_commerce_production.stock_ro
)

SELECT
    su.dt                                                                 AS "날짜",
    si.barcode                                                            AS "SKU(KE발급바코드)",
    si.sku_nm                                                             AS "품명",
    si.biz_partner_id                                                     AS "거래처ID",

    -- 구분(유형)
    CASE
        WHEN su.type = 'ADJUSTMENT_COMPLETED'                             THEN '조정'
        WHEN su.ref_type = 'TRANSFER'                                     THEN '이동'
        WHEN su.type = 'INCOMING_COMPLETED'                               THEN '입고'
        WHEN su.type = 'OUTGOING_COMPLETED'                               THEN '출고'
    END                                                                   AS "구분(유형)",

    -- 상세구분1
    CASE
        WHEN su.type = 'ADJUSTMENT_COMPLETED' AND su.delta >= 0           THEN '재고조정(플러스)'
        WHEN su.type = 'ADJUSTMENT_COMPLETED' AND su.delta < 0            THEN '재고조정(마이너스)'
        WHEN su.type = 'INCOMING_COMPLETED'  AND su.ref_type = 'TRANSFER' THEN '이동(입고)'
        WHEN su.type = 'INCOMING_COMPLETED'  AND su.ref_type = 'CLAIM'    THEN '반품입고'
        WHEN su.type = 'INCOMING_COMPLETED'                               THEN '구매입고'
        WHEN su.type = 'OUTGOING_COMPLETED'  AND su.ref_type = 'TRANSFER' THEN '이동(출고)'
        WHEN su.type = 'OUTGOING_COMPLETED'  AND su.ref_type = 'CLAIM'    THEN '반출'
        WHEN su.type = 'OUTGOING_COMPLETED'                               THEN '판매출고'
    END                                                                   AS "상세구분1",

    -- 상세구분2 (불량/CS 자동구분 불가 → 기본 가용, 이동/조정은 별도 표기)
    CASE
        WHEN su.type = 'ADJUSTMENT_COMPLETED' AND su.delta >= 0           THEN '재고조정(플러스)'
        WHEN su.type = 'ADJUSTMENT_COMPLETED' AND su.delta < 0            THEN '재고조정(마이너스)'
        WHEN su.type = 'INCOMING_COMPLETED'  AND su.ref_type = 'TRANSFER' THEN '이동(입고)'
        WHEN su.type = 'OUTGOING_COMPLETED'  AND su.ref_type = 'TRANSFER' THEN '이동(출고)'
        ELSE '가용'
    END                                                                   AS "상세구분2",

    su.delta                                                              AS "수량",

    -- 관리창고: warehouse_id (창고명 매핑 테이블 확인 후 JOIN 추가 필요)
    sw.warehouse_id                                                       AS "관리창고(warehouse_id)",

    -- 이동 체번: TRANSFER 거래 식별용 (TR+YYMMDD+ref_id 조합)
    CASE
        WHEN su.ref_type = 'TRANSFER'
        THEN 'TR' || DATE_FORMAT(su.dt, '%y%m%d') || '-' || CAST(su.ref_id AS VARCHAR)
    END                                                                   AS "이동입출고체번",

    -- 단가/금액: sku_ro.price_amount 기준 (실매입가는 incoming_item_ro.purchase_price 참고)
    si.price_amount                                                       AS "단가(VAT별도)",
    si.price_amount * ABS(su.delta)                                       AS "공급가액",
    ROUND(si.price_amount * ABS(su.delta) * 0.1)                         AS "VAT(부가세)",
    ROUND(si.price_amount * ABS(su.delta) * 1.1)                         AS "공급대가",

    su.before_quantity                                                    AS "변동전수량",
    su.after_quantity                                                     AS "변동후수량",
    su.type                                                               AS "원본type",
    su.ref_type                                                           AS "원본ref_type",
    su.ref_id                                                             AS "원본ref_id"

FROM su
LEFT JOIN sku_info si ON su.sku_id = si.sku_id
LEFT JOIN stock_wh sw ON su.stock_id = sw.stock_id
WHERE (
    '{{거래처ID}}' = ''
    OR CAST(si.biz_partner_id AS VARCHAR) = '{{거래처ID}}'
)
AND (
    '{{sku_id}}' = ''
    OR CAST(su.sku_id AS VARCHAR) = '{{sku_id}}'
)
ORDER BY su.dt, si.biz_partner_id, su.sku_id, su.id
;
