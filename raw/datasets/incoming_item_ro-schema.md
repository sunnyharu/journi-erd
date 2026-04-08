# incoming_item_ro 테이블
incoming_item_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.incoming_item_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 202628209104065 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-10-14 06:48:08.806 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-10-16 11:51:29.181 | 수정 일시 |
| `incoming_id` | BIGINT | 202628209104064 | incoming 참조 ID (FK) |
| `sku_id` | BIGINT | 193630068705792 | sku 참조 ID (FK) |
| `damaged_quantity` | BIGINT | 0 |  (nullable) |
| `incoming_quantity` | BIGINT | 96 |  (nullable) |
| `missing_quantity` | BIGINT | 0 | Enum: 0, 1 (nullable) |
| `requested_quantity` | BIGINT | 96 |  |
| `memo` | VARCHAR | 2/21-22 H2H 팬미팅MD 현장수령 | Enum: 12/05  LDG -> 베리즈 입고, 2/21-22 H2H 팬미팅MD 현장수령 ⚠️ NULL 포함 |
| `ref_type` | VARCHAR | NONE | Enum: CLAIM_LINE, NONE ⚠️ NULL 포함 |
| `ref_id` | BIGINT | 0 | ref 참조 ID (FK) ⚠️ NULL 포함 |
| `purchase_price` | BIGINT | 0.00 |  ⚠️ NULL 포함 |
| `purchase_currency` | VARCHAR | KRW |  ⚠️ NULL 포함 |
| `sale_type` | VARCHAR | LICENSE |  ⚠️ NULL 포함 |

## 주의사항
- `purchase_price`: NULL 비율 90%
- `purchase_currency`: NULL 비율 90%
- `sale_type`: NULL 비율 90%
- `memo`: NULL 비율 80%
- `ref_type`: NULL 비율 60%
- `ref_id`: NULL 비율 60%
- `damaged_quantity`: NULL 비율 20%
- `incoming_quantity`: NULL 비율 20%
- `missing_quantity`: NULL 비율 20%

**Enum성 컬럼 값 목록:**
- `missing_quantity`: 0 / 1
- `memo`: 12/05  LDG -> 베리즈 입고 / 2/21-22 H2H 팬미팅MD 현장수령
- `ref_type`: CLAIM_LINE / NONE

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  incoming_id,
  sku_id,
  damaged_quantity
FROM journi_y222.incoming_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- missing_quantity별 집계
SELECT
  missing_quantity,
  COUNT(*) AS cnt
FROM journi_y222.incoming_item_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY missing_quantity
ORDER BY cnt DESC;
```
