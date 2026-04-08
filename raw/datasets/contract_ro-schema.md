# contract_ro 테이블
contract_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.contract_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 1
- PK 컬럼: `_id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `_id` | BIGINT | 287592124482816 | 식별자 (PK) |
| `artists` | VARCHAR | ['{"berrizArtistId":94,"name":"우리들의 발라드"}', '{"berrizArti... |  |
| `attachmentpaths` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `bizpartnerid` | BIGINT | 1758532239245 |  |
| `businessmodeltype` | VARCHAR | BR |  |
| `code` | VARCHAR | 26008SC-M1-0-BR |  |
| `commissions` | VARCHAR | ['{"_id":287592124531968,"category":{"_id":19358112242963... |  |
| `contractname` | VARCHAR | 거래계약서 |  |
| `contractperiod` | VARCHAR | [1798642800000, 1764687600000] |  |
| `contracttype` | VARCHAR | NORMAL |  |
| `createdat` | TIMESTAMP | 2026-02-11 07:47:40.517 |  |
| `deletedat` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `internalapprovedocumenturl` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `ipdomains` | VARCHAR | ['k-pop'] |  |
| `labeltype` | VARCHAR | SC |  |
| `regiontype` | VARCHAR | DOMESTIC |  |
| `status` | VARCHAR | ACTIVE | 상태값 |
| `updatedat` | TIMESTAMP | 2026-02-11 07:47:40.517 |  |
| `contractsignedat` | VARCHAR | 2025-12-01 00:00:00.000 |  |
| `parentid` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `labelref` | VARCHAR | [287576890405824, 'SC'] |  |
| `businessmodelref` | VARCHAR | [222572860143680, 'BR'] |  |
| `renewalnotificationdate` | VARCHAR | 2026-11-01 00:00:00.000 |  |

## 주의사항
- `attachmentpaths`: NULL 비율 100%
- `deletedat`: NULL 비율 100%
- `internalapprovedocumenturl`: NULL 비율 100%
- `parentid`: NULL 비율 100%

**JSON 형식 컬럼:**
- `artists`: JSON 형식 (구조 가변적)
- `commissions`: JSON 형식 (구조 가변적)
- `contractperiod`: JSON 형식 (구조 가변적)
- `ipdomains`: JSON 형식 (구조 가변적)
- `labelref`: JSON 형식 (구조 가변적)
- `businessmodelref`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  _id,
  artists,
  attachmentpaths,
  bizpartnerid,
  businessmodeltype,
  code
FROM journi_y222.contract_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.contract_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```

```sql
-- artists JSON 파싱 조회
SELECT
  _id,
  json_extract_scalar(artists, '$.key') AS artists_key
FROM journi_y222.contract_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND artists IS NOT NULL
LIMIT 100;
```
