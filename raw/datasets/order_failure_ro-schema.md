# order_failure_ro 테이블
order_failure_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.order_failure_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 316558054218432 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-24 05:59:00.602 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-24 05:59:00.602 | 수정 일시 |
| `order_id` | BIGINT | 316557590557697 | order 참조 ID (FK) |
| `error_code` | VARCHAR | PAYMENT_PG_COMPLETE_FAILED | Enum: CAN_NOT_CANCEL_ORDER, PAYMENT_PG_COMPLETE_FAILED |
| `message` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `cause_type` | VARCHAR | PG_ERROR | Enum: DOMAIN_ERROR, PG_ERROR |
| `step` | VARCHAR | ORDER | Enum: CANCEL, ORDER |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20260324 |  |

## 주의사항
- `message`: NULL 비율 100%
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `error_code`: CAN_NOT_CANCEL_ORDER / PAYMENT_PG_COMPLETE_FAILED
- `cause_type`: DOMAIN_ERROR / PG_ERROR
- `step`: CANCEL / ORDER

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  order_id,
  error_code,
  message
FROM journi_y222.order_failure_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- error_code별 집계
SELECT
  error_code,
  COUNT(*) AS cnt
FROM journi_y222.order_failure_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY error_code
ORDER BY cnt DESC;
```
