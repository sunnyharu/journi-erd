# notice_ro 테이블
notice_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.notice_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 5
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 202536108835840 | 식별자 (PK) |
| `admintitle` | VARCHAR | 테스트샵홈공지#25 | Enum: 2025 정승환의 안녕, 겨울 : 사랑이라 불린 OFFICIAL MD 판매 안내, 공지입니다., 제이스 공지입니다. 35, 제이스 공지입니다. 39, 테스트샵홈공지#25 |
| `bizpartnerid` | BIGINT | 3 | Enum: 3, 5 (nullable) |
| `createdat` | TIMESTAMP | 2025-10-14 03:40:46.098 |  |
| `deletedat` | TIMESTAMP | 2025-11-17 14:01:34.868 |  (nullable) |
| `displaytarget` | VARCHAR | ['HOME', None] | Enum: ['ARTIST_SHOP', 139766400628485], ['ARTIST_SHOP', 184830871949440], ['ARTIST_SHOP', 189801601228288], ['HOME', None] |
| `i18n` | VARCHAR (JSON) | ['{"default":false,"property":"title","text":"테스트샵홈공지#25"... | JSON 형식 데이터 |
| `ispinned` | BOOLEAN | false |  |
| `maindisplay` | BOOLEAN | true |  |
| `postdate` | VARCHAR | 2025-10-14 03:40:35.719 | Enum: 2025-09-25 00:29:22.922, 2025-09-26 07:45:25.436, 2025-09-26 07:47:01.209, 2025-10-14 03:40:35.719, 2025-12-19 01:00:00.000 |
| `updatedat` | TIMESTAMP | 2025-11-17 14:01:34.868 |  |

## 주의사항
- `bizpartnerid`: NULL 비율 20%
- `deletedat`: NULL 비율 20%

**Enum성 컬럼 값 목록:**
- `admintitle`: 2025 정승환의 안녕, 겨울 : 사랑이라 불린 OFFICIAL MD 판매 안내 / 공지입니다. / 제이스 공지입니다. 35 / 제이스 공지입니다. 39 / 테스트샵홈공지#25
- `bizpartnerid`: 3 / 5
- `displaytarget`: ['ARTIST_SHOP', 139766400628485] / ['ARTIST_SHOP', 184830871949440] / ['ARTIST_SHOP', 189801601228288] / ['HOME', None]
- `postdate`: 2025-09-25 00:29:22.922 / 2025-09-26 07:45:25.436 / 2025-09-26 07:47:01.209 / 2025-10-14 03:40:35.719 / 2025-12-19 01:00:00.000

**JSON 형식 컬럼:**
- `displaytarget`: JSON 형식 (구조 가변적)
- `i18n`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  admintitle,
  bizpartnerid,
  createdat,
  deletedat,
  displaytarget
FROM journi_y222.notice_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- admintitle별 집계
SELECT
  admintitle,
  COUNT(*) AS cnt
FROM journi_y222.notice_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY admintitle
ORDER BY cnt DESC;
```

```sql
-- displaytarget JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(displaytarget, '$.key') AS displaytarget_key
FROM journi_y222.notice_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND displaytarget IS NOT NULL
LIMIT 100;
```
