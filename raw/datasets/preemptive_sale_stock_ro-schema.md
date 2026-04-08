# preemptive_sale_stock_ro 테이블
preemptive_sale_stock_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.preemptive_sale_stock_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 262767598003717 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-01-07 06:02:02.812 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-01-07 06:04:31.926 | 수정 일시 |
| `checkout_id` | BIGINT | 262767550309888 | checkout 참조 ID (FK) |
| `product_id` | BIGINT | 261996258205248 | product 참조 ID (FK) |
| `product_item_id` | BIGINT | 261996258328128 | product_item 참조 ID (FK) |
| `quantity` | BIGINT | 1 | 수량 |
| `expiration_time` | VARCHAR | 1767766022757 |  |
| `status` | VARCHAR | CONFIRMED | 상태값 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `quantity`: 1 / 5
- `status`: CONFIRMED / PENDING

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  checkout_id,
  product_id,
  product_item_id
FROM journi_y222.preemptive_sale_stock_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.preemptive_sale_stock_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```
