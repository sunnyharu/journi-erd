# payment_method_ro 테이블
payment_method_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.payment_method_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 7
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 1389290142502002944 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-09-02 02:19:17.639 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-09-02 02:19:17.639 | 수정 일시 |
| `name` | VARCHAR | 페이팔 | Enum: 0원 결제, 계좌이체, 신용카드, 알리페이, 카카오페이, 페이팔 |
| `code` | VARCHAR | PAYPAL | Enum: ALIPAY, BANK_TRANSFER, CREDIT_CARD, CREDIT_CARD_GLOBAL, KAKAO_PAY, PAYPAL |
| `region_type` | VARCHAR | GLOBAL | Enum: DOMESTIC, GLOBAL |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `name`: 0원 결제 / 계좌이체 / 신용카드 / 알리페이 / 카카오페이 / 페이팔 / 해외 신용카드
- `code`: ALIPAY / BANK_TRANSFER / CREDIT_CARD / CREDIT_CARD_GLOBAL / KAKAO_PAY / PAYPAL / ZERO_PAYMENT
- `region_type`: DOMESTIC / GLOBAL

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  name,
  code,
  region_type
FROM journi_y222.payment_method_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- name별 집계
SELECT
  name,
  COUNT(*) AS cnt
FROM journi_y222.payment_method_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY name
ORDER BY cnt DESC;
```
