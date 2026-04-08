-- ============================================================
-- 작업지시서 다운로드 쿼리 (Work Order Download)
-- DB: Presto / ods_commerce_production (또는 journi_y222)
--
-- 테이블 매핑 (가이드 → 실제):
--   delivery        → delivery_ro
--   delivery_item   → delivery_item_ro
--   sku             → sku_ro
--   bom_component   → bundled_sku_ro
--     bom_component.sku_id           = bundled_sku_ro.sku_id          (완제품)
--     bom_component.component_sku_id = bundled_sku_ro.bundled_sku_id  (구성요소)
--     bom_component.quantity         = bundled_sku_ro.quantity         (구성 단위 수량)
--
-- 파라미터:
--   {{시작일}}         예: '2026-03-23'
--   {{종료일}}         예: '2026-03-29'
--   {{biz_partner_id}} 예: 1758779013868
--   {{warehouse_id}}   예: 286184492824640  (라이온즈는 필수)
--   {{날짜기준}}        started_at / completed_at / requested_at / created_at
--
-- BOM 판별:
--   완제품: sku_ro.composition_type = 'BOM'
--           또는 bundled_sku_ro.sku_id 에 존재
--   구성요소: bundled_sku_ro.bundled_sku_id 에 존재
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
    s.name        AS sku_name,
    s.sku_code,
    s.barcode,
    s.id          AS sku_id,
    s.composition_type,
    SUM(di.quantity) AS quantity
FROM journi_y222.delivery_ro d
JOIN journi_y222.delivery_item_ro di
    ON di.delivery_id = d.id
   AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
JOIN journi_y222.sku_ro s
    ON s.id = di.sku_id
   AND s.dt = '{{종료일}}'
   AND s.deleted_at IS NULL
WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
  AND d.biz_partner_id = {{biz_partner_id}}
  -- AND d.warehouse_id = {{warehouse_id}}   -- 라이온즈 등 창고 고정 시 활성화
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND (
      -- BOM 완제품 (구성요소를 가진 SKU)
      s.composition_type = 'BOM'
      -- BOM 구성요소 (다른 완제품의 재료)
      OR s.id IN (
          SELECT DISTINCT bundled_sku_id
          FROM journi_y222.bundled_sku_ro
          WHERE dt = '{{종료일}}'
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
        cs.name    AS sku_name,
        cs.barcode,
        cs.id      AS sku_id,
        SUM(di.quantity * bs.quantity) AS quantity
    FROM journi_y222.delivery_ro d
    JOIN journi_y222.delivery_item_ro di
        ON di.delivery_id = d.id
       AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
    JOIN journi_y222.sku_ro s
        ON s.id = di.sku_id
       AND s.dt = '{{종료일}}'
       AND s.deleted_at IS NULL
       AND s.composition_type = 'BOM'        -- 완제품만
    JOIN journi_y222.bundled_sku_ro bs
        ON bs.sku_id = s.id
       AND bs.dt = '{{종료일}}'
    JOIN journi_y222.sku_ro cs
        ON cs.id = bs.bundled_sku_id         -- 구성요소 SKU
       AND cs.dt = '{{종료일}}'
       AND cs.deleted_at IS NULL
    WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
      AND d.biz_partner_id = {{biz_partner_id}}
      -- AND d.warehouse_id = {{warehouse_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
    GROUP BY cs.id, cs.sku_code, cs.name, cs.barcode

    UNION ALL

    -- 경로 B: 구성요소 SKU 자체가 delivery_item에 직접 포함된 경우
    SELECT
        s.sku_code,
        s.name     AS sku_name,
        s.barcode,
        s.id       AS sku_id,
        SUM(di.quantity) AS quantity
    FROM journi_y222.delivery_ro d
    JOIN journi_y222.delivery_item_ro di
        ON di.delivery_id = d.id
       AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
    JOIN journi_y222.sku_ro s
        ON s.id = di.sku_id
       AND s.dt = '{{종료일}}'
       AND s.deleted_at IS NULL
    WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
      AND d.biz_partner_id = {{biz_partner_id}}
      -- AND d.warehouse_id = {{warehouse_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
      AND s.id IN (
          SELECT DISTINCT bundled_sku_id
          FROM journi_y222.bundled_sku_ro
          WHERE dt = '{{종료일}}'
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
    s.name    AS sku_name,
    s.sku_code,
    s.barcode,
    s.id      AS sku_id,
    SUM(di.quantity) AS quantity
FROM journi_y222.delivery_ro d
JOIN journi_y222.delivery_item_ro di
    ON di.delivery_id = d.id
   AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
JOIN journi_y222.sku_ro s
    ON s.id = di.sku_id
   AND s.dt = '{{종료일}}'
   AND s.deleted_at IS NULL
WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
  AND d.biz_partner_id = {{biz_partner_id}}
  -- AND d.warehouse_id = {{warehouse_id}}
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND s.composition_type = 'BOM'   -- BOM 완제품만
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
    SUM(quantity)  AS quantity,
    'M'            AS direction,
    'ETC'          AS reason
FROM (
    -- Sheet 2와 동일한 이관지시서 쿼리 (경로 A + B)
    SELECT
        cs.sku_code, cs.name AS sku_name, cs.barcode, cs.id AS sku_id,
        SUM(di.quantity * bs.quantity) AS quantity
    FROM journi_y222.delivery_ro d
    JOIN journi_y222.delivery_item_ro di ON di.delivery_id = d.id AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
    JOIN journi_y222.sku_ro s ON s.id = di.sku_id AND s.dt = '{{종료일}}' AND s.deleted_at IS NULL AND s.composition_type = 'BOM'
    JOIN journi_y222.bundled_sku_ro bs ON bs.sku_id = s.id AND bs.dt = '{{종료일}}'
    JOIN journi_y222.sku_ro cs ON cs.id = bs.bundled_sku_id AND cs.dt = '{{종료일}}' AND cs.deleted_at IS NULL
    WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
      AND d.biz_partner_id = {{biz_partner_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
    GROUP BY cs.id, cs.sku_code, cs.name, cs.barcode

    UNION ALL

    SELECT
        s.sku_code, s.name AS sku_name, s.barcode, s.id AS sku_id,
        SUM(di.quantity) AS quantity
    FROM journi_y222.delivery_ro d
    JOIN journi_y222.delivery_item_ro di ON di.delivery_id = d.id AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
    JOIN journi_y222.sku_ro s ON s.id = di.sku_id AND s.dt = '{{종료일}}' AND s.deleted_at IS NULL
    WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
      AND d.biz_partner_id = {{biz_partner_id}}
      AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
      AND s.id IN (SELECT DISTINCT bundled_sku_id FROM journi_y222.bundled_sku_ro WHERE dt = '{{종료일}}')
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
    s.name    AS sku_name,
    s.sku_code,
    s.barcode,
    s.id      AS sku_id,
    s.composition_type,
    SUM(di.quantity) AS quantity,
    'G'       AS type    -- 입고 유형 고정
FROM journi_y222.delivery_ro d
JOIN journi_y222.delivery_item_ro di ON di.delivery_id = d.id AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
JOIN journi_y222.sku_ro s ON s.id = di.sku_id AND s.dt = '{{종료일}}' AND s.deleted_at IS NULL
WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
  AND d.biz_partner_id = {{biz_partner_id}}
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND (
      s.composition_type = 'BOM'
      OR s.id IN (SELECT DISTINCT bundled_sku_id FROM journi_y222.bundled_sku_ro WHERE dt = '{{종료일}}')
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
    s.name    AS sku_name,
    s.sku_code,
    s.barcode,
    s.id      AS sku_id,
    SUM(di.quantity) AS quantity,
    'P'       AS type    -- 생산 입고 유형 고정
FROM journi_y222.delivery_ro d
JOIN journi_y222.delivery_item_ro di ON di.delivery_id = d.id AND di.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
JOIN journi_y222.sku_ro s ON s.id = di.sku_id AND s.dt = '{{종료일}}' AND s.deleted_at IS NULL
WHERE d.dt BETWEEN '{{시작일}}' AND '{{종료일}}'
  AND d.biz_partner_id = {{biz_partner_id}}
  AND date(d.{{날짜기준}} AT TIME ZONE 'Asia/Seoul') BETWEEN date('{{시작일}}') AND date('{{종료일}}')
  AND s.composition_type = 'BOM'
GROUP BY s.id, s.name, s.sku_code, s.barcode
ORDER BY s.name
;
