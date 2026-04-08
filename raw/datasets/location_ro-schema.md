# location_ro 테이블
location_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.location_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 288466563808384 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-12 13:26:43.592 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-12 13:26:43.592 | 수정 일시 |
| `biz_partner_id` | BIGINT | 5 | biz_partner 참조 ID (FK) |
| `ref_id` | BIGINT | 288466563562624 | ref 참조 ID (FK) |
| `ref_type` | VARCHAR | WAREHOUSE |  |
| `operating_start_at` | TIMESTAMP | 2026-02-11 15:00:00.000 |  |
| `operating_end_at` | TIMESTAMP | 2026-02-17 15:00:00.000 |  |
| `pickup_method` | VARCHAR | BUTTON | Enum: BUTTON, SIGN |
| `log_date` | VARCHAR | 20260212 |  |

## 주의사항

**Enum성 컬럼 값 목록:**
- `pickup_method`: BUTTON / SIGN

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  biz_partner_id,
  ref_id,
  ref_type
FROM journi_y222.location_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- pickup_method별 집계
SELECT
  pickup_method,
  COUNT(*) AS cnt
FROM journi_y222.location_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY pickup_method
ORDER BY cnt DESC;
```
