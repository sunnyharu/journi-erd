# coupon_ro 테이블
쿠폰 기본 정보. 쿠폰 코드, 할인율/금액, 유효기간, 조건 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.coupon_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 273516564657280 | 식별자 (PK) |
| `activatedat` | TIMESTAMP | 2025-12-23 01:00:00.000 | Enum: 2025-12-23 01:00:00.000, 2026-01-23 06:00:00.000, 2026-02-09 06:00:00.000, 2026-03-02 01:00:00.000, 2026-03-20 01:00:00.000 |
| `couponpolicyid` | BIGINT | 251469986412608 |  |
| `expiredat` | TIMESTAMP | 2026-01-31 14:59:59.000 | Enum: 2026-01-31 14:59:59.000, 2026-02-01 14:59:59.000, 2026-02-28 14:59:59.000, 2026-03-31 14:59:59.000, 2026-04-30 14:59:59.000 |
| `issuedat` | VARCHAR | 2026-01-22 10:30:52.509 |  |
| `issuedby` | VARCHAR | ['220667669856512', '0.0.0.0', 'USER'] |  |
| `status` | VARCHAR | UNUSED | 상태값 |
| `userid` | BIGINT | 220667669856512 |  |
| `redeemedinfo` | VARCHAR (JSON) | ['2000', 1772438247204, 301044424532226] | JSON 형식 데이터 ⚠️ NULL 포함 |

## 주의사항
- `redeemedinfo`: NULL 비율 60%

**Enum성 컬럼 값 목록:**
- `activatedat`: 2025-12-23 01:00:00.000 / 2026-01-23 06:00:00.000 / 2026-02-09 06:00:00.000 / 2026-03-02 01:00:00.000 / 2026-03-20 01:00:00.000
- `expiredat`: 2026-01-31 14:59:59.000 / 2026-02-01 14:59:59.000 / 2026-02-28 14:59:59.000 / 2026-03-31 14:59:59.000 / 2026-04-30 14:59:59.000
- `status`: UNUSED / USED
- `redeemedinfo`: ['1000.0', 1769641704223, 278135015747649] / ['2000', 1771927398077, 296859941815810] / ['2000', 1772438247204, 301044424532226] / ['9400.0', 1769849592780, 279838548957761]

**JSON 형식 컬럼:**
- `issuedby`: JSON 형식 (구조 가변적)
- `redeemedinfo`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  activatedat,
  couponpolicyid,
  expiredat,
  issuedat,
  issuedby
FROM journi_y222.coupon_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- activatedat별 집계
SELECT
  activatedat,
  COUNT(*) AS cnt
FROM journi_y222.coupon_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY activatedat
ORDER BY cnt DESC;
```

```sql
-- issuedby JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(issuedby, '$.key') AS issuedby_key
FROM journi_y222.coupon_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND issuedby IS NOT NULL
LIMIT 100;
```
