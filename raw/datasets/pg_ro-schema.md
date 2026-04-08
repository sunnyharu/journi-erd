# pg_ro 테이블
pg_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.pg_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 3
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 1389288987344544000 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-06-30 16:58:26.324 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-06-30 16:58:26.324 | 수정 일시 |
| `name` | VARCHAR | 0원 결제 |  ⚠️ NULL 포함 |
| `code` | VARCHAR | EXIMBAY | Enum: EXIMBAY, NICEPAY, ZERO_PAYMENT |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%
- `name`: NULL 비율 67%

**Enum성 컬럼 값 목록:**
- `code`: EXIMBAY / NICEPAY / ZERO_PAYMENT

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  name,
  code,
  deleted_at
FROM journi_y222.pg_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- code별 집계
SELECT
  code,
  COUNT(*) AS cnt
FROM journi_y222.pg_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY code
ORDER BY cnt DESC;
```
