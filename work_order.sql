-- ============================================================
-- 작업지시서 다운로드 쿼리 (Work Order Download)
-- DB: Presto
--
-- 테이블 매핑 (가이드 → 실제):
--   delivery        → delivery_ro
--   delivery_item   → delivery_item_ro
--   sku             → sku_ro
--   bom_component   → bundled_sku_ro
--     bom_component.sku_id           = bundled_sku_ro.sku_id          (완제품)
--     bom_component.component_sku_id = bundled_sku_ro.bundled_sku_id  (구성요소)
--     bom_component.quantity         = bundled_sku_ro.quantity
--
-- ERD 기준 실제 컬럼 (dt 없음):
--   delivery_ro      : id, biz_partner_id, warehouse_id, order_id,
--                      status, type, created_at, started_at, completed_at,
--                      outgoing_id, log_date
--   delivery_item_ro : id, delivery_id, sku_id, quantity, product_id,
--                      item_info(json), log_date
--   sku_ro           : id, sku_code, name, barcode, manufacturer_id,
--                      composition_type(SINGLE/BOM), deleted_at
--   bundled_sku_ro   : id, sku_id, bundled_sku_id, quantity
--
-- 날짜 기준 옵션 ({{날짜기준}} 자리에 컬럼명 입력):
--   started_at   : 배송 시작일 (기본값 권장)
--   completed_at : 배송 완료일
--   created_at   : 배송 생성일
--
-- 파라미터:
--   {{시작일}}          예: '2026-03-23'
--   {{종료일}}          예: '2026-03-29'
--   {{biz_partner_id}}  예: 1758779013868
--   {{warehouse_id}}    예: 286184492824640  (라이온즈 등 창고 고정 시)
--   {{날짜기준}}         started_at / completed_at / created_at
--
-- BOM 판별:
--   완제품: sku_ro.composition_type = 'BOM'
--   구성요소: bundled_sku_ro.bundled_sku_id 에 존재하는 sku
-- ============================================================


-- ============================================================
-- Sheet 1. 출고수량
-- BOM 완제품 또는 구성요소인 SKU의 전체 출고 수량 집계
-- ============================================================
SELECT
    d.biz_partner_id,
    d.warehouse_id,
    s.manufacturer_id,
    di.product_id,
    s.name              AS sku_name,
    s.sku_code,
    s.barcode,
    s.id                AS sku_id,
    s.composition_type,
    SUM(di.quantity)    AS quantity
FROM delivery_ro d
JOIN delivery_item_ro di
    ON di.delivery_id = d.id
JOIN sku_ro s
    ON s.id = di.sku_id
   AND s.deleted_at IS NULL
WHERE d.biz_partner_id = {{biz_partner_id}}
  -- AND d.warehouse_id = {{warehouse_id}}   -- 라이온즈 등 창고 고정 시 활성화
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
      BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND (
      s.composition_type = 'BOM'
      OR s.id IN (
          SELECT DISTINCT bundled_sku_id
          FROM bundled_sku_ro
      )
  )
GROUP BY
    d.biz_partner_id, d.warehouse_id, s.manufacturer_id,
    di.product_id, s.name, s.sku_code, s.barcode, s.id, s.composition_type
ORDER BY s.name
;


-- ============================================================
-- Sheet 2. 이관지시서
-- BOM 구성요소별 총 필요 수량 (완제품 전개분 + 직접 포함분 합산)
-- ============================================================
SELECT
    sku_code,
    sku_name,
    barcode,
    sku_id,
    SUM(quantity) AS quantity
FROM (

    -- 경로 A: BOM 완제품 하위의 구성요소 수량 전개
    --         (완제품 출고 수량 × bundled_sku_ro.quantity)
    SELECT
        cs.sku_code,
        cs.name         AS sku_name,
        cs.barcode,
        cs.id           AS sku_id,
        SUM(di.quantity * bs.quantity) AS quantity
    FROM delivery_ro d
    JOIN delivery_item_ro di
        ON di.delivery_id = d.id
    JOIN sku_ro s
        ON s.id = di.sku_id
       AND s.deleted_at IS NULL
       AND s.composition_type = 'BOM'
    JOIN bundled_sku_ro bs
        ON bs.sku_id = s.id
    JOIN sku_ro cs
        ON cs.id = bs.bundled_sku_id
       AND cs.deleted_at IS NULL
    WHERE d.biz_partner_id = {{biz_partner_id}}
      -- AND d.warehouse_id = {{warehouse_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
          BETWEEN date('{{시작일}}') AND date('{{종료일}}')
    GROUP BY cs.id, cs.sku_code, cs.name, cs.barcode

    UNION ALL

    -- 경로 B: 구성요소 SKU 자체가 delivery_item에 직접 포함된 경우
    SELECT
        s.sku_code,
        s.name          AS sku_name,
        s.barcode,
        s.id            AS sku_id,
        SUM(di.quantity) AS quantity
    FROM delivery_ro d
    JOIN delivery_item_ro di
        ON di.delivery_id = d.id
    JOIN sku_ro s
        ON s.id = di.sku_id
       AND s.deleted_at IS NULL
    WHERE d.biz_partner_id = {{biz_partner_id}}
      -- AND d.warehouse_id = {{warehouse_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
          BETWEEN date('{{시작일}}') AND date('{{종료일}}')
      AND s.id IN (
          SELECT DISTINCT bundled_sku_id
          FROM bundled_sku_ro
      )
    GROUP BY s.id, s.sku_code, s.name, s.barcode

) combined
GROUP BY sku_id, sku_code, sku_name, barcode
ORDER BY sku_name
;


-- ============================================================
-- Sheet 3. 유니폼 제작 필요 (BOM 완제품 대상)
-- 생산이 필요한 완제품 SKU 수량 집계
-- ============================================================
SELECT
    s.name          AS sku_name,
    s.sku_code,
    s.barcode,
    s.id            AS sku_id,
    SUM(di.quantity) AS quantity
FROM delivery_ro d
JOIN delivery_item_ro di
    ON di.delivery_id = d.id
JOIN sku_ro s
    ON s.id = di.sku_id
   AND s.deleted_at IS NULL
WHERE d.biz_partner_id = {{biz_partner_id}}
  -- AND d.warehouse_id = {{warehouse_id}}
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
      BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND s.composition_type = 'BOM'
GROUP BY s.id, s.name, s.sku_code, s.barcode
ORDER BY s.name
;


-- ============================================================
-- Sheet 4. 재고조정양식 (Sheet 2 + 고정값)
-- direction='M' (이관), reason='ETC'
-- ============================================================
SELECT
    sku_code,
    sku_name,
    barcode,
    sku_id,
    SUM(quantity)   AS quantity,
    'M'             AS direction,
    'ETC'           AS reason
FROM (
    SELECT
        cs.sku_code, cs.name AS sku_name, cs.barcode, cs.id AS sku_id,
        SUM(di.quantity * bs.quantity) AS quantity
    FROM delivery_ro d
    JOIN delivery_item_ro di ON di.delivery_id = d.id
    JOIN sku_ro s ON s.id = di.sku_id AND s.deleted_at IS NULL AND s.composition_type = 'BOM'
    JOIN bundled_sku_ro bs ON bs.sku_id = s.id
    JOIN sku_ro cs ON cs.id = bs.bundled_sku_id AND cs.deleted_at IS NULL
    WHERE d.biz_partner_id = {{biz_partner_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
          BETWEEN date('{{시작일}}') AND date('{{종료일}}')
    GROUP BY cs.id, cs.sku_code, cs.name, cs.barcode

    UNION ALL

    SELECT
        s.sku_code, s.name AS sku_name, s.barcode, s.id AS sku_id,
        SUM(di.quantity) AS quantity
    FROM delivery_ro d
    JOIN delivery_item_ro di ON di.delivery_id = d.id
    JOIN sku_ro s ON s.id = di.sku_id AND s.deleted_at IS NULL
    WHERE d.biz_partner_id = {{biz_partner_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
          BETWEEN date('{{시작일}}') AND date('{{종료일}}')
      AND s.id IN (SELECT DISTINCT bundled_sku_id FROM bundled_sku_ro)
    GROUP BY s.id, s.sku_code, s.name, s.barcode
) combined
GROUP BY sku_id, sku_code, sku_name, barcode
ORDER BY sku_name
;


-- ============================================================
-- Sheet 5. CJ창고 입고요청 (Sheet 1 + type='G')
-- ============================================================
SELECT
    d.biz_partner_id,
    d.warehouse_id,
    s.manufacturer_id,
    di.product_id,
    s.name          AS sku_name,
    s.sku_code,
    s.barcode,
    s.id            AS sku_id,
    s.composition_type,
    SUM(di.quantity) AS quantity,
    'G'             AS type
FROM delivery_ro d
JOIN delivery_item_ro di ON di.delivery_id = d.id
JOIN sku_ro s ON s.id = di.sku_id AND s.deleted_at IS NULL
WHERE d.biz_partner_id = {{biz_partner_id}}
  -- AND d.warehouse_id = {{warehouse_id}}
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
      BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND (
      s.composition_type = 'BOM'
      OR s.id IN (SELECT DISTINCT bundled_sku_id FROM bundled_sku_ro)
  )
GROUP BY
    d.biz_partner_id, d.warehouse_id, s.manufacturer_id,
    di.product_id, s.name, s.sku_code, s.barcode, s.id, s.composition_type
ORDER BY s.name
;


-- ============================================================
-- Sheet 6. 생산입고요청 (Sheet 3 + type='P')
-- ============================================================
SELECT
    s.name          AS sku_name,
    s.sku_code,
    s.barcode,
    s.id            AS sku_id,
    SUM(di.quantity) AS quantity,
    'P'             AS type
FROM delivery_ro d
JOIN delivery_item_ro di ON di.delivery_id = d.id
JOIN sku_ro s ON s.id = di.sku_id AND s.deleted_at IS NULL
WHERE d.biz_partner_id = {{biz_partner_id}}
  -- AND d.warehouse_id = {{warehouse_id}}
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul')
      BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND s.composition_type = 'BOM'
GROUP BY s.id, s.name, s.sku_code, s.barcode
ORDER BY s.name
;
