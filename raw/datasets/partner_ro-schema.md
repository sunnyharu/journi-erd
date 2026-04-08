# partner_ro 테이블
파트너(공급사/브랜드) 기본 정보.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.partner_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 2

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `partner_id` | BIGINT | 5 | partner 참조 ID (FK) |
| `created_at` | TIMESTAMP | 2025-03-12 06:01:05.071 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-03-12 06:01:05.057 | 수정 일시 |
| `name` | VARCHAR | TEST | Enum: TEST, 피나클엔터테인먼트 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `name`: TEST / 피나클엔터테인먼트

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  partner_id,
  created_at,
  updated_at,
  name
FROM journi_y222.partner_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- name별 집계
SELECT
  name,
  COUNT(*) AS cnt
FROM journi_y222.partner_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY name
ORDER BY cnt DESC;
```
