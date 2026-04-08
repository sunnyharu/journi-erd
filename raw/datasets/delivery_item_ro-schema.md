# delivery_item_ro 테이블
delivery_item_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.delivery_item_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 313523038217088 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-19 23:04:15.252 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-19 23:04:15.252 | 수정 일시 |
| `delivery_id` | BIGINT | 313523037643650 | delivery 참조 ID (FK) |
| `sku_id` | BIGINT | 293409755680768 | sku 참조 ID (FK) |
| `quantity` | BIGINT | 1 | 수량 |
| `ref_id` | BIGINT | 310810860284672 | ref 참조 ID (FK) |
| `ref_type` | VARCHAR | ORDER_LINE |  |
| `item_info` | VARCHAR (JSON) | {"name":"삼성라이온즈 2026 02올드 레플리카 홈 유니폼","optionName":"95 / ... | JSON 형식 데이터 |
| `product_id` | BIGINT | 294162233523584 | product 참조 ID (FK) |
| `pre_sale_deliver_start` | VARCHAR | 2026-03-20 | Enum: 2025-12-26, 2026-01-30, 2026-02-20, 2026-03-11, 2026-03-20, 2026-03-23 |
| `pre_sale_deliver_end` | VARCHAR | 2026-03-31 | Enum: 2026-01-02, 2026-02-05, 2026-02-25, 2026-03-16, 2026-03-31, 2026-04-07 |
| `log_date` | VARCHAR | 20260319 |  |

## 주의사항

**Enum성 컬럼 값 목록:**
- `quantity`: 1 / 4
- `pre_sale_deliver_start`: 2025-12-26 / 2026-01-30 / 2026-02-20 / 2026-03-11 / 2026-03-20 / 2026-03-23 / 2026-03-24 / 2026-04-01
- `pre_sale_deliver_end`: 2026-01-02 / 2026-02-05 / 2026-02-25 / 2026-03-16 / 2026-03-31 / 2026-04-07 / 2026-04-18 / 2026-05-31

**JSON 형식 컬럼:**
- `item_info`: 주요 키 → `discountAmount`, `name`, `optionName`, `orderedAt`, `paidAt`, `paymentAmount`, `salePrice`, `saleType`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  delivery_id,
  sku_id,
  quantity
FROM journi_y222.delivery_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.delivery_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```

```sql
-- item_info JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(item_info, '$.name') AS item_info_name,
  json_extract_scalar(item_info, '$.optionName') AS item_info_optionName,
  json_extract_scalar(item_info, '$.salePrice') AS item_info_salePrice,
  json_extract_scalar(item_info, '$.paymentAmount') AS item_info_paymentAmount,
  json_extract_scalar(item_info, '$.discountAmount') AS item_info_discountAmount
FROM journi_y222.delivery_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND item_info IS NOT NULL
LIMIT 100;
```
