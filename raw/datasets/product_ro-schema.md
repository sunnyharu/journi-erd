# product_ro 테이블
상품 기본 정보. 상품명, 가격, 상태, SKU 그룹, 아티스트, 몰 연결 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.product_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 293271448375424 | 식별자 (PK) |
| `adultonly` | BOOLEAN | false |  |
| `artistid` | BIGINT | 189351294458560 |  |
| `bizpartnerid` | BIGINT | 1758779013868 |  |
| `buyquantitylimit` | VARCHAR | {"enabled":false} | Enum: {"enabled":false}, {"enabled":true,"max":3} |
| `couponenabled` | BOOLEAN | true | Enum: false, true |
| `createdat` | TIMESTAMP | 2026-02-19 08:22:17.450 |  |
| `culturetaxdeductible` | BOOLEAN | false |  |
| `deletereason` | VARCHAR | sku 재등록 |  ⚠️ NULL 포함 |
| `deletedat` | TIMESTAMP | 2026-03-20 08:46:16.424 |  ⚠️ NULL 포함 |
| `detailinfos` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `display` | BOOLEAN | false | Enum: false, true ⚠️ NULL 포함 |
| `displayenabled` | BOOLEAN | true |  |
| `displayperiod` | VARCHAR | [253402300799000, 1771826400000] |  |
| `essentialinfos` | VARCHAR | ['{"i18n":[{"default":false,"property":"title","text":"상품... |  |
| `i18n` | VARCHAR (JSON) | ['{"default":false,"property":"artistName","text":"NCT WI... | JSON 형식 데이터 |
| `images` | VARCHAR (JSON) | ['{"order":0,"savedPath":"product/293271448375424/2933040... | JSON 형식 데이터 |
| `items` | VARCHAR | ['{"_id":293271448465536,"buyQuantityLimit":{"enabled":fa... |  |
| `keywords` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `mainartistshopid` | BIGINT | 204678854043392 |  |
| `mallcategoryids` | VARCHAR | ['189323979571407'] | Enum: ['172845827663307'], ['189323979571394'], ['189323979571401'], ['189323979571405', '189323979571406'], ['189323979571406', '189323979571405'], ['189323979571407'] |
| `mallid` | BIGINT | 189323979571392 |  |
| `manualflags` | VARCHAR | [] |  |
| `notices` | VARCHAR | [] |  ⚠️ NULL 포함 |
| `ogimage` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `options` | VARCHAR (JSON) | ['{"id":293271448375425,"name":"Option","order":0,"produc... | JSON 형식 데이터 |
| `platformcategoryids` | VARCHAR | ['10010'] | Enum: ['10010'], ['1010'], ['11010'], ['4010'], ['5020'], ['5030'] |
| `price` | VARCHAR | [['18000', 'KRW'], ['18000', 'KRW'], ['18000', 'KRW']] | 금액 |
| `productcategoryids` | VARCHAR | ['41'] | Enum: ['1'], ['41'] |
| `productsalecountry` | VARCHAR | ['KRW', '[{"code":"MM"},{"code":"ST"},{"code":"KM"},{"cod... |  |
| `purchaseconditions` | VARCHAR (JSON) | [] | JSON 형식 데이터 |
| `receivingpolicy` | VARCHAR | {"deliveryPolicy":{"bundleDeliveryGroupId":28812756316576... |  |
| `saleperiod` | VARCHAR | [253402300799000, 1771826400000] |  |
| `saletype` | VARCHAR | SELF | Enum: PURCHASE, SELF |
| `sellablequantityexists` | BOOLEAN | false | Enum: false, true |
| `status` | VARCHAR | SALE | 상태값 |
| `type` | VARCHAR | GENERAL | 유형 구분 |
| `updatedat` | TIMESTAMP | 2026-03-04 08:32:50.345 |  |
| `chartdata` | VARCHAR (JSON) | ['8804775456985', 1, 1761922800000] | JSON 형식 데이터 ⚠️ NULL 포함 |
| `commission` | VARCHAR | [293289008307256, '15', 193971718644416, 'PERCENT', '3.6'... |  (nullable) |
| `profile` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `fanclubkey` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `profiles` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `eventpolicyid` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `platformcategorypolicies` | VARCHAR | [] |  ⚠️ NULL 포함 |
| `purchasebenefits` | VARCHAR | [] |  ⚠️ NULL 포함 |
| `firstsalestartat` | VARCHAR | 2026-02-23 06:00:00.000 | Enum: 2024-01-01 03:00:00.000, 2025-11-19 21:00:00.000, 2025-12-01 06:00:00.000, 2026-01-16 05:10:57.000, 2026-01-28 06:00:00.000, 2026-02-23 06:00:00.000 |
| `aliasname` | VARCHAR | NULL |  ⚠️ NULL 포함 |

## 주의사항
- `detailinfos`: NULL 비율 100%
- `keywords`: NULL 비율 100%
- `ogimage`: NULL 비율 100%
- `profile`: NULL 비율 100%
- `fanclubkey`: NULL 비율 100%
- `profiles`: NULL 비율 100%
- `eventpolicyid`: NULL 비율 100%
- `aliasname`: NULL 비율 100%
- `deletereason`: NULL 비율 90%
- `deletedat`: NULL 비율 90%

**Enum성 컬럼 값 목록:**
- `buyquantitylimit`: {"enabled":false} / {"enabled":true,"max":3}
- `couponenabled`: false / true
- `display`: false / true
- `mallcategoryids`: ['172845827663307'] / ['189323979571394'] / ['189323979571401'] / ['189323979571405', '189323979571406'] / ['189323979571406', '189323979571405'] / ['189323979571407'] / ['189323979571428'] / ['228522710869191']
- `platformcategoryids`: ['10010'] / ['1010'] / ['11010'] / ['4010'] / ['5020'] / ['5030'] / ['5040'] / ['9010']
- `productcategoryids`: ['1'] / ['41']
- `saletype`: PURCHASE / SELF
- `sellablequantityexists`: false / true
- `status`: SALE / SALE_END
- `firstsalestartat`: 2024-01-01 03:00:00.000 / 2025-11-19 21:00:00.000 / 2025-12-01 06:00:00.000 / 2026-01-16 05:10:57.000 / 2026-01-28 06:00:00.000 / 2026-02-23 06:00:00.000 / 2026-03-23 06:00:00.000 / 2026-03-23 08:00:00.000

**JSON 형식 컬럼:**
- `buyquantitylimit`: 주요 키 → `enabled`, `max`
- `displayperiod`: JSON 형식 (구조 가변적)
- `essentialinfos`: JSON 형식 (구조 가변적)
- `i18n`: JSON 형식 (구조 가변적)
- `images`: JSON 형식 (구조 가변적)
- `items`: JSON 형식 (구조 가변적)
- `mallcategoryids`: JSON 형식 (구조 가변적)
- `options`: JSON 형식 (구조 가변적)
- `platformcategoryids`: JSON 형식 (구조 가변적)
- `price`: JSON 형식 (구조 가변적)
- `productcategoryids`: JSON 형식 (구조 가변적)
- `productsalecountry`: JSON 형식 (구조 가변적)
- `purchaseconditions`: JSON 형식 (구조 가변적)
- `receivingpolicy`: 주요 키 → `deliveryPolicy`, `pickupInfos`, `pickupPolicy`, `receivingInfos`, `receivingType`, `returnInfos`
- `saleperiod`: JSON 형식 (구조 가변적)
- `chartdata`: JSON 형식 (구조 가변적)
- `commission`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  adultonly,
  artistid,
  bizpartnerid,
  buyquantitylimit,
  couponenabled
FROM journi_y222.product_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- buyquantitylimit별 집계
SELECT
  buyquantitylimit,
  COUNT(*) AS cnt
FROM journi_y222.product_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY buyquantitylimit
ORDER BY cnt DESC;
```

```sql
-- buyquantitylimit JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(buyquantitylimit, '$.enabled') AS buyquantitylimit_enabled
FROM journi_y222.product_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND buyquantitylimit IS NOT NULL
LIMIT 100;
```
