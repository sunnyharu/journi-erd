# incoming_ro 테이블
incoming_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.incoming_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 242956308594880 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-12-10 06:15:52.515 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-12-15 09:30:59.584 | 수정 일시 |
| `claim_id` | VARCHAR | NULL | claim 참조 ID (FK) ⚠️ NULL 포함 |
| `origin_delivery_id` | VARCHAR | NULL | origin_delivery 참조 ID (FK) ⚠️ NULL 포함 |
| `warehouse_id` | BIGINT | 1758779013868 | warehouse 참조 ID (FK) |
| `request_date` | VARCHAR | 2025-12-15 |  |
| `status` | VARCHAR | COMPLETED | 상태값 |
| `transport_type` | VARCHAR | NORMAL |  |
| `type` | VARCHAR | PURCHASE_ORDER | 유형 구분 |
| `delivery_id` | VARCHAR | NULL | delivery 참조 ID (FK) ⚠️ NULL 포함 |
| `ref_type` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `ref_id` | VARCHAR | NULL | ref 참조 ID (FK) ⚠️ NULL 포함 |
| `external_ref_id` | VARCHAR | NULL | external_ref 참조 ID (FK) ⚠️ NULL 포함 |
| `version` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `completed_at` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `biz_partner_id` | VARCHAR | NULL | biz_partner 참조 ID (FK) ⚠️ NULL 포함 |
| `origin_outgoing_id` | VARCHAR | NULL | origin_outgoing 참조 ID (FK) ⚠️ NULL 포함 |
| `origin_incoming_id` | VARCHAR | NULL | origin_incoming 참조 ID (FK) ⚠️ NULL 포함 |
| `note` | VARCHAR | NULL |  ⚠️ NULL 포함 |

## 주의사항
- `claim_id`: NULL 비율 100%
- `origin_delivery_id`: NULL 비율 100%
- `delivery_id`: NULL 비율 100%
- `ref_type`: NULL 비율 100%
- `ref_id`: NULL 비율 100%
- `external_ref_id`: NULL 비율 100%
- `version`: NULL 비율 100%
- `completed_at`: NULL 비율 100%
- `biz_partner_id`: NULL 비율 100%
- `origin_outgoing_id`: NULL 비율 100%

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  claim_id,
  origin_delivery_id,
  warehouse_id
FROM journi_y222.incoming_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.incoming_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```
