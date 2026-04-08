# sku_group_ro 테이블
SKU 그룹(재고 묶음) 정보. 재고 관리 단위의 상위 그룹.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.sku_group_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 223722745262528 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-11-13 02:05:05.427 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-11-13 02:05:05.427 | 수정 일시 |
| `biz_partner_id` | BIGINT | 1758779013868 | biz_partner 참조 ID (FK) |
| `code` | VARCHAR | 254QRZLIBSRRP0 |  |
| `code_name` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `code_name`: NULL 비율 100%
- `deleted_at`: NULL 비율 100%

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  biz_partner_id,
  code,
  code_name
FROM journi_y222.sku_group_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.sku_group_ro
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;
```
