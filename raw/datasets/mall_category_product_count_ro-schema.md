# mall_category_product_count_ro 테이블
mall_category_product_count_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.mall_category_product_count_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 202463669102400 | 식별자 (PK) |
| `artistid` | BIGINT | 189350764903104 |  |
| `createdat` | TIMESTAMP | 2025-10-14 01:13:23.357 |  |
| `deletedat` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `mallcategoryid` | BIGINT | 189323979571428 |  |
| `mallid` | BIGINT | 189323979571392 |  |
| `productcount` | BIGINT | 17 | Enum: 0, 1, 12, 17, 2, 3 |
| `updatedat` | TIMESTAMP | 2025-10-16 07:25:11.093 |  |
| `log_date` | VARCHAR | 20251014 |  |

## 주의사항
- `deletedat`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `productcount`: 0 / 1 / 12 / 17 / 2 / 3 / 6

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  artistid,
  createdat,
  deletedat,
  mallcategoryid,
  mallid
FROM journi_y222.mall_category_product_count_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- productcount별 집계
SELECT
  productcount,
  COUNT(*) AS cnt
FROM journi_y222.mall_category_product_count_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY productcount
ORDER BY cnt DESC;
```
