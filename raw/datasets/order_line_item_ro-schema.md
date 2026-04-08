# order_line_item_ro 테이블
주문 내 개별 상품 라인. 수량, 단가, 할인, 상태 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.order_line_item_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 293911420781316 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-20 06:04:18.998 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-20 06:04:18.998 | 수정 일시 |
| `order_line_id` | BIGINT | 293911420781314 | order_line 참조 ID (FK) |
| `product_option_item_id` | BIGINT | 293259722813572 | product_option_item 참조 ID (FK) |
| `display_order` | BIGINT | 0 | Enum: 0, 1 |
| `required` | BIGINT | 1 |  |
| `option_name` | VARCHAR | CELEB | Enum: CELEB, Member, Option, Pick-up Time, 사이즈 |
| `option_value` | VARCHAR | YUSHI |  |
| `option_type` | VARCHAR | SELECT |  |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `select_option_type` | VARCHAR | TEXT | Enum: DATETIME, TEXT |
| `log_date` | VARCHAR | 20260220 |  |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `display_order`: 0 / 1
- `option_name`: CELEB / Member / Option / Pick-up Time / 사이즈
- `select_option_type`: DATETIME / TEXT

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  order_line_id,
  product_option_item_id,
  display_order
FROM journi_y222.order_line_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- display_order별 집계
SELECT
  display_order,
  COUNT(*) AS cnt
FROM journi_y222.order_line_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY display_order
ORDER BY cnt DESC;
```
