# contract_project_ro 테이블
contract_project_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.contract_project_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 5
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 193984833249984 | 식별자 (PK) |
| `bizpartnerid` | BIGINT | 1758779013868 |  |
| `createdat` | TIMESTAMP | 2025-10-02 01:43:09.215 |  |
| `deletedat` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `name` | VARCHAR | 25_예성_콘서트MD | Enum: 22_데뷔기념MD, 25_ae_라이선스MD, 25_시즌그리팅_기획MD, 25_예성_콘서트MD, 26_NJ_앨범MD |
| `status` | VARCHAR | ACTIVE | 상태값 |
| `subprojects` | VARCHAR | ['{"_id":193984833249985,"artists":[{"berrizArtistId":98,... |  |
| `updatedat` | TIMESTAMP | 2025-10-02 01:43:09.215 |  |

## 주의사항
- `deletedat`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `name`: 22_데뷔기념MD / 25_ae_라이선스MD / 25_시즌그리팅_기획MD / 25_예성_콘서트MD / 26_NJ_앨범MD

**JSON 형식 컬럼:**
- `subprojects`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  bizpartnerid,
  createdat,
  deletedat,
  name,
  status
FROM journi_y222.contract_project_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- name별 집계
SELECT
  name,
  COUNT(*) AS cnt
FROM journi_y222.contract_project_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY name
ORDER BY cnt DESC;
```

```sql
-- subprojects JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(subprojects, '$.key') AS subprojects_key
FROM journi_y222.contract_project_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND subprojects IS NOT NULL
LIMIT 100;
```
