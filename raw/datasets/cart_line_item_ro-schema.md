# cart_line_item_ro 테이블
cart_line_item_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.cart_line_item_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 282551181098177 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-04 04:51:50.974 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-04 04:51:50.974 | 수정 일시 |
| `cart_line_id` | BIGINT | 282551181098176 | cart_line 참조 ID (FK) |
| `product_option_item_id` | BIGINT | 282444878259841 | product_option_item 참조 ID (FK) |
| `value` | VARCHAR | Df | Enum:  b, Cx, Ddd, Df, ㅂㅈ, ㅎㅎ (nullable) |
| `log_date` | VARCHAR | 20260204 |  |

## 주의사항
- `value`: NULL 비율 20%

**Enum성 컬럼 값 목록:**
- `value`:  b / Cx / Ddd / Df / ㅂㅈ / ㅎㅎ / 가나다라마가나다라마 / 일이삼사오육칠팔구십

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  cart_line_id,
  product_option_item_id,
  value
FROM journi_y222.cart_line_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- value별 집계
SELECT
  value,
  COUNT(*) AS cnt
FROM journi_y222.cart_line_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY value
ORDER BY cnt DESC;
```
