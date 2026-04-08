# collection_ro 테이블
collection_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.collection_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 5
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 227257695219776 | 식별자 (PK) |
| `bizpartnerid` | BIGINT | 1758779013868 |  |
| `createdat` | TIMESTAMP | 2025-11-18 01:56:58.799 |  |
| `deletedat` | TIMESTAMP | 2025-11-19 04:16:36.310 |  ⚠️ NULL 포함 |
| `display` | BOOLEAN | true |  ⚠️ NULL 포함 |
| `displayperiod` | VARCHAR | [253402300799000, 1773023400000] | Enum: [253402300799000, 1770191760000], [253402300799000, 1771897800000], [253402300799000, 1773023400000] ⚠️ NULL 포함 |
| `i18n` | VARCHAR (JSON) | ['{"default":false,"property":"name","text":"WayV Winter ... | JSON 형식 데이터 |
| `mallid` | BIGINT | 189323979571392 |  |
| `ogimage` | VARCHAR | collection/303811778140416/305850668389632.jpg |  ⚠️ NULL 포함 |
| `products` | VARCHAR | ['{"order":1,"productId":239299377872960}', '{"order":2,"... |  |
| `topimage` | VARCHAR (JSON) | [['#353535'], 'collection/227257695219776/227430740132352... | JSON 형식 데이터 |
| `updatedat` | TIMESTAMP | 2025-12-05 09:43:02.365 |  |
| `urlpath` | VARCHAR | wayvwinterspecialalbum | Enum: axzkga44ll, frequency, vl5cedj532, wayvwinterspecialalbum, z03iloy6mi |

## 주의사항
- `ogimage`: NULL 비율 80%
- `deletedat`: NULL 비율 60%
- `display`: NULL 비율 40%
- `displayperiod`: NULL 비율 40%

**Enum성 컬럼 값 목록:**
- `displayperiod`: [253402300799000, 1770191760000] / [253402300799000, 1771897800000] / [253402300799000, 1773023400000]
- `urlpath`: axzkga44ll / frequency / vl5cedj532 / wayvwinterspecialalbum / z03iloy6mi

**JSON 형식 컬럼:**
- `displayperiod`: JSON 형식 (구조 가변적)
- `i18n`: JSON 형식 (구조 가변적)
- `ogimage`: JSON 형식 (구조 가변적)
- `products`: JSON 형식 (구조 가변적)
- `topimage`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  bizpartnerid,
  createdat,
  deletedat,
  display,
  displayperiod
FROM journi_y222.collection_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- displayperiod별 집계
SELECT
  displayperiod,
  COUNT(*) AS cnt
FROM journi_y222.collection_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY displayperiod
ORDER BY cnt DESC;
```

```sql
-- displayperiod JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(displayperiod, '$.key') AS displayperiod_key
FROM journi_y222.collection_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND displayperiod IS NOT NULL
LIMIT 100;
```
