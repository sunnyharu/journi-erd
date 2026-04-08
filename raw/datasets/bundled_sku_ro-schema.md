# bundled_sku_ro 테이블
bundled_sku_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.bundled_sku_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 292103490903232 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-17 16:46:04.449 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-17 16:46:04.455 | 수정 일시 |
| `sku_id` | BIGINT | 292103490903237 | sku 참조 ID (FK) |
| `bundled_sku_id` | BIGINT | 292100579941568 | bundled_sku 참조 ID (FK) |
| `quantity` | BIGINT | 1 | 수량 |

## 주의사항

**Enum성 컬럼 값 목록:**
- `quantity`: 1 / 2

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  sku_id,
  bundled_sku_id,
  quantity
FROM journi_y222.bundled_sku_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.bundled_sku_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```
