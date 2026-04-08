# logistics_sku_mapping_ro 테이블
logistics_sku_mapping_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.logistics_sku_mapping_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 312309000686214 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-18 05:54:17.310 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-18 05:54:17.378 | 수정 일시 |
| `sku_id` | BIGINT | 297550301461568 | sku 참조 ID (FK) |
| `warehouse_id` | BIGINT | 1758779013868 | warehouse 참조 ID (FK) |
| `integration_status` | VARCHAR | SUCCESS |  |

## 주의사항
- 특이사항 없음

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  sku_id,
  warehouse_id,
  integration_status
FROM journi_y222.logistics_sku_mapping_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.logistics_sku_mapping_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```
