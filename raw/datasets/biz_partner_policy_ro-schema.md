# biz_partner_policy_ro 테이블
biz_partner_policy_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.biz_partner_policy_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 320870277080064 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-30 08:12:15.001 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-30 08:29:27.087 | 수정 일시 |
| `biz_partner_id` | BIGINT | 1770623494828 | biz_partner 참조 ID (FK) |
| `auto_order_approval` | BIGINT | 1 |  |
| `auto_order_approval_hour` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `conditional_free_threshold` | BIGINT | 50000.00 |  |
| `delivery_fee` | BIGINT | 3000.00 |  |
| `jeju_additional_amount` | BIGINT | 3000.00 |  |
| `remote_area_additional_amount` | BIGINT | 4000.00 |  |
| `return_fee` | BIGINT | 3000.00 |  |

## 주의사항
- `auto_order_approval_hour`: NULL 비율 100%

**JSON 형식 컬럼:**
- `conditional_free_threshold`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  biz_partner_id,
  auto_order_approval,
  auto_order_approval_hour
FROM journi_y222.biz_partner_policy_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.biz_partner_policy_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```

```sql
-- conditional_free_threshold JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(conditional_free_threshold, '$.key') AS conditional_free_threshold_key
FROM journi_y222.biz_partner_policy_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND conditional_free_threshold IS NOT NULL
LIMIT 100;
```
