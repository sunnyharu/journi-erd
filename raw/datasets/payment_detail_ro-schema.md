# payment_detail_ro 테이블
payment_detail_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.payment_detail_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 289902141089536 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-14 14:07:24.963 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-14 14:07:24.963 | 수정 일시 |
| `payment_id` | BIGINT | 289898933331264 | payment 참조 ID (FK) |
| `card_installment` | BIGINT | 0 | Enum: 0, 3 (nullable) |
| `bank_code` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `bank_name` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `pg_payment_method_code` | VARCHAR | P101 | Enum: 01, 02, 06, 07, 12, 40 |
| `pg_payment_method_name` | VARCHAR | Visa | Enum: KB국민, NH채움, Visa, 비씨, 신한, 카카오머니 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `card_code` | BIGINT | 02 | Enum: 02, 06, 07, 12 ⚠️ NULL 포함 |
| `approval_amount` | BIGINT | 52145.00 |  ⚠️ NULL 포함 |
| `approval_currency` | VARCHAR | KRW | Enum: JPY, KRW ⚠️ NULL 포함 |
| `approval_rate` | DOUBLE | 9.36512200 |  ⚠️ NULL 포함 |

## 주의사항
- `bank_code`: NULL 비율 100%
- `bank_name`: NULL 비율 100%
- `deleted_at`: NULL 비율 100%
- `approval_amount`: NULL 비율 70%
- `approval_currency`: NULL 비율 70%
- `approval_rate`: NULL 비율 70%
- `card_code`: NULL 비율 50%
- `card_installment`: NULL 비율 30%

**Enum성 컬럼 값 목록:**
- `card_installment`: 0 / 3
- `pg_payment_method_code`: 01 / 02 / 06 / 07 / 12 / 40 / P001 / P101
- `pg_payment_method_name`: KB국민 / NH채움 / Visa / 비씨 / 신한 / 카카오머니 / 페이팔 / 현대
- `card_code`: 02 / 06 / 07 / 12
- `approval_currency`: JPY / KRW

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  payment_id,
  card_installment,
  bank_code
FROM journi_y222.payment_detail_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- card_installment별 집계
SELECT
  card_installment,
  COUNT(*) AS cnt
FROM journi_y222.payment_detail_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY card_installment
ORDER BY cnt DESC;
```
