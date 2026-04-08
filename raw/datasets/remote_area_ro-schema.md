# remote_area_ro 테이블
remote_area_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.remote_area_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 202 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-04-24 02:32:54.425 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-04-24 02:32:54.425 | 수정 일시 |
| `address` | VARCHAR | 전라남도 완도군 노화읍 |  |
| `delivery_company` | VARCHAR | CJGLS |  |
| `type` | VARCHAR | REMOTE | 유형 구분 |

## 주의사항

**JSON 형식 컬럼:**
- `address`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  address,
  delivery_company,
  type
FROM journi_y222.remote_area_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.remote_area_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```

```sql
-- address JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(address, '$.key') AS address_key
FROM journi_y222.remote_area_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND address IS NOT NULL
LIMIT 100;
```
