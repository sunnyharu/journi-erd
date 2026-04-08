# platform_category_ro 테이블
platform_category_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.platform_category_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 8030 | 식별자 (PK) |
| `createdat` | TIMESTAMP | 2026-01-23 06:00:00.000 |  |
| `deletedat` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `level` | BIGINT | 2 | Enum: 1, 2 |
| `name` | VARCHAR | Beauty Tool |  |
| `parentid` | BIGINT | 8000 |  (nullable) |
| `updatedat` | TIMESTAMP | 2026-01-23 06:00:00.000 |  |
| `policies` | VARCHAR | ['SYNC_CHART_DATA'] |  ⚠️ NULL 포함 |

## 주의사항
- `deletedat`: NULL 비율 100%
- `policies`: NULL 비율 90%
- `parentid`: NULL 비율 30%

**Enum성 컬럼 값 목록:**
- `level`: 1 / 2

**JSON 형식 컬럼:**
- `policies`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  createdat,
  deletedat,
  level,
  name,
  parentid
FROM journi_y222.platform_category_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- level별 집계
SELECT
  level,
  COUNT(*) AS cnt
FROM journi_y222.platform_category_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY level
ORDER BY cnt DESC;
```

```sql
-- policies JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(policies, '$.key') AS policies_key
FROM journi_y222.platform_category_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND policies IS NOT NULL
LIMIT 100;
```
