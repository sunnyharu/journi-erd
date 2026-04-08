# artist_shop_ro 테이블
artist_shop_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.artist_shop_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 189357916043968 | 식별자 (PK) |
| `artistids` | VARCHAR | ['189351294458560', '189350933461696', '189351167261376',... |  |
| `communitykey` | VARCHAR | nowz | Enum: monstax, nowz, woodz ⚠️ NULL 포함 |
| `bizpartnerid` | BIGINT | 1758779013868 |  |
| `createdat` | TIMESTAMP | 2025-09-25 12:49:41.607 |  |
| `deletedat` | TIMESTAMP | 2025-11-19 04:17:28.390 |  ⚠️ NULL 포함 |
| `display` | BOOLEAN | false | Enum: false, true |
| `displaycommunitylinkbutton` | BOOLEAN | false | Enum: false, true |
| `i18n` | VARCHAR (JSON) | ['{"default":false,"property":"name","text":"NCT","type":... | JSON 형식 데이터 |
| `keywords` | VARCHAR | [] | Enum: ['ATEEZ', '에이티즈'], ['KANGTA'], ['NCT DREAM'], ['NOWZ', '나우즈'], ['몬엑', '몬엑샵', 'Monx샵', 'Monx', '몬베베샵'], [] |
| `mainimagepath` | VARCHAR | artist_shop/189357916043968/266180252581952.jpg |  |
| `mallid` | BIGINT | 189323979571392 |  |
| `slots` | VARCHAR (JSON) | [] | JSON 형식 데이터 |
| `topbanners` | VARCHAR (JSON) | ['{"display":true,"displayPeriod":{"endAt":"9999-12-31T23... | JSON 형식 데이터 |
| `updatedat` | TIMESTAMP | 2026-01-12 01:45:09.919 |  |
| `urlpath` | VARCHAR | nct |  |
| `communityid` | BIGINT | 14 | Enum: 10, 14, 4 ⚠️ NULL 포함 |
| `displayedat` | VARCHAR | 2026-01-13 00:34:12.405 | Enum: 2026-01-13 00:34:12.405, 2026-01-16 02:18:33.255, 2026-03-10 23:31:58.976, 2026-03-13 03:35:42.761, 2026-04-03 04:01:05.821, 2026-04-03 08:24:35.443 (nullable) |
| `ogimage` | VARCHAR | artist_shop/189371993905856/217528888063872.png | Enum: artist_shop/189371993905856/217528888063872.png, artist_shop/204678318532352/227449241090624.png, artist_shop/208216825921792/217383414201344.png, artist_shop/228523883594944/228523366278336.png, artist_shop/313154016138560/313783657998208.jpg ⚠️ NULL 포함 |

## 주의사항
- `deletedat`: NULL 비율 90%
- `communitykey`: NULL 비율 70%
- `communityid`: NULL 비율 70%
- `ogimage`: NULL 비율 50%
- `displayedat`: NULL 비율 30%

**Enum성 컬럼 값 목록:**
- `communitykey`: monstax / nowz / woodz
- `display`: false / true
- `displaycommunitylinkbutton`: false / true
- `keywords`: ['ATEEZ', '에이티즈'] / ['KANGTA'] / ['NCT DREAM'] / ['NOWZ', '나우즈'] / ['몬엑', '몬엑샵', 'Monx샵', 'Monx', '몬베베샵'] / []
- `communityid`: 10 / 14 / 4
- `displayedat`: 2026-01-13 00:34:12.405 / 2026-01-16 02:18:33.255 / 2026-03-10 23:31:58.976 / 2026-03-13 03:35:42.761 / 2026-04-03 04:01:05.821 / 2026-04-03 08:24:35.443 / 2026-04-06 02:42:00.205
- `ogimage`: artist_shop/189371993905856/217528888063872.png / artist_shop/204678318532352/227449241090624.png / artist_shop/208216825921792/217383414201344.png / artist_shop/228523883594944/228523366278336.png / artist_shop/313154016138560/313783657998208.jpg

**JSON 형식 컬럼:**
- `artistids`: JSON 형식 (구조 가변적)
- `i18n`: JSON 형식 (구조 가변적)
- `slots`: JSON 형식 (구조 가변적)
- `topbanners`: JSON 형식 (구조 가변적)
- `ogimage`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  artistids,
  communitykey,
  bizpartnerid,
  createdat,
  deletedat
FROM journi_y222.artist_shop_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- communitykey별 집계
SELECT
  communitykey,
  COUNT(*) AS cnt
FROM journi_y222.artist_shop_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY communitykey
ORDER BY cnt DESC;
```

```sql
-- artistids JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(artistids, '$.key') AS artistids_key
FROM journi_y222.artist_shop_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND artistids IS NOT NULL
LIMIT 100;
```
