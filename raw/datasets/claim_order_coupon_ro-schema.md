# claim_order_coupon_ro 테이블
claim_order_coupon_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.claim_order_coupon_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 322999663757251 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-04-02 08:24:32.469 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-04-02 08:24:32.540 | 수정 일시 |
| `claim_id` | BIGINT | 322999663617984 | claim 참조 ID (FK) |
| `coupon_id` | BIGINT | 313759606804416 | coupon 참조 ID (FK) |
| `cancel_amount` | DOUBLE | 1.92 |  |
| `cancel_currency` | VARCHAR | USD | Enum: KRW, USD |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `order_line_id` | BIGINT | 322954206622280 | order_line 참조 ID (FK) |
| `coupon_type` | VARCHAR | CHECKOUT_COUPON |  |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `cancel_currency`: KRW / USD

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  claim_id,
  coupon_id,
  cancel_amount
FROM journi_y222.claim_order_coupon_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- cancel_currency별 집계
SELECT
  cancel_currency,
  COUNT(*) AS cnt
FROM journi_y222.claim_order_coupon_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY cancel_currency
ORDER BY cnt DESC;
```
