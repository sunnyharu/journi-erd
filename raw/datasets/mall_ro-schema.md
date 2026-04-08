# mall_ro 테이블
쇼핑몰(브랜드/파트너) 기본 정보. i18n(다국어), 배너, 카테고리, URL 경로 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.mall_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 281890899123200 | 식별자 (PK) |
| `artistshopdisplayconfig` | VARCHAR | ['[]', 'MANUAL', 'MANUAL'] |  |
| `bizpartnerid` | BIGINT | 5 |  |
| `categories` | VARCHAR (JSON) | ['{"_id":281890899123201,"children":[{"_id":2818908991232... | JSON 형식 데이터 |
| `createdat` | TIMESTAMP | 2026-02-03 06:28:30.783 |  |
| `deletedat` | TIMESTAMP | 2025-11-10 01:59:46.802 |  ⚠️ NULL 포함 |
| `display` | BOOLEAN | true | Enum: false, true |
| `i18n` | VARCHAR (JSON) | ['{"default":true,"property":"name","text":"QAent(artist ... | JSON 형식 데이터 |
| `images` | VARCHAR (JSON) | ['{"order":0,"savedPath":"mall/281890899123200/2825465592... | JSON 형식 데이터 |
| `slots` | VARCHAR (JSON) | ['{"displayName":"0309","displayPeriod":{"endAt":25340230... | JSON 형식 데이터 |
| `topbanners` | VARCHAR (JSON) | ['{"display":true,"gradationCode":{"code":"#2E2E2E"},"i18... | JSON 형식 데이터 |
| `updatedat` | TIMESTAMP | 2026-03-23 09:47:42.731 |  |
| `urlpath` | VARCHAR | qaent |  |
| `profile` | VARCHAR | cbt | Enum: cbt, prod |
| `ogimage` | VARCHAR | mall/281890899123200/282546559231616.jpeg | Enum: mall/172845827655104/228204661529792.png, mall/189323979571392/207454773567360.png, mall/228522710869184/228522652271808.png, mall/281890899123200/282546559231616.jpeg, mall/286978355384384/296275569005376.png, mall/313761238540416/316476036235136.jpg (nullable) |

## 주의사항
- `deletedat`: NULL 비율 90%
- `ogimage`: NULL 비율 30%

**Enum성 컬럼 값 목록:**
- `display`: false / true
- `profile`: cbt / prod
- `ogimage`: mall/172845827655104/228204661529792.png / mall/189323979571392/207454773567360.png / mall/228522710869184/228522652271808.png / mall/281890899123200/282546559231616.jpeg / mall/286978355384384/296275569005376.png / mall/313761238540416/316476036235136.jpg / mall/317849831562304/321592092393536.jpg

**JSON 형식 컬럼:**
- `artistshopdisplayconfig`: JSON 형식 (구조 가변적)
- `categories`: JSON 형식 (구조 가변적)
- `i18n`: JSON 형식 (구조 가변적)
- `images`: JSON 형식 (구조 가변적)
- `slots`: JSON 형식 (구조 가변적)
- `topbanners`: JSON 형식 (구조 가변적)
- `profile`: JSON 형식 (구조 가변적)
- `ogimage`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  artistshopdisplayconfig,
  bizpartnerid,
  categories,
  createdat,
  deletedat
FROM journi_y222.mall_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- display별 집계
SELECT
  display,
  COUNT(*) AS cnt
FROM journi_y222.mall_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY display
ORDER BY cnt DESC;
```

```sql
-- artistshopdisplayconfig JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(artistshopdisplayconfig, '$.key') AS artistshopdisplayconfig_key
FROM journi_y222.mall_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND artistshopdisplayconfig IS NOT NULL
LIMIT 100;
```
