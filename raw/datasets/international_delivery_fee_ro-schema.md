# international_delivery_fee_ro 테이블
international_delivery_fee_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.international_delivery_fee_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 736 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-11-05 02:35:45.000 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-11-05 02:35:45.000 | 수정 일시 |
| `fee` | BIGINT | 105280.00 |  |
| `min_weight` | DOUBLE | 20.000 |  |
| `zone_code` | VARCHAR | P | Enum: A, H, J, P, Q, X |

## 주의사항

**Enum성 컬럼 값 목록:**
- `zone_code`: A / H / J / P / Q / X / Y / Z

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  fee,
  min_weight,
  zone_code
FROM journi_y222.international_delivery_fee_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- zone_code별 집계
SELECT
  zone_code,
  COUNT(*) AS cnt
FROM journi_y222.international_delivery_fee_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY zone_code
ORDER BY cnt DESC;
```
