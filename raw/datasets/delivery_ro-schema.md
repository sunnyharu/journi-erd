# delivery_ro 테이블
배송 정보. 택배사, 송장번호, 배송 상태, 수령인 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.delivery_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 308568159426840 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-03-12 23:03:31.686 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-03-14 07:17:06.583 | 수정 일시 |
| `type` | VARCHAR | NORMAL | 유형 구분 |
| `origin_delivery_id` | VARCHAR | NULL | origin_delivery 참조 ID (FK) ⚠️ NULL 포함 |
| `status` | VARCHAR | COMPLETED | 상태값 |
| `started_at` | TIMESTAMP | 2026-03-13 01:47:12.470 |  (nullable) |
| `completed_at` | TIMESTAMP | 2026-03-14 04:24:00.000 |  (nullable) |
| `method` | VARCHAR | NORMAL |  |
| `region` | VARCHAR | DOMESTIC | Enum: DOMESTIC, OVERSEAS |
| `biz_partner_id` | BIGINT | 6 | biz_partner 참조 ID (FK) |
| `receiver_city` | VARCHAR | Yamanashi shi | Enum: Tokyo, Yamanashi shi ⚠️ NULL 포함 |
| `receiver_country` | VARCHAR | KR | Enum: JP, KR |
| `receiver_state_or_province` | VARCHAR | Yamanashi | Enum: Japan, Yamanashi ⚠️ NULL 포함 |
| `requirement` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `order_id` | BIGINT | 308174188543937 | order 참조 ID (FK) |
| `ref_id` | BIGINT | 308174188617665 | ref 참조 ID (FK) |
| `ref_type` | VARCHAR | ORDER_BUNDLE |  |
| `warehouse_id` | BIGINT | 286184492824640 | warehouse 참조 ID (FK) |
| `pre_sale_deliver_start` | VARCHAR | 2026-03-31 | Enum: 2025-08-22, 2026-01-01, 2026-03-31, 2026-04-01 ⚠️ NULL 포함 |
| `pre_sale_deliver_end` | VARCHAR | 2026-04-07 | Enum: 2025-08-29, 2026-04-07, 2026-04-30, 2026-05-31 ⚠️ NULL 포함 |
| `version` | BIGINT | 3 | Enum: 0, 1, 2, 3 |
| `outgoing_id` | BIGINT | 308568159492375 | outgoing 참조 ID (FK) |
| `incoming_id` | VARCHAR | NULL | incoming 참조 ID (FK) ⚠️ NULL 포함 |
| `order_snapshot` | VARCHAR (JSON) | {"totalPaymentAmount":{"amount":5681,"currency":"JPY"},"t... | JSON 형식 데이터 ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20260312 |  |

## 주의사항
- `origin_delivery_id`: NULL 비율 100%
- `requirement`: NULL 비율 100%
- `incoming_id`: NULL 비율 100%
- `receiver_city`: NULL 비율 80%
- `receiver_state_or_province`: NULL 비율 80%
- `order_snapshot`: NULL 비율 80%
- `pre_sale_deliver_start`: NULL 비율 40%
- `pre_sale_deliver_end`: NULL 비율 40%
- `completed_at`: NULL 비율 20%
- `started_at`: NULL 비율 10%

**Enum성 컬럼 값 목록:**
- `status`: COMPLETED / IN_PROGRESS / WAITING
- `region`: DOMESTIC / OVERSEAS
- `receiver_city`: Tokyo / Yamanashi shi
- `receiver_country`: JP / KR
- `receiver_state_or_province`: Japan / Yamanashi
- `pre_sale_deliver_start`: 2025-08-22 / 2026-01-01 / 2026-03-31 / 2026-04-01
- `pre_sale_deliver_end`: 2025-08-29 / 2026-04-07 / 2026-04-30 / 2026-05-31
- `version`: 0 / 1 / 2 / 3

**JSON 형식 컬럼:**
- `order_snapshot`: 주요 키 → `totalDiscountAmount`, `totalPaymentAmount`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  type,
  origin_delivery_id,
  status
FROM journi_y222.delivery_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- status별 집계
SELECT
  status,
  COUNT(*) AS cnt
FROM journi_y222.delivery_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY status
ORDER BY cnt DESC;
```

```sql
-- order_snapshot JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(order_snapshot, '$.totalPaymentAmount') AS order_snapshot_totalPaymentAmount,
  json_extract_scalar(order_snapshot, '$.totalDiscountAmount') AS order_snapshot_totalDiscountAmount
FROM journi_y222.delivery_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND order_snapshot IS NOT NULL
LIMIT 100;
```
