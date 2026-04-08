# purchased_quantity_ro 테이블
purchased_quantity_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.purchased_quantity_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 293910707557248 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-20 06:02:51.918 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-20 11:56:58.354 | 수정 일시 |
| `order_id` | BIGINT | 293910420069441 | order 참조 ID (FK) |
| `order_line_id` | BIGINT | 293910420069442 | order_line 참조 ID (FK) |
| `product_id` | BIGINT | 287556887982144 | product 참조 ID (FK) |
| `product_item_id` | BIGINT | 287556888596544 | product_item 참조 ID (FK) |
| `user_id` | BIGINT | 1393125268141747968 | user 참조 ID (FK) |
| `canceled_quantity` | BIGINT | 1 | Enum: 0, 1 |
| `ordered_quantity` | BIGINT | 1 | Enum: 1, 2 |
| `version` | BIGINT | 1 | Enum: 0, 1 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `canceled_quantity`: 0 / 1
- `ordered_quantity`: 1 / 2
- `version`: 0 / 1

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  order_id,
  order_line_id,
  product_id
FROM journi_y222.purchased_quantity_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- canceled_quantity별 집계
SELECT
  canceled_quantity,
  COUNT(*) AS cnt
FROM journi_y222.purchased_quantity_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY canceled_quantity
ORDER BY cnt DESC;
```
