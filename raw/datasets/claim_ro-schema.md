# claim_ro 테이블
클레임(취소/반품/교환) 정보. 이유, 상태, 처리 결과 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.claim_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 188606453284096 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-09-24 11:20:49.404 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-09-30 03:05:17.791 | 수정 일시 |
| `order_id` | BIGINT | 186577422909129 | order 참조 ID (FK) |
| `claim_reason` | VARCHAR | BUYER | Enum: BUYER, SELLER |
| `claim_type` | VARCHAR | CANCEL | Enum: CANCEL, EXCHANGE |
| `product_disposition_method` | VARCHAR | NONE_DELIVERY | Enum: DISPOSE, NONE_DELIVERY |
| `status` | VARCHAR | REFUNDED | 상태값 |
| `creation_description` | VARCHAR | 단순 변심 | Enum: Selected the wrong option, 临时改变主意, 단순 변심, 몬스터X 키트 팬클럽 카드 불량 - 카드 재배송 필요, 미수령 취소, 옵션 잘못 선택 |
| `description` | VARCHAR | 단순 변심 | Enum: Selected the wrong option, 临时改变主意, 단순 변심, 몬스타엑스 자동 재배송 요청, 미수령 취소, 옵션 잘못 선택 (nullable) |
| `refund_amount` | BIGINT | 25000.00 |  (nullable) |
| `refund_currency` | VARCHAR | KRW | Enum: JPY, KRW (nullable) |
| `completed_at` | TIMESTAMP | 2025-09-24 11:20:49.404 |  |
| `user_id` | BIGINT | 186517864045824 | user 참조 ID (FK) |
| `refund_context_id` | BIGINT | 192609630496448 | refund_context 참조 ID (FK) |
| `log_date` | VARCHAR | 20250924 |  |

## 주의사항
- `description`: NULL 비율 20%
- `refund_amount`: NULL 비율 10%
- `refund_currency`: NULL 비율 10%

**Enum성 컬럼 값 목록:**
- `claim_reason`: BUYER / SELLER
- `claim_type`: CANCEL / EXCHANGE
- `product_disposition_method`: DISPOSE / NONE_DELIVERY
- `status`: REDELIVERED / REFUNDED
- `creation_description`: Selected the wrong option / 临时改变主意 / 단순 변심 / 몬스터X 키트 팬클럽 카드 불량 - 카드 재배송 필요 / 미수령 취소 / 옵션 잘못 선택
- `description`: Selected the wrong option / 临时改变主意 / 단순 변심 / 몬스타엑스 자동 재배송 요청 / 미수령 취소 / 옵션 잘못 선택
- `refund_currency`: JPY / KRW

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  order_id,
  claim_reason,
  claim_type
FROM journi_y222.claim_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- claim_reason별 집계
SELECT
  claim_reason,
  COUNT(*) AS cnt
FROM journi_y222.claim_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY claim_reason
ORDER BY cnt DESC;
```
