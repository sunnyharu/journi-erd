# adjustment_ro 테이블
adjustment_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.adjustment_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 257345793655808 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-12-30 14:11:21.452 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-12-30 14:11:21.471 | 수정 일시 |
| `warehouse_id` | BIGINT | 7 | warehouse 참조 ID (FK) |
| `status` | VARCHAR | COMPLETED | 상태값 |
| `sku_id` | BIGINT | 221600747227072 | sku 참조 ID (FK) |
| `adjusted_quantity` | BIGINT | 16 |  |
| `adjusting_quantity` | BIGINT | 8 |  |
| `type` | VARCHAR | EXTERNAL | 유형 구분 |
| `reason` | VARCHAR | TAKING | Enum: ADJUSTMENT, DAMAGED, DISCREPANCY, ETC, TAKING |
| `note` | VARCHAR | NULL |  ⚠️ NULL 포함 |

## 주의사항
- `note`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `type`: EXTERNAL / MANAGING
- `reason`: ADJUSTMENT / DAMAGED / DISCREPANCY / ETC / TAKING

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  warehouse_id,
  status,
  sku_id
FROM journi_y222.adjustment_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- type별 집계
SELECT
  type,
  COUNT(*) AS cnt
FROM journi_y222.adjustment_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY type
ORDER BY cnt DESC;
```
