# order_product_ro 테이블
order_product_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.order_product_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 3
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 236589095811394 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-12-01 06:21:44.876 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-12-01 06:21:44.876 | 수정 일시 |
| `artist_id` | BIGINT | 189350493141696 | artist 참조 ID (FK) |
| `biz_partner_id` | BIGINT | 1758779013868 | biz_partner 참조 ID (FK) |
| `commission_id` | BIGINT | 140282778076288 | commission 참조 ID (FK) ⚠️ NULL 포함 |
| `mall_id` | BIGINT | 189323979571392 | mall 참조 ID (FK) |
| `product_id` | BIGINT | 231715649016512 | product 참조 ID (FK) |
| `commission` | BIGINT | 15.000 |  |
| `origin_price_order_payment_amount` | DOUBLE | 10000.00 |  |
| `origin_price_product_origin_amount` | BIGINT | 10000.00 |  |
| `sale_price_base_currency_amount` | BIGINT | 10000.00 |  |
| `sale_price_order_payment_amount` | DOUBLE | 10000.00 |  |
| `sale_price_product_origin_amount` | BIGINT | 10000.00 |  |
| `artist_i18n` | VARCHAR (JSON) | {"results":[{"refId":null,"property":"name","lang":[{"id"... | JSON 형식 데이터 |
| `artist_name` | VARCHAR | SHINee | Enum: Monsta X, SHINee, i-dle |
| `base_currency` | VARCHAR | KRW |  |
| `delivery_policy` | VARCHAR | {"deliveryMethod":"NORMAL","warehouseId":1758779013868,"b... |  ⚠️ NULL 포함 |
| `fan_club_key` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `mall_i18n` | VARCHAR (JSON) | {"results":[{"refId":null,"property":"name","lang":[{"id"... | JSON 형식 데이터 |
| `mall_name` | VARCHAR | SMTOWN &STORE | Enum: CUBE, SMTOWN &STORE, Starship |
| `mall_url_path` | VARCHAR | sm | Enum: cube, sm, starship |
| `order_payment_currency` | VARCHAR | KRW | Enum: KRW, USD |
| `pickup_policy` | VARCHAR | {"warehouseId":283241854530176} |  ⚠️ NULL 포함 |
| `product_i18n` | VARCHAR (JSON) | {"results":[{"refId":null,"property":"artistName","lang":... | JSON 형식 데이터 |
| `product_name` | VARCHAR | [FAST DELIVERY] 2025 BEST CHOI's MINHO 'Our Movie' - 4 CU... | Enum: MONSTA X Official Fanclub MONBEBE, [FAST DELIVERY] 2025 BEST CHOI's MINHO 'Our Movie' - 4 CUT PHOTO SET, [Syncopation] OFFICIAL LIGHT STICK VER.3 |
| `product_origin_currency` | VARCHAR | KRW |  |
| `thumbnail_url` | VARCHAR | https://shop-cdn.berriz.in/product/231715649016512/233764... | Enum: https://shop-cdn.berriz.in/product/140282778076288/fanclub.png, https://shop-cdn.berriz.in/product/231715649016512/233764261964992.jpg, https://shop-cdn.berriz.in/product/283984588714816/286137439293504.jpg |
| `commission_type` | VARCHAR | PERCENT | Enum: FIXED, PERCENT |
| `product_type` | VARCHAR | GENERAL | Enum: FAN_CLUB, GENERAL |
| `product_sale_type` | VARCHAR | SELF | Enum: PURCHASE, SELF |
| `is_chart_target` | BIGINT | 0 |  |
| `product_commission_id` | BIGINT | 232219525309390 | product_commission 참조 ID (FK) |
| `project_id` | BIGINT | 224508776244480 | project 참조 ID (FK) ⚠️ NULL 포함 |
| `sub_project_id` | BIGINT | 224508776244481 | sub_project 참조 ID (FK) ⚠️ NULL 포함 |
| `product_purchase_benefits` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20251201 |  |

## 주의사항
- `fan_club_key`: NULL 비율 100%
- `product_purchase_benefits`: NULL 비율 100%
- `commission_id`: NULL 비율 67%
- `delivery_policy`: NULL 비율 67%
- `pickup_policy`: NULL 비율 67%
- `project_id`: NULL 비율 33%
- `sub_project_id`: NULL 비율 33%

**Enum성 컬럼 값 목록:**
- `artist_name`: Monsta X / SHINee / i-dle
- `mall_name`: CUBE / SMTOWN &STORE / Starship
- `mall_url_path`: cube / sm / starship
- `order_payment_currency`: KRW / USD
- `product_name`: MONSTA X Official Fanclub MONBEBE / [FAST DELIVERY] 2025 BEST CHOI's MINHO 'Our Movie' - 4 CUT PHOTO SET / [Syncopation] OFFICIAL LIGHT STICK VER.3
- `thumbnail_url`: https://shop-cdn.berriz.in/product/140282778076288/fanclub.png / https://shop-cdn.berriz.in/product/231715649016512/233764261964992.jpg / https://shop-cdn.berriz.in/product/283984588714816/286137439293504.jpg
- `commission_type`: FIXED / PERCENT
- `product_type`: FAN_CLUB / GENERAL
- `product_sale_type`: PURCHASE / SELF

**JSON 형식 컬럼:**
- `artist_i18n`: 주요 키 → `results`
- `delivery_policy`: 주요 키 → `bundleDeliveryGroupId`, `deliveryFeePolicy`, `deliveryMethod`, `jejuAreaDeliveryAvailable`, `onlySingleDeliveryAvailable`, `preSale`, `preSaleDeliverEnd`, `preSaleDeliverStart`
- `mall_i18n`: 주요 키 → `results`
- `pickup_policy`: 주요 키 → `warehouseId`
- `product_i18n`: 주요 키 → `results`
- `product_name`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  artist_id,
  biz_partner_id,
  commission_id
FROM journi_y222.order_product_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- artist_name별 집계
SELECT
  artist_name,
  COUNT(*) AS cnt
FROM journi_y222.order_product_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY artist_name
ORDER BY cnt DESC;
```

```sql
-- artist_i18n JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(artist_i18n, '$.results') AS artist_i18n_results
FROM journi_y222.order_product_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND artist_i18n IS NOT NULL
LIMIT 100;
```
