# order_bundle_ro 테이블
order_bundle_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.order_bundle_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 313102195945922 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-19 08:48:02.916 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-19 08:48:02.916 | 수정 일시 |
| `biz_partner_id` | BIGINT | 6 | biz_partner 참조 ID (FK) |
| `bundle_delivery_group_id` | BIGINT | 302433387510784 | bundle_delivery_group 참조 ID (FK) ⚠️ NULL 포함 |
| `order_id` | BIGINT | 313102195864001 | order 참조 ID (FK) |
| `shipping_warehouse_id` | BIGINT | 286184492824640 | shipping_warehouse 참조 ID (FK) ⚠️ NULL 포함 |
| `base_currency_delivery_fee` | BIGINT | 0.00 |  |
| `delivery_fee` | BIGINT | 0.00 |  |
| `pickup_date` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `base_currency` | VARCHAR | KRW |  |
| `delivery_fee_currency` | VARCHAR | KRW | Enum: JPY, KRW, USD |
| `delivery_requirement` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_city` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_country` | VARCHAR | KR |  ⚠️ NULL 포함 |
| `receiver_state_or_province` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `area_type` | VARCHAR | NORMAL |  ⚠️ NULL 포함 |
| `delivery_method` | VARCHAR | NORMAL |  ⚠️ NULL 포함 |
| `receiving_type` | VARCHAR | DELIVERY | Enum: DELIVERY, NONE |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `pickup_warehouse_id` | VARCHAR | NULL | pickup_warehouse 참조 ID (FK) ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20260319 |  |

## 주의사항
- `pickup_date`: NULL 비율 100%
- `delivery_requirement`: NULL 비율 100%
- `receiver_city`: NULL 비율 100%
- `receiver_state_or_province`: NULL 비율 100%
- `deleted_at`: NULL 비율 100%
- `pickup_warehouse_id`: NULL 비율 100%
- `bundle_delivery_group_id`: NULL 비율 80%
- `shipping_warehouse_id`: NULL 비율 50%
- `receiver_country`: NULL 비율 50%
- `area_type`: NULL 비율 50%

**Enum성 컬럼 값 목록:**
- `delivery_fee_currency`: JPY / KRW / USD
- `receiving_type`: DELIVERY / NONE

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  biz_partner_id,
  bundle_delivery_group_id,
  order_id
FROM journi_y222.order_bundle_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- delivery_fee_currency별 집계
SELECT
  delivery_fee_currency,
  COUNT(*) AS cnt
FROM journi_y222.order_bundle_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY delivery_fee_currency
ORDER BY cnt DESC;
```
