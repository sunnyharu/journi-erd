WITH payment AS (
  SELECT
    date_format(completed_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d') AS completed_dt
  , ref_id    AS order_id
  , user_id
  , requested_currency AS currency
  , CAST(amount AS DOUBLE) AS amount
  FROM payment_ro
  WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
    AND date(date_format(completed_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
    AND status <> 'REQUESTED'
)

,orders AS (
  SELECT
    id AS order_id
  , CAST(base_currency_payment_amount AS DOUBLE) AS krw_amount
  , CASE
      WHEN payment_currency = 'JPY' THEN regexp_extract(exchange_rates, '100JPY/KRW=([0-9.]+)', 1)
      WHEN payment_currency = 'USD' THEN regexp_extract(exchange_rates, 'USD/KRW=([0-9.]+)', 1)
      WHEN payment_currency = 'KRW' THEN '1'
      ELSE payment_currency
    END AS exchange_rate
  FROM orders_ro
  WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
    AND date(date_format(completed_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
    AND status = 'COMPLETED'
)

,order_line AS (
  SELECT
    id AS order_line_id
  , order_bundle_id
  , order_product_id
  , product_item_id
  , sku_id
  , quantity
  , option_name
  , product_item_type
  , CAST(amount AS DOUBLE)               AS line_amount
  , CAST(base_currency_amount AS DOUBLE) AS line_krw_amount
  FROM order_line_ro
  WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
    AND date(date_format(created_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
)

,order_bundle AS (
  SELECT
    id AS order_bundle_id
  , order_id
  , biz_partner_id
  , CAST(base_currency_delivery_fee AS DOUBLE) AS krw_delivery_fee
  , CAST(delivery_fee AS DOUBLE)               AS delivery_fee
  , bundle_delivery_group_id
  , receiver_country
  , receiving_type
  FROM order_bundle_ro
  WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
    AND date(date_format(created_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
)


, project as 
(
select cp.project_id
		, cp.project_name
		, cp.partner_id
		, cp.contract_id
		, ct.businessmodeltype as bm_type
from 
	(select distinct 
		  cp._id as project_id
		, name as project_name
		, bizpartnerid as partner_id
		, cast(json_extract(sp.subprojects_json_string, '$.contractId') as bigint) as contract_id
	  from contract_project_ro cp
	  	 , unnest(cp.subprojects) as sp(subprojects_json_string)) cp
left join contract_ro ct
	on cp.contract_id = ct._id
)

, artist AS (
  SELECT
    b.partner_nm     AS partner_nm
  , a.biz_partner_id AS partner_id
  , a.artist_id
  , a.artist_name
  FROM (
    SELECT DISTINCT
    , bizpartnerid     AS biz_partner_id
    , _id              AS artist_id
    , artistname       AS artist_name
    FROM artist_ro
  ) a
  LEFT JOIN (
    SELECT
      bizpartnerid
    , json_extract_scalar(elem, '$.text') AS partner_nm
    FROM mall_ro
    CROSS JOIN UNNEST(i18n) AS t(elem)
    WHERE json_extract_scalar(elem, '$.type') = 'EN'
      AND profile = 'prod'
      AND deletedat IS NULL
  ) b ON a.biz_partner_id = b.bizpartnerid
)

, product as 
 ( select distinct 
    op.id as order_product_id 

   ,op.biz_partner_id as partner_id
   ,cma.partner_nm

   ,op.artist_id 
   ,cma.artist_name

   ,op.mall_id 
   ,op.mall_name

   ,op.product_id 
   ,op.product_name
   ,op.product_type

   ,coalesce(pj.project_id, 0) as project_id
   ,coalesce(pj.project_name, 'NONE') as project_name
   ,coalesce(pj.bm_type, 'NONE') as bm_type
   ,case when bm_type = 'BR' then 'BR'
         when bm_type = 'CM' then '커뮤니티'
         when bm_type = 'DP' then '사입'
         when bm_type = 'CO' then '위탁'
         when bm_type = 'LI' then '라이선스'
         when bm_type = 'OM' then '제작외주'
         when bm_type = 'MD' then '제조납품'
         when bm_type = 'DB' then '유통'
         when bm_type = 'AG' then '운영 위수탁' else bm_type end as bm_type_nm
  FROM 
  (select id 
        , biz_partner_id
        , artist_id
        , mall_id
        , mall_name
        , project_id
        , cast(product_id as varchar) as product_id
        , max(product_name) as product_name
        , product_type
  FROM order_product_ro
  WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
    AND date(date_format(created_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
    AND artist_name NOT LIKE '%테스트%' AND lower(artist_name) NOT LIKE '%test%'
    AND mall_name   NOT LIKE '%테스트%' AND lower(mall_name)   NOT LIKE '%test%'
    AND upper(product_type) = 'GENERAL'
    group by id 
        , biz_partner_id
        , artist_id
        , mall_id
        , mall_name
        , product_id
        , product_type
        , project_id
  ) op
  left join artist cma on op.artist_id = cma.artist_id
  left join community_artist_ro ca on cma.artist_id = ca.artist_id
  left join project pj on op.project_id = pj.project_id 
  left join partner_ro pt on op.biz_partner_id = pt.partner_id -- 파트너 정보 매핑   

)


, claim AS (
     SELECT
    b.order_id
  , a.order_line_id
  , a.order_bundle_id
  , b.refund_currency
  , sum(a.quantity) as quantity
  , max(b.claim_dt) as claim_dt
  , sum(b.refund_amount) as refund_amount
  , max_by(b.final_refund_amount,b.claim_dt) as final_refund_amount
  , sum(b.total_claim_delivery_fee) as total_claim_delivery_fee
  FROM (
    SELECT
        date_format(updated_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d') AS claim_line_dt
      , order_line_id
      , order_bundle_id
      , claim_id
      , id AS claim_line_id
      , type
      , quantity
    FROM claim_line_ro
    WHERE date(date_format(updated_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
         AND type = 'PURCHASED'
     ) a
  LEFT JOIN 
    (SELECT
        c.claim_dt
      , c.order_id
      , c.claim_id
      , c.refund_amount
      , c.refund_currency
      , ca.final_refund_amount
      , cd.order_bundle_id
      , cd.total_claim_delivery_fee
    FROM (
        SELECT
            date_format(updated_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d') AS claim_dt
          , order_id
          , id AS claim_id
          , CAST(refund_amount AS DOUBLE) AS refund_amount
          , refund_currency
        FROM claim_ro
        WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
          AND refund_amount IS NOT NULL
        ) c
    LEFT JOIN (
                SELECT
                    order_id
                  , SUM(CAST(refund_amount AS DOUBLE)) AS final_refund_amount
                  , MAX(refund_currency) AS refund_currency
                FROM claim_ro
                WHERE date(date_parse(log_date, '%Y%m%d')) BETWEEN date_add('day', -1, date('{{기준일}}')) AND date_add('day', 1, date('{{기준일}}'))
                  AND refund_amount IS NOT NULL
                GROUP BY 1
             ) ca ON c.order_id = ca.order_id
    LEFT JOIN (
        SELECT  claim_id
              , order_bundle_id
              , abs(cast(refunded_delivery_fee as double)) + cast(return_delivery_fee as double) as total_claim_delivery_fee
        FROM claim_delivery_fee_ro
        WHERE date(date_format(updated_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d')) BETWEEN date('{{기준일}}') AND date('{{기준일}}')
         ) cd ON c.claim_id = cd.claim_id 
  ) b ON a.claim_id = b.claim_id  
  WHERE b.final_refund_amount IS NOT NULL 
  group by 1,2,3,4
)

, coupon AS (
  SELECT
    coupon_policy_id
  , order_line_id
  , CASE WHEN benefit_type = 'FIXED_AMOUNT_DISCOUNT' THEN 'AMT'
         WHEN benefit_type = 'FIXED_RATE_DISCOUNT'   THEN 'RATE' END AS coupon_discount_type
  , CASE WHEN coupon_type = 'PRODUCT_COUPON'  THEN 'PRODUCT'
         WHEN coupon_type = 'CHECKOUT_COUPON' THEN 'CHECKOUT' END AS coupon_scope_type
  , ROUND(CAST(base_currency_applied_discount_amount AS DOUBLE), 0) AS real_discount_amount
  , ROUND(CAST(discount_amount AS DOUBLE), 0)     AS coupon_discount_amount
  , ROUND(CAST(discount_rate AS DOUBLE), 0)        AS coupon_discount_rate
  , ROUND(CAST(max_discount_amount AS DOUBLE), 0)  AS max_discount_amount
  , ROUND(CAST(min_applicable_price AS DOUBLE), 0) AS min_applicable_price
  , json_extract_scalar(lang_elem, '$.text')       AS coupon_name
  FROM order_coupon_discount_ro
  CROSS JOIN UNNEST(
      CAST(json_extract(i18n, '$.results[0].lang') AS ARRAY(JSON))
  ) AS t(lang_elem)
  WHERE json_extract_scalar(lang_elem, '$.type') = 'KO'
)


, mart_v1 AS (
  SELECT
    pay.completed_dt
  , CAST(CASE WHEN c.order_line_id IS NOT NULL THEN 1 ELSE 0 END AS INT) AS cancel_yn
  , pay.order_id
  , pay.user_id
  , usr.member_key
  , pay.currency
  , pay.amount
  , ord.krw_amount
  , ord.exchange_rate
  , line.order_line_id
  , line.order_bundle_id
  , line.order_product_id
  , line.product_item_id
  , line.sku_id
  , line.option_name
  , line.product_item_type
  , line.quantity
  , line.line_amount
  , line.line_krw_amount
  , CAST(c.refund_amount AS DOUBLE)       AS refund_amount
  , CAST(c.final_refund_amount AS DOUBLE) AS final_refund_amount
  , CASE
      WHEN c.refund_currency = 'KRW' THEN CAST(c.final_refund_amount AS DOUBLE)
      WHEN c.refund_currency = 'JPY' THEN CAST(c.final_refund_amount AS DOUBLE) * CAST(ord.exchange_rate AS DOUBLE) / 100
      ELSE                                CAST(c.final_refund_amount AS DOUBLE) * CAST(ord.exchange_rate AS DOUBLE)
    END AS refund_krw_amount
  , CASE
      WHEN c.refund_currency = 'KRW' THEN CAST(c.total_claim_delivery_fee AS DOUBLE)
      WHEN c.refund_currency = 'JPY' THEN CAST(c.total_claim_delivery_fee AS DOUBLE) * CAST(ord.exchange_rate AS DOUBLE) / 100
      ELSE                                CAST(c.total_claim_delivery_fee AS DOUBLE) * CAST(ord.exchange_rate AS DOUBLE)
    END AS total_claim_delivery_fee
  , COALESCE(c.quantity, 0)                   AS cancel_quantity
  , line.quantity - COALESCE(c.quantity, 0)   AS net_quantity
  , bun.krw_delivery_fee
  , bun.delivery_fee
  , bun.bundle_delivery_group_id
  
  , bun.receiver_country
  , co2.country_nm AS receiver_country_nm
  , bun.receiving_type
  
  , prd.product_id
  , prd.product_name
  , prd.product_type
  
  , prd.partner_id
  , art.partner_nm
  
  , prd.artist_id
  , art.artist_name
  
  , prd.mall_id
  , prd.mall_name

  -- 프로젝트 추가 
  , prd.project_id
  , prd.project_name
  , prd.bm_type
  , prd.bm_type_nm
  
  , usr.country AS join_country
  , co1.country_nm AS join_country_nm
  , cp.coupon_policy_id
  , cp.coupon_discount_type
  , cp.coupon_scope_type
  , cp.real_discount_amount
  , cp.coupon_discount_amount
  , cp.coupon_discount_rate
  , cp.max_discount_amount
  , cp.min_applicable_price
  , cp.coupon_name
  , c.claim_dt
  FROM payment pay
  LEFT JOIN orders       ord  ON pay.order_id          = ord.order_id
  LEFT JOIN order_bundle bun  ON ord.order_id          = bun.order_id
  LEFT JOIN order_line   line ON bun.order_bundle_id   = line.order_bundle_id
  LEFT JOIN users_ro usr ON pay.user_id = usr.id
  JOIN  product          prd  ON line.order_product_id = prd.order_product_id
  LEFT JOIN journi_y222.iso_code co1 ON co1.iso_code2 = usr.country
  LEFT JOIN journi_y222.iso_code co2 ON co2.iso_code2 = bun.receiver_country
  LEFT JOIN artist        art  ON prd.partner_id = art.partner_id AND prd.artist_id = art.artist_id
  LEFT JOIN claim         c    ON line.order_line_id = c.order_line_id
  LEFT JOIN coupon        cp   ON line.order_line_id = cp.order_line_id
)

, mart_v2 AS (
  SELECT
    *
  , ROUND(line_krw_amount / NULLIF(quantity, 0), 0)             AS unit_price
  , MAX(refund_krw_amount) OVER (PARTITION BY order_id)         AS refund_krw_amount_agg
  , MAX(total_claim_delivery_fee) OVER (PARTITION BY order_id)  AS total_claim_delivery_fee_agg
  , ROW_NUMBER() OVER (PARTITION BY order_id        ORDER BY order_line_id) AS amt_rk
  , ROW_NUMBER() OVER (PARTITION BY order_bundle_id ORDER BY order_line_id) AS delivery_rk
  , ROW_NUMBER() OVER (PARTITION BY order_id,        cancel_yn ORDER BY order_line_id) AS net_amt_rk
  , ROW_NUMBER() OVER (PARTITION BY order_bundle_id, cancel_yn ORDER BY order_line_id) AS net_delivery_rk
  FROM mart_v1
)

select
    completed_dt
  , claim_dt
  , cancel_yn
  , CAST(user_id AS VARCHAR)           AS user_id
  , member_key
  , CAST(order_id AS VARCHAR)          AS order_id
  , CAST(order_line_id AS VARCHAR)     AS order_line_id
  , CAST(order_bundle_id AS VARCHAR)   AS order_bundle_id
  , CAST(order_product_id AS VARCHAR)  AS order_product_id
  , CAST(product_item_id AS VARCHAR)   AS product_item_id
  , CAST(sku_id AS VARCHAR)            AS sku_id
  , CAST(product_id AS VARCHAR)        AS product_id
  , product_name
  , option_name
  , product_item_type
  , krw_amount
  , quantity
  , line_krw_amount
  , krw_delivery_fee
  , unit_price
  , refund_krw_amount_agg              AS refund_krw_amount
  , total_claim_delivery_fee_agg       AS total_claim_delivery_fee
  , refund_amount
  , cancel_quantity
  , currency
  , amount
  , line_amount
  , delivery_fee
  , exchange_rate
  
  , CAST(project_id AS VARCHAR)        AS project_id
  , project_name
  , bm_type
  , bm_type_nm
  
  , receiver_country
  , receiver_country_nm
  , receiving_type
  , product_type
  , partner_id
  , partner_nm
  , CAST(artist_id AS VARCHAR)         AS artist_id
  , artist_name
  , CAST(mall_id AS VARCHAR)           AS mall_id
  , mall_name
  , join_country
  , join_country_nm
  , CAST(coupon_policy_id AS VARCHAR)  AS coupon_policy_id
  , coupon_discount_type
  , coupon_scope_type
  , real_discount_amount
  , coupon_discount_amount
  , coupon_discount_rate
  , max_discount_amount
  , min_applicable_price
  , coupon_name
  , amt_rk
  , delivery_rk
  , net_amt_rk
  , net_delivery_rk
 
  FROM mart_v2
  ;