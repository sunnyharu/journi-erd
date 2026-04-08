# pg_currency_ro 테이블
pg_currency_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.pg_currency_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 1389290687090434048 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-06-30 17:05:11.576 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-06-30 17:05:11.576 | 수정 일시 |
| `pg_payment_method_id` | BIGINT | 1389290687090434048 | pg_payment_method 참조 ID (FK) |
| `currency` | VARCHAR | KRW | 통화 코드 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `currency`: KRW / USD

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  pg_payment_method_id,
  currency,
  deleted_at
FROM journi_y222.pg_currency_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- currency별 집계
SELECT
  currency,
  COUNT(*) AS cnt
FROM journi_y222.pg_currency_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY currency
ORDER BY cnt DESC;
```
