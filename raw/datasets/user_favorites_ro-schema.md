# user_favorites_ro 테이블
user_favorites_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.user_favorites_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 243146644165568 | 식별자 (PK) |
| `artistshopfavorites` | VARCHAR | ['226520949288896'] | Enum: ['189356575242944'], ['189371094227648', '139766400628480', '189370806205120'], ['204678854043392', '189357132962496'], ['204678854043392'], ['224527152959424'], ['226520949288896'] |
| `mallfavorites` | VARCHAR | [] | Enum: ['286978355384384'], [] |

## 주의사항

**Enum성 컬럼 값 목록:**
- `artistshopfavorites`: ['189356575242944'] / ['189371094227648', '139766400628480', '189370806205120'] / ['204678854043392', '189357132962496'] / ['204678854043392'] / ['224527152959424'] / ['226520949288896'] / []
- `mallfavorites`: ['286978355384384'] / []

**JSON 형식 컬럼:**
- `artistshopfavorites`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  artistshopfavorites,
  mallfavorites
FROM journi_y222.user_favorites_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- artistshopfavorites별 집계
SELECT
  artistshopfavorites,
  COUNT(*) AS cnt
FROM journi_y222.user_favorites_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY artistshopfavorites
ORDER BY cnt DESC;
```

```sql
-- artistshopfavorites JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(artistshopfavorites, '$.key') AS artistshopfavorites_key
FROM journi_y222.user_favorites_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND artistshopfavorites IS NOT NULL
LIMIT 100;
```
