# orders_ro 테이블
최종 주문 정보. 결제 완료된 주문. 금액, 상태, 결제/배송 연결.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.orders_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 293923777037058 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-20 06:29:27.329 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-20 06:29:27.329 | 수정 일시 |
| `checkout_id` | BIGINT | 293923242659397 | checkout 참조 ID (FK) |
| `user_id` | BIGINT | 289227055789952 | user 참조 ID (FK) |
| `base_currency_payment_amount` | BIGINT | 50000.00 |  |
| `payment_amount` | DOUBLE | 50000.00 |  |
| `base_currency` | VARCHAR | KRW |  |
| `exchange_rates` | VARCHAR | KRW/KRW=1.0000000000 | Enum: 100JPY/KRW=880.0000000000;KRW/JPY=0.1136363636;KRW/KRW=1.0000000000, KRW/KRW=1.0000000000, KRW/KRW=1.0000000000;KRW/USD=0.0007407407;USD/KRW=1350.0000000000 |
| `payment_currency` | VARCHAR | KRW | Enum: JPY, KRW, USD |
| `user_agent` | VARCHAR | Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) Ap... |  |
| `device` | VARCHAR | IOS | Enum: ANDROID, IOS, PC |
| `status` | VARCHAR | CREATED | 상태값 |
| `completed_at` | TIMESTAMP | 2025-09-16 12:37:17.566 |  ⚠️ NULL 포함 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20260220 |  |

## 주의사항
- `deleted_at`: NULL 비율 100%
- `completed_at`: NULL 비율 80%

**Enum성 컬럼 값 목록:**
- `exchange_rates`: 100JPY/KRW=880.0000000000;KRW/JPY=0.1136363636;KRW/KRW=1.0000000000 / KRW/KRW=1.0000000000 / KRW/KRW=1.0000000000;KRW/USD=0.0007407407;USD/KRW=1350.0000000000
- `payment_currency`: JPY / KRW / USD
- `device`: ANDROID / IOS / PC
- `status`: COMPLETED / CREATED / FAILED

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  checkout_id,
  user_id,
  base_currency_payment_amount
FROM journi_y222.orders_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- exchange_rates별 집계
SELECT
  exchange_rates,
  COUNT(*) AS cnt
FROM journi_y222.orders_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY exchange_rates
ORDER BY cnt DESC;
```
