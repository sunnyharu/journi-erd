# coupon_policy_ro 테이블
coupon_policy_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.coupon_policy_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 277638411441664 | 식별자 (PK) |
| `createdat` | TIMESTAMP | 2026-01-28 06:16:47.646 |  |
| `deletedat` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `discountpolicy` | VARCHAR (JSON) | [None, 'FIXED_AMOUNT', None, ['10000', 'KRW'], ['1000', '... | JSON 형식 데이터 |
| `issuancepolicy` | VARCHAR | [True, [[True, 1769580949339], [False, 1769612400000], 'I... |  |
| `operationpolicy` | VARCHAR | ['PRIVATE', '[{"default":false,"property":"couponDisplayN... |  |
| `redeempolicy` | VARCHAR | ['DAYS', None, 'FIXED_RANGE', [[True, 1769580949339], [Fa... |  |
| `targetpolicy` | VARCHAR | [False, '[]', '[{"_id":228523194991808,"type":"COMMERCE_A... |  |
| `updatedat` | TIMESTAMP | 2026-01-28 06:16:47.646 |  |

## 주의사항
- `deletedat`: NULL 비율 100%

**JSON 형식 컬럼:**
- `discountpolicy`: JSON 형식 (구조 가변적)
- `issuancepolicy`: JSON 형식 (구조 가변적)
- `operationpolicy`: JSON 형식 (구조 가변적)
- `redeempolicy`: JSON 형식 (구조 가변적)
- `targetpolicy`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  createdat,
  deletedat,
  discountpolicy,
  issuancepolicy,
  operationpolicy
FROM journi_y222.coupon_policy_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.coupon_policy_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```

```sql
-- discountpolicy JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(discountpolicy, '$.key') AS discountpolicy_key
FROM journi_y222.coupon_policy_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND discountpolicy IS NOT NULL
LIMIT 100;
```
