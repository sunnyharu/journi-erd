# international_dim_factor_ro 테이블
international_dim_factor_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.international_dim_factor_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 12 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-06-30 17:08:03.250 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-11-05 02:33:22.177 | 수정 일시 |
| `dim_factor` | BIGINT | 4000 |  |
| `zone_code` | VARCHAR | L |  |

## 주의사항
- 특이사항 없음

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  dim_factor,
  zone_code
FROM journi_y222.international_dim_factor_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.international_dim_factor_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```
