# community_artist_ro 테이블
community_artist_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.community_artist_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 1

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `community_artist_id` | BIGINT | 1 | community_artist 참조 ID (FK) |
| `created_at` | TIMESTAMP | 2025-02-10 11:16:52 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-11-07 11:39:21 | 수정 일시 |
| `community_id` | BIGINT | 1 | community 참조 ID (FK) |
| `user_id` | BIGINT | 149743433867264 | user 참조 ID (FK) |
| `artist_id` | BIGINT | 1 | artist 참조 ID (FK) |
| `name` | VARCHAR | 정씨 |  |
| `name_set` | VARCHAR | [{"ko":"정"},{"en":"Jung "}] |  |
| `tag_set` | VARCHAR | [{"tag":"정","tagBgColor":""},{"tag":"Jung ","tagBgColor":... |  |
| `is_displayed` | BIGINT | 1 |  |
| `display_order` | BIGINT | 0 |  |
| `is_push_enabled` | BIGINT | 1 |  |

## 주의사항

**JSON 형식 컬럼:**
- `name_set`: 주요 키 → `ko`
- `tag_set`: 주요 키 → `tag`, `tagBgColor`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  community_artist_id,
  created_at,
  updated_at,
  community_id,
  user_id,
  artist_id
FROM journi_y222.community_artist_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- name_set JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(name_set, '$.key') AS name_set_key
FROM journi_y222.community_artist_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND name_set IS NOT NULL
LIMIT 100;
```
