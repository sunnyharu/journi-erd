# outgoing_ro 테이블
outgoing_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.outgoing_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 251974246355594 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-12-23 00:02:55.001 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-04-01 01:22:34.276 | 수정 일시 |
| `status` | VARCHAR | COMPLETED | 상태값 |
| `warehouse_id` | BIGINT | 7 | warehouse 참조 ID (FK) |
| `note` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `shipping_id` | BIGINT | 251974246306443 | shipping 참조 ID (FK) |
| `type` | VARCHAR | ORDER | 유형 구분 ⚠️ NULL 포함 |
| `fulfillment_type` | VARCHAR | B2C |  ⚠️ NULL 포함 |
| `method` | VARCHAR | PICKUP | Enum: PARCEL, PICKUP ⚠️ NULL 포함 |
| `external_ref_id` | VARCHAR | NULL | external_ref 참조 ID (FK) ⚠️ NULL 포함 |
| `ref_type` | VARCHAR | ORDER_BUNDLE |  |
| `ref_id` | BIGINT | 224037537988992 | ref 참조 ID (FK) |
| `receiver_name` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_phone_number` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_tin` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_addr` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_city` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_country` | VARCHAR | KR |  ⚠️ NULL 포함 |
| `receiver_detail_addr` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_state_or_province` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `receiver_zipcode` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `expected_start_date_time` | TIMESTAMP | 2026-02-21 06:00:00.000 |  ⚠️ NULL 포함 |
| `expected_end_date_time` | TIMESTAMP | 2026-05-31 14:59:59.999 |  ⚠️ NULL 포함 |
| `requested_at` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `version` | BIGINT | 1 |  ⚠️ NULL 포함 |
| `order_id` | BIGINT | 293912318692934 | order 참조 ID (FK) ⚠️ NULL 포함 |
| `order_completed_at` | TIMESTAMP | 2025-11-13 12:46:23.663 |  |
| `origin_outgoing_id` | VARCHAR | NULL | origin_outgoing 참조 ID (FK) ⚠️ NULL 포함 |
| `buyer_name` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `buyer_phone_number` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `buyer_email` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `biz_partner_id` | BIGINT | 1758779013868 | biz_partner 참조 ID (FK) ⚠️ NULL 포함 |
| `order_snapshot` | VARCHAR (JSON) | {"totalPaymentAmount":{"amount":159000,"currency":"KRW"},... | JSON 형식 데이터 ⚠️ NULL 포함 |
| `log_date` | VARCHAR | 20251223 |  |

## 주의사항
- `note`: NULL 비율 100%
- `external_ref_id`: NULL 비율 100%
- `receiver_name`: NULL 비율 100%
- `receiver_phone_number`: NULL 비율 100%
- `receiver_tin`: NULL 비율 100%
- `receiver_addr`: NULL 비율 100%
- `receiver_city`: NULL 비율 100%
- `receiver_detail_addr`: NULL 비율 100%
- `receiver_state_or_province`: NULL 비율 100%
- `receiver_zipcode`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `status`: COMPLETED / WAIT
- `method`: PARCEL / PICKUP

**JSON 형식 컬럼:**
- `order_snapshot`: 주요 키 → `totalDiscountAmount`, `totalPaymentAmount`

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  status,
  warehouse_id,
  note
FROM journi_y222.outgoing_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- status별 집계
SELECT
  status,
  COUNT(*) AS cnt
FROM journi_y222.outgoing_ro
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
FROM journi_y222.outgoing_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND order_snapshot IS NOT NULL
LIMIT 100;
```
