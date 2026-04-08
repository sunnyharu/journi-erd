# artist_ro 테이블
아티스트 기본 정보. 이름, 프로필, 이미지 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.artist_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 5
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 189350116145856 | 식별자 (PK) |
| `artistid` | BIGINT | 97 |  |
| `artistname` | VARCHAR | TVXQ! | Enum: GIRLS' GENERATION, KiiiKiii, TVXQ!, WayV, 최유리 |
| `bizpartnerid` | BIGINT | 1758779013868 |  |
| `createdat` | TIMESTAMP | 2025-09-25 12:33:47.859 |  |
| `deletedat` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `i18n` | VARCHAR (JSON) | ['{"default":false,"property":"name","text":"TVXQ!","type... | JSON 형식 데이터 |
| `mallid` | BIGINT | 189323979571392 |  |
| `updatedat` | TIMESTAMP | 2025-09-25 12:33:47.859 |  |

## 주의사항
- `deletedat`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `artistname`: GIRLS' GENERATION / KiiiKiii / TVXQ! / WayV / 최유리

**JSON 형식 컬럼:**
- `i18n`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  artistid,
  artistname,
  bizpartnerid,
  createdat,
  deletedat
FROM journi_y222.artist_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- artistname별 집계
SELECT
  artistname,
  COUNT(*) AS cnt
FROM journi_y222.artist_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY artistname
ORDER BY cnt DESC;
```

```sql
-- i18n JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(i18n, '$.key') AS i18n_key
FROM journi_y222.artist_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND i18n IS NOT NULL
LIMIT 100;
```
