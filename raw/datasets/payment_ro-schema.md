# payment_ro 테이블
결제 정보. 결제 수단, 금액, 상태, PG사 연결 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.payment_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 296016949978368 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-23 05:28:01.634 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-04-03 05:15:25.597 | 수정 일시 |
| `payment_detail_id` | BIGINT | 267292603665920 | payment_detail 참조 ID (FK) ⚠️ NULL 포함 |
| `ref_id` | BIGINT | 296016949904646 | ref 참조 ID (FK) |
| `user_id` | BIGINT | 1387766083522928896 | user 참조 ID (FK) |
| `amount` | DOUBLE | 2841.00 | 금액 |
| `canceled_amount` | BIGINT | 0.00 |  |
| `commission` | DOUBLE | 0.000 | Enum: 0.000, 2.000, 2.200 |
| `payment_vat` | BIGINT | 10.000 |  ⚠️ NULL 포함 |
| `payment_method_i18n` | VARCHAR (JSON) | {"results":[{"refId":0,"property":"name","lang":[{"id":16... | JSON 형식 데이터 |
| `pg_transaction_id` | VARCHAR | kakaoent1m01012601140028094211 | pg_transaction 참조 ID (FK) ⚠️ NULL 포함 |
| `requested_currency` | VARCHAR | JPY | Enum: JPY, KRW, USD |
| `commission_type` | VARCHAR | PERCENT |  ⚠️ NULL 포함 |
| `payment_method` | VARCHAR | PAYPAL | Enum: ALIPAY, BANK_TRANSFER, CREDIT_CARD, KAKAO_PAY, PAYPAL |
| `pg_code` | VARCHAR | EXIMBAY | Enum: EXIMBAY, NICEPAY |
| `ref_type` | VARCHAR | ORDER |  |
| `status` | VARCHAR | REQUESTED | 상태값 |
| `completed_at` | TIMESTAMP | 2026-01-13 15:28:11.000 |  ⚠️ NULL 포함 |
| `latest_canceled_at` | TIMESTAMP | 2026-02-24 03:51:33.000 |  ⚠️ NULL 포함 |
| `requested_at` | TIMESTAMP | 2026-02-23 05:28:01.633 |  |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `expire_at` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `member_key` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `mid` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20260223 |  |

## 주의사항
- `deleted_at`: NULL 비율 100%
- `expire_at`: NULL 비율 100%
- `member_key`: NULL 비율 100%
- `mid`: NULL 비율 100%
- `latest_canceled_at`: NULL 비율 80%
- `payment_detail_id`: NULL 비율 60%
- `payment_vat`: NULL 비율 60%
- `pg_transaction_id`: NULL 비율 60%
- `commission_type`: NULL 비율 60%
- `completed_at`: NULL 비율 60%

**Enum성 컬럼 값 목록:**
- `commission`: 0.000 / 2.000 / 2.200
- `pg_transaction_id`: 13215FC635W0000155851060 / 13215FC635W0000165334808 / kakaoent1m01012601140028094211 / kakaoent1m01012602241108442683
- `requested_currency`: JPY / KRW / USD
- `payment_method`: ALIPAY / BANK_TRANSFER / CREDIT_CARD / KAKAO_PAY / PAYPAL
- `pg_code`: EXIMBAY / NICEPAY
- `status`: CANCELED / COMPLETED / REQUESTED

**JSON 형식 컬럼:**
- `payment_method_i18n`: 주요 키 → `results`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  payment_detail_id,
  ref_id,
  user_id
FROM journi_y222.payment_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- commission별 집계
SELECT
  commission,
  COUNT(*) AS cnt
FROM journi_y222.payment_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY commission
ORDER BY cnt DESC;
```

```sql
-- payment_method_i18n JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(payment_method_i18n, '$.results') AS payment_method_i18n_results
FROM journi_y222.payment_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND payment_method_i18n IS NOT NULL
LIMIT 100;
```
