# order_line_ro 테이블
order_line_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.order_line_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 302432619161088 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-04 07:00:44.340 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-04 07:01:10.793 | 수정 일시 |
| `order_bundle_id` | BIGINT | 302432619161094 | order_bundle 참조 ID (FK) |
| `order_product_id` | BIGINT | 302432619120128 | order_product 참조 ID (FK) |
| `product_item_id` | BIGINT | 298780291867136 | product_item 참조 ID (FK) |
| `sku_id` | BIGINT | 298736971417408 | sku 참조 ID (FK) |
| `amount` | DOUBLE | 12000.00 | 금액 |
| `base_currency_amount` | BIGINT | 12000.00 |  |
| `product_item_price_base_currency_amount` | BIGINT | 0.00 |  |
| `product_item_price_order_payment_amount` | BIGINT | 0.00 |  |
| `product_item_price_product_origin_amount` | BIGINT | 0.00 |  |
| `quantity` | BIGINT | 2 | 수량 |
| `version` | BIGINT | 1 | Enum: 0, 1, 2, 3 |
| `base_currency` | VARCHAR | KRW |  |
| `option_name` | VARCHAR | A | Enum: 2026-02-21 18:00 (KST), A, DONGHAE ⚠️ NULL 포함 |
| `order_payment_currency` | VARCHAR | KRW | Enum: JPY, KRW, USD |
| `product_origin_currency` | VARCHAR | KRW |  |
| `product_item_type` | VARCHAR | SINGLE |  |
| `status` | VARCHAR | COMPLETED | 상태값 |
| `canceled_at` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `confirmed_at` | TIMESTAMP | 2026-01-26 15:01:20.859 |  ⚠️ NULL 포함 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `approved_at` | TIMESTAMP | 2026-01-26 15:01:20.859 |  ⚠️ NULL 포함 |
| `order_id` | BIGINT | 302432619120130 | order 참조 ID (FK) (nullable) |
| `log_date` | VARCHAR | 20260304 |  |

## 주의사항
- `canceled_at`: NULL 비율 100%
- `deleted_at`: NULL 비율 100%
- `confirmed_at`: NULL 비율 70%
- `approved_at`: NULL 비율 70%
- `option_name`: NULL 비율 60%
- `order_id`: NULL 비율 10%

**Enum성 컬럼 값 목록:**
- `quantity`: 1 / 2
- `version`: 0 / 1 / 2 / 3
- `option_name`: 2026-02-21 18:00 (KST) / A / DONGHAE
- `order_payment_currency`: JPY / KRW / USD
- `status`: COMPLETED / CONFIRMED / CREATED / FAILED

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  order_bundle_id,
  order_product_id,
  product_item_id
FROM journi_y222.order_line_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.order_line_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```
