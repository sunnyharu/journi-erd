-- 전체 일별 지표


  select completed_dt            as "결제일"
     , user_cnt                  as "결제고객수"
     , ord_cnt                   as "결제주문수"
     , ord_prd_cnt               as "결제주문상품수"
     , quantity                  as "총상품 구매수량"
     , tot_pay_amt               as "결제거래액(배송비포함,쿠폰할인적용)"  
     , krw_delivery_fee          as "배송비"
     , real_discount_amount      as "쿠폰할인액"
     , line_delivery_krw_amount  as "결제거래액(배송비포함,쿠폰할인미적용)"
     
     , concat(cast(round((cast(krw_delivery_fee as DOUBLE)/ nullif(cast(tot_pay_amt as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "거래액 대비 배송비 구성비"
     , concat(cast(round((cast(real_discount_amount as DOUBLE)/ nullif(cast(line_delivery_krw_amount as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "거래액 대비 쿠폰할인 구성비"
     , cast(round(cast(ord_cnt as DOUBLE)/nullif(cast(user_cnt as DOUBLE),0),1) as varchar) as "인당주문수"
     , cast(round(cast(ord_prd_cnt as DOUBLE)/nullif(cast(ord_cnt as DOUBLE),0),2) as varchar) as "주문당 상품수"
     , cast(round(tot_pay_amt / nullif(cast(ord_cnt as double), 0)) as integer)  as "주문당거래액"
     , cast(round(tot_pay_amt / nullif(cast(user_cnt as double), 0)) as integer) as "인당거래액"

     , net_user_cnt                  as "순_결제고객수"
     , net_ord_cnt                   as "순_결제주문수"
     , net_ord_prd_cnt               as "순_결제주문상품수"
     , net_quantity                  as "순_총상품 구매수량"
     , net_tot_pay_amt               as "순_결제거래액(배송비포함,쿠폰적용)"  
     , net_krw_delivery_fee          as "순_배송비"
     , net_real_discount_amount      as "순_쿠폰할인액"
     , net_line_delivery_krw_amount  as "순_결제거래액(배송비포함,쿠폰미적용)"
     
     , concat(cast(round((cast(net_krw_delivery_fee as DOUBLE)/ nullif(cast(net_tot_pay_amt as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "순_거래액 대비 배송비 구성비"
     , concat(cast(round((cast(net_real_discount_amount as DOUBLE)/ nullif(cast(net_line_delivery_krw_amount as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "순_거래액 대비 쿠폰할인 구성비"
     , cast(round(cast(net_ord_cnt as DOUBLE)/nullif(cast(net_user_cnt as DOUBLE),0),1) as varchar) as "순_인당주문수"
     , cast(round(cast(net_ord_prd_cnt as DOUBLE)/nullif(cast(net_ord_cnt as DOUBLE),0),2) as varchar) as "순_주문당 상품수"
     , cast(round(net_tot_pay_amt / nullif(cast(net_ord_cnt as double), 0)) as integer)  as "순_주문당거래액"
     , cast(round(net_tot_pay_amt / nullif(cast(net_user_cnt as double), 0)) as integer) as "순_인당거래액"     
     
  
  from 
  (
       select 
        -- 총 기준 
           completed_dt
        --  , 'all' as gubun 
       --  , case when partner_id  = 6 then partner_id else 0 end as partner_gubun
         , count(distinct user_id)                                                               as user_cnt 
         , count(distinct order_id)                                                              as ord_cnt 
         , count(distinct order_line_id)                                                         as ord_prd_cnt 
         , sum(quantity)                                                                         as quantity 
         
         , sum(if(amt_rk = 1, coalesce(krw_amount,0), 0))                                                                                        as tot_pay_amt 
         , sum(coalesce(line_krw_amount,0)) +  sum(if(delivery_rk = 1, coalesce(krw_delivery_fee,0), 0)) - sum(coalesce(real_discount_amount,0)) as pay_amt 
         , sum(coalesce(line_krw_amount,0)) +  sum(if(delivery_rk = 1, coalesce(krw_delivery_fee,0), 0))                                         as line_delivery_krw_amount 
         , sum(coalesce(line_krw_amount,0))                                                                                                      as line_krw_amount
         , sum(if(delivery_rk = 1, krw_delivery_fee, 0))                                                                                         as krw_delivery_fee
         , coalesce(sum(real_discount_amount), 0)                                                                                                as real_discount_amount

        
        -- 순 기준 
         , count(distinct if(cancel_yn = 0, user_id, null))                                      as net_user_cnt
         , count(distinct if(cancel_yn = 0, order_id, null))                                     as net_ord_cnt
         , count(distinct if(cancel_yn = 0, order_line_id, null))                                as net_ord_prd_cnt
         , sum(quantity) - sum(cancel_quantity)                                                  as net_quantity


         , sum(if(net_amt_rk = 1 and cancel_yn = 0, coalesce(krw_amount,0) - coalesce(round(refund_krw_amount, 0), 0), 0))                      as net_tot_pay_amt 
         , sum(if(cancel_yn = 0, line_krw_amount, 0)) 
            + sum(if(net_delivery_rk = 1 and cancel_yn = 0, coalesce(krw_delivery_fee, 0) + coalesce(total_claim_delivery_fee, 0), 0)) 
            - sum(if(cancel_yn = 0, coalesce(real_discount_amount,0), 0))                                                                       as net_pay_amt 
        
        -- 순) 상품금액 합 + 배송비 금액 합     
         , sum(if(cancel_yn = 0, line_krw_amount, 0)) 
             + sum(if(net_delivery_rk = 1 and cancel_yn = 0, coalesce(krw_delivery_fee,0) + coalesce(total_claim_delivery_fee,0), 0))           as net_line_delivery_krw_amount    
             
        -- 순) 상품별 거래액 합
         , sum(if(cancel_yn = 0, line_krw_amount, 0))                                                                                           as net_line_krw_amount     
         , sum(if(net_delivery_rk = 1 and cancel_yn = 0, coalesce(krw_delivery_fee, 0) + coalesce(total_claim_delivery_fee, 0), 0))             as net_krw_delivery_fee   

         -- 순) 쿠폰 할인금액 
         , sum(if(cancel_yn = 0, coalesce(real_discount_amount,0), 0))                                                                          as net_real_discount_amount
    
from journi_y222.mart_daily_order
where  date_format(date_parse(completed_dt, '%Y-%m-%d'), '%Y-%m') = '{{조회월}}'
group by 1
) a
order by 1 desc

  
-- 파트너 구분


  select completed_dt            as "결제일"
     , user_cnt                  as "결제고객수"
     , ord_cnt                   as "결제주문수"
     , ord_prd_cnt               as "결제주문상품수"
     , quantity                  as "총상품 구매수량"
     , pay_amt               as "결제거래액(배송비포함,쿠폰할인적용)"  
     , krw_delivery_fee          as "배송비"
     , real_discount_amount      as "쿠폰할인액"
     , line_delivery_krw_amount  as "결제거래액(배송비포함,쿠폰할인미적용)"
     
     , concat(cast(round((cast(krw_delivery_fee as DOUBLE)/ nullif(cast(pay_amt as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "거래액 대비 배송비 구성비"
     , concat(cast(round((cast(real_discount_amount as DOUBLE)/ nullif(cast(line_delivery_krw_amount as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "거래액 대비 쿠폰할인 구성비"
     , cast(round(cast(ord_cnt as DOUBLE)/nullif(cast(user_cnt as DOUBLE),0),1) as varchar) as "인당주문수"
     , cast(round(cast(ord_prd_cnt as DOUBLE)/nullif(cast(ord_cnt as DOUBLE),0),2) as varchar) as "주문당 상품수"
     , cast(round(pay_amt / nullif(cast(ord_cnt as double), 0)) as integer)  as "주문당거래액"
     , cast(round(pay_amt / nullif(cast(user_cnt as double), 0)) as integer) as "인당거래액"

     , net_user_cnt                  as "순_결제고객수"
     , net_ord_cnt                   as "순_결제주문수"
     , net_ord_prd_cnt               as "순_결제주문상품수"
     , net_quantity                  as "순_총상품 구매수량"
     , net_pay_amt           as "순_결제거래액(배송비포함,쿠폰적용)"  
     , net_krw_delivery_fee          as "순_배송비"
     , net_real_discount_amount      as "순_쿠폰할인액"
     , net_line_delivery_krw_amount  as "순_결제거래액(배송비포함,쿠폰미적용)"
     
     , concat(cast(round((cast(net_krw_delivery_fee as DOUBLE)/ nullif(cast(net_pay_amt as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "순_거래액 대비 배송비 구성비"
     , concat(cast(round((cast(net_real_discount_amount as DOUBLE)/ nullif(cast(net_line_delivery_krw_amount as DOUBLE),0)) * 100, 1) AS varchar), '%') AS  "순_거래액 대비 쿠폰할인 구성비"
     , cast(round(cast(net_ord_cnt as DOUBLE)/nullif(cast(net_user_cnt as DOUBLE),0),1) as varchar) as "순_인당주문수"
     , cast(round(cast(net_ord_prd_cnt as DOUBLE)/nullif(cast(net_ord_cnt as DOUBLE),0),2) as varchar) as "순_주문당 상품수"
     , cast(round(net_pay_amt / nullif(cast(net_ord_cnt as double), 0)) as integer)  as "순_주문당거래액"
     , cast(round(net_pay_amt / nullif(cast(net_user_cnt as double), 0)) as integer) as "순_인당거래액"     

  from 
  (
       select 
        -- 총 기준 
           completed_dt
        --  , 'all' as gubun 
       --  , case when partner_id  = 6 then partner_id else 0 end as partner_gubun
         , count(distinct user_id)                                                               as user_cnt 
         , count(distinct order_id)                                                              as ord_cnt 
         , count(distinct order_line_id)                                                         as ord_prd_cnt 
         , sum(quantity)                                                                         as quantity 
         
         , sum(if(amt_rk = 1, coalesce(krw_amount,0), 0))                                                                                        as tot_pay_amt 
         , sum(coalesce(line_krw_amount,0)) +  sum(if(delivery_rk = 1, coalesce(krw_delivery_fee,0), 0)) - sum(coalesce(real_discount_amount,0)) as pay_amt 
         , sum(coalesce(line_krw_amount,0)) +  sum(if(delivery_rk = 1, coalesce(krw_delivery_fee,0), 0))                                         as line_delivery_krw_amount 
         , sum(coalesce(line_krw_amount,0))                                                                                                      as line_krw_amount
         , sum(if(delivery_rk = 1, krw_delivery_fee, 0))                                                                                         as krw_delivery_fee
         , coalesce(sum(real_discount_amount), 0)                                                                                                as real_discount_amount

        
        -- 순 기준 
         , count(distinct if(cancel_yn = 0, user_id, null))                                      as net_user_cnt
         , count(distinct if(cancel_yn = 0, order_id, null))                                     as net_ord_cnt
         , count(distinct if(cancel_yn = 0, order_line_id, null))                                as net_ord_prd_cnt
         , sum(quantity) - sum(cancel_quantity)                                                  as net_quantity


         , sum(if(net_amt_rk = 1 and cancel_yn = 0, coalesce(krw_amount,0) - coalesce(round(refund_krw_amount, 0), 0), 0))                      as net_tot_pay_amt 
         , sum(if(cancel_yn = 0, line_krw_amount, 0)) 
            + sum(if(net_delivery_rk = 1 and cancel_yn = 0, coalesce(krw_delivery_fee, 0) + coalesce(total_claim_delivery_fee, 0), 0)) 
            - sum(if(cancel_yn = 0, coalesce(real_discount_amount,0), 0))                                                                       as net_pay_amt 
        
        -- 순) 상품금액 합 + 배송비 금액 합     
         , sum(if(cancel_yn = 0, line_krw_amount, 0)) 
             + sum(if(net_delivery_rk = 1 and cancel_yn = 0, coalesce(krw_delivery_fee,0) + coalesce(total_claim_delivery_fee,0), 0))           as net_line_delivery_krw_amount    
             
        -- 순) 상품별 거래액 합
         , sum(if(cancel_yn = 0, line_krw_amount, 0))                                                                                           as net_line_krw_amount     
         , sum(if(net_delivery_rk = 1 and cancel_yn = 0, coalesce(krw_delivery_fee, 0) + coalesce(total_claim_delivery_fee, 0), 0))             as net_krw_delivery_fee   

         -- 순) 쿠폰 할인금액 
         , sum(if(cancel_yn = 0, coalesce(real_discount_amount,0), 0))                                                                          as net_real_discount_amount
    
from journi_y222.mart_daily_order
where  date_format(date_parse(completed_dt, '%Y-%m-%d'), '%Y-%m') = '{{조회월}}'
    and partner_id <> 6 -- 6은 라이온즈 파트너
group by 1
) a
order by 1 desc

  

