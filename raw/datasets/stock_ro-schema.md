# stock_ro 테이블
stock_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.stock_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 323553814643212 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-04-03 03:11:55.266 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-04-05 06:13:27.641 | 수정 일시 |
| `sku_id` | BIGINT | 311681323845568 | sku 참조 ID (FK) |
| `warehouse_id` | BIGINT | 320741400797248 | warehouse 참조 ID (FK) |
| `available_quantity` | BIGINT | -13 | Enum: -13, 0, 1, 29, 3 |
| `reserved_quantity` | BIGINT | 0 |  |
| `version` | BIGINT | 12 | Enum: 0, 1, 12, 3, 5, 7 |
| `physical_quantity` | BIGINT | -13 | Enum: -13, 0, 1, 29, 3 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `available_quantity`: -13 / 0 / 1 / 29 / 3
- `version`: 0 / 1 / 12 / 3 / 5 / 7
- `physical_quantity`: -13 / 0 / 1 / 29 / 3

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  sku_id,
  warehouse_id,
  available_quantity
FROM journi_y222.stock_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- available_quantity별 집계
SELECT
  available_quantity,
  COUNT(*) AS cnt
FROM journi_y222.stock_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY available_quantity
ORDER BY cnt DESC;
```
