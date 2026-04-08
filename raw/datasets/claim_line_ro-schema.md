# claim_line_ro 테이블
claim_line_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.claim_line_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 297286538556994 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-25 00:31:00.933 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-25 00:31:01.000 | 수정 일시 |
| `claim_id` | BIGINT | 297286538556992 | claim 참조 ID (FK) |
| `order_bundle_id` | BIGINT | 296640236136323 | order_bundle 참조 ID (FK) |
| `order_line_id` | BIGINT | 296640236136321 | order_line 참조 ID (FK) |
| `sku_id` | BIGINT | 293151208368640 | sku 참조 ID (FK) |
| `quantity` | BIGINT | 1 | 수량 |
| `type` | VARCHAR | PURCHASED | 유형 구분 |

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
  claim_id,
  order_bundle_id,
  order_line_id
FROM journi_y222.claim_line_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- quantity별 집계
SELECT
  quantity,
  COUNT(*) AS cnt
FROM journi_y222.claim_line_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY quantity
ORDER BY cnt DESC;
```
