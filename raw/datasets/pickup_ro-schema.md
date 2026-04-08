# pickup_ro 테이블
pickup_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.pickup_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 294189653521270 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-20 15:30:22.942 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-21 03:27:24.416 | 수정 일시 |
| `order_id` | BIGINT | 293913061262081 | order 참조 ID (FK) |
| `ref_id` | BIGINT | 293913061262084 | ref 참조 ID (FK) |
| `ref_type` | VARCHAR | ORDER_BUNDLE |  |
| `item_ref_id` | BIGINT | 293913061262082 | item_ref 참조 ID (FK) |
| `item_ref_type` | VARCHAR | ORDER_LINE |  |
| `sku_id` | BIGINT | 287544735948352 | sku 참조 ID (FK) |
| `quantity` | BIGINT | 3 | 수량 |
| `status` | VARCHAR | COMPLETED | 상태값 |
| `pickup_date_time` | TIMESTAMP | 2026-02-21 03:00:00.000 |  |
| `warehouse_id` | BIGINT | 293241513644032 | warehouse 참조 ID (FK) |
| `biz_partner_id` | BIGINT | 1758779013868 | biz_partner 참조 ID (FK) |
| `completed_at` | TIMESTAMP | 2026-02-21 03:27:24.376 |  (nullable) |
| `signature_path` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `version` | BIGINT | 1 | Enum: 0, 1 |
| `picked_up_at` | TIMESTAMP | 2026-02-21 03:27:24.376 |  (nullable) |
| `outgoing_id` | BIGINT | 294189652145005 | outgoing 참조 ID (FK) |
| `log_date` | VARCHAR | 20260220 |  |

## 주의사항
- `signature_path`: NULL 비율 100%
- `completed_at`: NULL 비율 10%
- `picked_up_at`: NULL 비율 10%

**Enum성 컬럼 값 목록:**
- `quantity`: 1 / 2 / 3
- `status`: COMPLETED / WAITING
- `version`: 0 / 1

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  order_id,
  ref_id,
  ref_type
FROM journi_y222.pickup_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.pickup_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```
