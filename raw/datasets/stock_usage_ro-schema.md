# stock_usage_ro 테이블
stock_usage_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.stock_usage_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 264033835469891 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-01-09 00:58:12.806 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-01-09 00:58:12.806 | 수정 일시 |
| `ref_id` | BIGINT | 264033835453510 | ref 참조 ID (FK) |
| `sku_id` | BIGINT | 172865588495808 | sku 참조 ID (FK) |
| `stock_id` | BIGINT | 259209066225216 | stock 참조 ID (FK) |
| `after_quantity` | BIGINT | 4596 |  |
| `before_quantity` | BIGINT | 4597 |  |
| `delta` | BIGINT | -1 | Enum: -1, -10, -2, -3 |
| `ref_type` | VARCHAR | OUTGOING |  |
| `type` | VARCHAR | OUTGOING_REQUESTED | 유형 구분 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `delta`: -1 / -10 / -2 / -3
- `type`: OUTGOING_COMPLETED / OUTGOING_REQUESTED

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  ref_id,
  sku_id,
  stock_id
FROM journi_y222.stock_usage_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- delta별 집계
SELECT
  delta,
  COUNT(*) AS cnt
FROM journi_y222.stock_usage_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY delta
ORDER BY cnt DESC;
```
