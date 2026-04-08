WITH usage_agg AS (
  SELECT
      CAST(date_format(a.updated_at AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d') AS date) AS dt,
      b.sku_id,
      SUM(IF(a.type = 'INCOMING_COMPLETED',   a.delta, 0)) AS incoming_completed_qty,
      SUM(IF(a.type = 'ADJUSTMENT_COMPLETED', a.delta, 0)) AS adjustment_completed_qty,
      SUM(IF(a.type = 'OUTGOING_REQUESTED',   a.delta, 0)) AS outgoing_requested_qty,
      SUM(IF(a.type = 'OUTGOING_CANCELLED',   a.delta, 0)) AS outgoing_cancelled_qty
  FROM stock_usage_ro a
  LEFT JOIN stock_ro b
         ON a.stock_id = b.id

  GROUP BY 1, 2
),
net AS (
  SELECT
      dt,
      sku_id,
      incoming_completed_qty,
      adjustment_completed_qty,
      outgoing_requested_qty,
      outgoing_cancelled_qty,
      (incoming_completed_qty
       + adjustment_completed_qty
       + outgoing_cancelled_qty
       + outgoing_requested_qty) AS net_change
  FROM usage_agg
),
net_with_eod AS (
  SELECT
      dt,
      sku_id,
      incoming_completed_qty,
      adjustment_completed_qty,
      outgoing_requested_qty,
      outgoing_cancelled_qty,
      net_change,
      SUM(net_change) OVER (
        PARTITION BY sku_id
        ORDER BY dt
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS eod_qty_rel
  FROM net
)
, summary as
(SELECT
    n.dt,
    n.sku_id,
    coalesce(lag(n.eod_qty_rel,1) over(partition by n.sku_id order by n.dt asc),0) as prev_eod_qty_rel,
    n.incoming_completed_qty, 
    n.adjustment_completed_qty, 
    n.outgoing_requested_qty, 
    n.outgoing_cancelled_qty, 
    n.net_change ,
    n.eod_qty_rel 
FROM net_with_eod n
) 
SELECT
    n.dt,
    cast(n.sku_id as varchar) as sku_id,
    s.name      AS sku_nm,
    s.sku_code,
    s.barcode,
  --  s.hs_code,
    n.prev_eod_qty_rel AS "기초재고",
    n.incoming_completed_qty AS "입고재고",
    n.adjustment_completed_qty AS "조정재고",
    n.outgoing_requested_qty AS "출고요청",
    n.outgoing_cancelled_qty AS "출고취소",
    n.net_change AS "일자순변동",
    n.eod_qty_rel AS "최종재고"
FROM summary n
LEFT JOIN sku_ro s
       ON n.sku_id = s.id
ORDER BY n.dt desc
;
