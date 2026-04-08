# outgoing_item_ro 테이블
outgoing_item_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.outgoing_item_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 7
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 293138743322370 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-19 03:52:18.133 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-21 05:42:43.374 | 수정 일시 |
| `outgoing_id` | BIGINT | 293138743322371 | outgoing 참조 ID (FK) |
| `sku_id` | BIGINT | 283850883543872 | sku 참조 ID (FK) |
| `quantity` | BIGINT | 10 | 수량 |
| `outgoing_quantity` | BIGINT | 10 | Enum: 1, 10, 2, 25 (nullable) |
| `ref_type` | VARCHAR | ORDER_LINE | Enum: ORDER_LINE, REWARD (nullable) |
| `ref_id` | BIGINT | 287716667066966 | ref 참조 ID (FK) (nullable) |
| `expected_start_date_time` | TIMESTAMP | 2026-02-21 04:00:00.000 |  ⚠️ NULL 포함 |
| `expected_end_date_time` | TIMESTAMP | 2026-03-31 14:59:59.999 |  ⚠️ NULL 포함 |
| `order_item_snapshot` | VARCHAR (JSON) | {"name":"[Syncopation] TRADING PHOTO CARD SET","option":"... | JSON 형식 데이터 (nullable) |
| `product_id` | BIGINT | 284084278230592 | product 참조 ID (FK) ⚠️ NULL 포함 |
| `parent_item_id` | VARCHAR | NULL | parent_item 참조 ID (FK) ⚠️ NULL 포함 |
| `sale_type` | VARCHAR | LICENSE | Enum: LICENSE, SELF ⚠️ NULL 포함 |

## 주의사항
- `parent_item_id`: NULL 비율 100%
- `expected_end_date_time`: NULL 비율 71%
- `sale_type`: NULL 비율 57%
- `expected_start_date_time`: NULL 비율 43%
- `product_id`: NULL 비율 43%
- `outgoing_quantity`: NULL 비율 29%
- `ref_type`: NULL 비율 29%
- `ref_id`: NULL 비율 29%
- `order_item_snapshot`: NULL 비율 29%

**Enum성 컬럼 값 목록:**
- `quantity`: 1 / 10 / 2 / 25
- `outgoing_quantity`: 1 / 10 / 2 / 25
- `ref_type`: ORDER_LINE / REWARD
- `sale_type`: LICENSE / SELF

**JSON 형식 컬럼:**
- `order_item_snapshot`: 주요 키 → `baseAmount`, `discountAmount`, `name`, `option`, `paymentAmount`, `salePrice`, `saleType`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  outgoing_id,
  sku_id,
  quantity
FROM journi_y222.outgoing_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.outgoing_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```

```sql
-- order_item_snapshot JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(order_item_snapshot, '$.name') AS order_item_snapshot_name,
  json_extract_scalar(order_item_snapshot, '$.option') AS order_item_snapshot_option,
  json_extract_scalar(order_item_snapshot, '$.salePrice') AS order_item_snapshot_salePrice,
  json_extract_scalar(order_item_snapshot, '$.baseAmount') AS order_item_snapshot_baseAmount,
  json_extract_scalar(order_item_snapshot, '$.paymentAmount') AS order_item_snapshot_paymentAmount
FROM journi_y222.outgoing_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND order_item_snapshot IS NOT NULL
LIMIT 100;
```
