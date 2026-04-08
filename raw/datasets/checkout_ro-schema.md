# checkout_ro 테이블
주문서(체크아웃) 정보. 결제 전 주문 생성 단계. 배송지, 쿠폰, 금액 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.checkout_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 319385810271680 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-28 05:52:05.671 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-28 05:52:05.671 | 수정 일시 |
| `user_id` | BIGINT | 319384419986304 | user 참조 ID (FK) |
| `checkout_data` | VARCHAR (JSON) | {"bundles":[{"id":319385810132418,"checkoutLines":[{"id":... | JSON 형식 데이터 |
| `currency` | VARCHAR | USD | 통화 코드 |
| `exchange_rates` | VARCHAR | KRW/KRW=1.0000000000;KRW/USD=0.0007407407;USD/KRW=1350.00... | Enum: 100JPY/KRW=880.0000000000;KRW/JPY=0.1136363636;KRW/KRW=1.0000000000, KRW/KRW=1.0000000000, KRW/KRW=1.0000000000;KRW/USD=0.0007407407;USD/KRW=1350.0000000000 |
| `receiving_type` | VARCHAR | NONE | Enum: DELIVERY, NONE |
| `source_type` | VARCHAR | PRODUCT_DETAIL | Enum: CART, PRODUCT_DETAIL |
| `status` | VARCHAR | CREATED | 상태값 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20260328 |  |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `currency`: JPY / KRW / USD
- `exchange_rates`: 100JPY/KRW=880.0000000000;KRW/JPY=0.1136363636;KRW/KRW=1.0000000000 / KRW/KRW=1.0000000000 / KRW/KRW=1.0000000000;KRW/USD=0.0007407407;USD/KRW=1350.0000000000
- `receiving_type`: DELIVERY / NONE
- `source_type`: CART / PRODUCT_DETAIL
- `status`: COMPLETED / CREATED

**JSON 형식 컬럼:**
- `checkout_data`: 주요 키 → `applicableCoupons`, `bundles`, `eventPolicyId`, `fanClubInfos`, `fanClubKey`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  user_id,
  checkout_data,
  currency
FROM journi_y222.checkout_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- currency별 집계
SELECT
  currency,
  COUNT(*) AS cnt
FROM journi_y222.checkout_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY currency
ORDER BY cnt DESC;
```

```sql
-- checkout_data JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(checkout_data, '$.bundles') AS checkout_data_bundles,
  json_extract_scalar(checkout_data, '$.applicableCoupons') AS checkout_data_applicableCoupons,
  json_extract_scalar(checkout_data, '$.fanClubInfos') AS checkout_data_fanClubInfos,
  json_extract_scalar(checkout_data, '$.fanClubKey') AS checkout_data_fanClubKey,
  json_extract_scalar(checkout_data, '$.eventPolicyId') AS checkout_data_eventPolicyId
FROM journi_y222.checkout_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND checkout_data IS NOT NULL
LIMIT 100;
```
