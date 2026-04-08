# cart_line_ro 테이블
cart_line_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.cart_line_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 315936897055616 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-23 08:55:15.753 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-23 08:55:15.753 | 수정 일시 |
| `cart_id` | BIGINT | 315936737248640 | cart 참조 ID (FK) |
| `mall_id` | BIGINT | 313129886381376 | mall 참조 ID (FK) |
| `product_id` | BIGINT | 313177976500288 | product 참조 ID (FK) |
| `product_item_id` | BIGINT | 313177976606784 | product_item 참조 ID (FK) |
| `quantity` | BIGINT | 1 | 수량 |
| `selected` | BIGINT | 1 | Enum: 0, 1 |
| `added_at` | TIMESTAMP | 2026-03-23 08:55:15.753 |  |
| `log_date` | VARCHAR | 20260323 |  |

## 주의사항

**Enum성 컬럼 값 목록:**
- `selected`: 0 / 1

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  cart_id,
  mall_id,
  product_id
FROM journi_y222.cart_line_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- selected별 집계
SELECT
  selected,
  COUNT(*) AS cnt
FROM journi_y222.cart_line_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY selected
ORDER BY cnt DESC;
```
