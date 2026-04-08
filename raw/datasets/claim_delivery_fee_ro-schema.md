# claim_delivery_fee_ro 테이블
claim_delivery_fee_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.claim_delivery_fee_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 267831046327041 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-01-14 09:43:39.891 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-01-14 09:43:39.967 | 수정 일시 |
| `claim_id` | BIGINT | 267831046163200 | claim 참조 ID (FK) |
| `order_bundle_id` | BIGINT | 267827484210817 | order_bundle 참조 ID (FK) |
| `refunded_delivery_fee` | BIGINT | 0.00 |  |
| `return_delivery_fee` | BIGINT | 0.00 |  |
| `currency` | VARCHAR | KRW | 통화 코드 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `currency`: JPY / KRW

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  claim_id,
  order_bundle_id,
  refunded_delivery_fee
FROM journi_y222.claim_delivery_fee_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- currency별 집계
SELECT
  currency,
  COUNT(*) AS cnt
FROM journi_y222.claim_delivery_fee_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY currency
ORDER BY cnt DESC;
```
