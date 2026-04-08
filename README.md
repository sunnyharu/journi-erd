# Journi DB Schema & Query Reference

e-커머스 서비스의 테이블 스키마 정의 및 Presto 쿼리 레퍼런스 저장소입니다.

## 구조

```
├── raw/
│   └── datasets/
│       ├── orders_ro-schema.md
│       ├── delivery_ro-schema.md
│       ├── payment_ro-schema.md
│       └── ... (총 65개 테이블)
├── generate_schemas.py   # schema.md 자동 생성 스크립트
└── sync_erd.py           # ERD HTML 데이터 동기화 스크립트
```

## 테이블 도메인 구성

| 도메인 | 주요 테이블 |
|--------|------------|
| 주문 | `orders_ro`, `order_line_ro`, `order_bundle_ro`, `checkout_ro` |
| 배송 | `delivery_ro`, `delivery_item_ro`, `outgoing_ro`, `incoming_ro` |
| 상품 | `product_ro`, `sku_ro`, `sku_group_ro`, `stock_ro` |
| 클레임 | `claim_ro`, `claim_line_ro` |
| 결제 | `payment_ro`, `payment_detail_ro`, `payment_cancel_ro` |
| 쿠폰 | `coupon_ro`, `coupon_policy_ro` |
| 유저 | `users_ro`, `user_delivery_address_ro` |
| 파트너 | `artist_ro`, `artist_shop_ro`, `mall_ro` |

## schema.md 포함 정보

각 테이블별 문서에는 다음 내용이 포함됩니다:

- **기본 정보**: 엔진(Presto), 경로(`journi_y222.{테이블명}`), 파티션 컬럼(`dt`)
- **컬럼 정의**: 타입, 샘플값, 설명
- **주의사항**: NULL 비율 높은 컬럼, Enum 값 목록, JSON 컬럼 구조
- **샘플 쿼리**: dt 파티션 조건 포함, JSON 파싱 쿼리 포함

## 쿼리 작성 시 주의사항

```sql
-- dt 파티션 조건 필수
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')

-- JSON 컬럼 파싱 (예: delivery_ro.order_snapshot)
json_extract_scalar(order_snapshot, '$.totalPaymentAmount')
```