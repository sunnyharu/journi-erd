# order_coupon_discount_ro 테이블
order_coupon_discount_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.order_coupon_discount_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 4
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 252155070822980 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-12-23 06:10:48.312 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-12-23 06:10:48.312 | 수정 일시 |
| `coupon_id` | BIGINT | 252150123887168 | coupon 참조 ID (FK) |
| `coupon_policy_id` | BIGINT | 251469986412608 | coupon_policy 참조 ID (FK) |
| `order_line_id` | BIGINT | 252155070822979 | order_line 참조 ID (FK) |
| `applied_discount_amount` | DOUBLE | 208.00 |  |
| `base_currency_applied_discount_amount` | BIGINT | 208.00 |  |
| `discount_amount` | BIGINT | 2000.00 |  ⚠️ NULL 포함 |
| `discount_rate` | BIGINT | 10.000 | Enum: 10.000, 5.000 (nullable) |
| `max_discount_amount` | BIGINT | 10000.00 |  (nullable) |
| `min_applicable_price` | BIGINT | 40000.00 |  |
| `applied_currency` | VARCHAR | KRW | Enum: KRW, USD |
| `base_currency` | VARCHAR | KRW |  |
| `i18n` | VARCHAR (JSON) | {"results":[{"refId":null,"property":"couponDisplayName",... | JSON 형식 데이터 |
| `benefit_type` | VARCHAR | FIXED_RATE_DISCOUNT | Enum: FIXED_AMOUNT_DISCOUNT, FIXED_RATE_DISCOUNT |
| `coupon_type` | VARCHAR | CHECKOUT_COUPON |  |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%
- `discount_amount`: NULL 비율 75%
- `discount_rate`: NULL 비율 25%
- `max_discount_amount`: NULL 비율 25%

**Enum성 컬럼 값 목록:**
- `discount_rate`: 10.000 / 5.000
- `applied_currency`: KRW / USD
- `benefit_type`: FIXED_AMOUNT_DISCOUNT / FIXED_RATE_DISCOUNT

**JSON 형식 컬럼:**
- `applied_discount_amount`: JSON 형식 (구조 가변적)
- `base_currency_applied_discount_amount`: JSON 형식 (구조 가변적)
- `discount_amount`: JSON 형식 (구조 가변적)
- `discount_rate`: JSON 형식 (구조 가변적)
- `max_discount_amount`: JSON 형식 (구조 가변적)
- `i18n`: 주요 키 → `results`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  coupon_id,
  coupon_policy_id,
  order_line_id
FROM journi_y222.order_coupon_discount_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- discount_rate별 집계
SELECT
  discount_rate,
  COUNT(*) AS cnt
FROM journi_y222.order_coupon_discount_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY discount_rate
ORDER BY cnt DESC;
```

```sql
-- applied_discount_amount JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(applied_discount_amount, '$.key') AS applied_discount_amount_key
FROM journi_y222.order_coupon_discount_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND applied_discount_amount IS NOT NULL
LIMIT 100;
```
