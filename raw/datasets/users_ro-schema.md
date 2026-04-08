# users_ro 테이블
회원 기본 정보 테이블. 가입 국가, 회원 키, 상태, 접속 IP 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.users_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 244440395324864 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-12-12 08:35:15.444 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-12-12 08:35:15.444 | 수정 일시 |
| `country` | VARCHAR | ID | 국가 코드 |
| `member_key` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `status` | VARCHAR | ACTIVATED | 상태값 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `deactivated_at` | TIMESTAMP | 2025-09-27 05:03:38.063 |  ⚠️ NULL 포함 |

## 주의사항
- `member_key`: NULL 비율 100%
- `deleted_at`: NULL 비율 100%
- `deactivated_at`: NULL 비율 90%

**Enum성 컬럼 값 목록:**
- `country`: ID / IN / JP / KR / RO / SA / TW / US
- `status`: ACTIVATED / DEACTIVATED

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  country,
  member_key,
  status
FROM journi_y222.users_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- country별 집계
SELECT
  country,
  COUNT(*) AS cnt
FROM journi_y222.users_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY country
ORDER BY cnt DESC;
```
