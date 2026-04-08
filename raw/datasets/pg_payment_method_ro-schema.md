# pg_payment_method_ro 테이블
pg_payment_method_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.pg_payment_method_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 1389290689661541888 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-06-30 17:05:12.189 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-06-30 17:05:12.189 | 수정 일시 |
| `commission_id` | BIGINT | 1389290689661541888 | commission 참조 ID (FK) |
| `enabled` | BIGINT | 1 |  |
| `code` | VARCHAR | 36 |  |
| `name` | VARCHAR | KDB산업 |  |
| `code_type` | VARCHAR | DETAIL | Enum: DETAIL, METHOD |
| `payment_method_code` | VARCHAR | CREDIT_CARD | Enum: ALIPAY, BANK_TRANSFER, CREDIT_CARD, CREDIT_CARD_GLOBAL |
| `pg_code` | VARCHAR | NICEPAY | Enum: EXIMBAY, NICEPAY |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `code_type`: DETAIL / METHOD
- `payment_method_code`: ALIPAY / BANK_TRANSFER / CREDIT_CARD / CREDIT_CARD_GLOBAL
- `pg_code`: EXIMBAY / NICEPAY

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  commission_id,
  enabled,
  code
FROM journi_y222.pg_payment_method_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- code_type별 집계
SELECT
  code_type,
  COUNT(*) AS cnt
FROM journi_y222.pg_payment_method_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY code_type
ORDER BY cnt DESC;
```
