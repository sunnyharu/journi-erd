# sku_ro 테이블
개별 SKU(재고 단위) 정보. 색상, 사이즈 등 옵션별 실제 재고 단위.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.sku_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 3
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 293104036568256 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-19 02:41:41.338 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-19 02:41:41.338 | 수정 일시 |
| `manufacturer_id` | BIGINT | 287035616230976 | manufacturer 참조 ID (FK) |
| `height` | BIGINT | 230 |  |
| `length` | BIGINT | 230 | Enum: 135, 145, 230 |
| `price_amount` | BIGINT | 7000.00 |  |
| `weight` | BIGINT | 141 |  |
| `width` | BIGINT | 230 | Enum: 135, 145, 230 |
| `type` | VARCHAR | PHYSICAL | 유형 구분 |
| `barcode` | BIGINT | 8804775462252 |  |
| `currency` | VARCHAR | KRW | 통화 코드 |
| `hs_code` | BIGINT | 950669 |  |
| `name` | VARCHAR | 삼성라이온즈 하드 로고볼 | Enum: MINI DOLL KEY RING_D.O., SUPER  CD PLAYER SET_LEETEUK, 삼성라이온즈 하드 로고볼 |
| `sku_code` | VARCHAR | 26AC-BA-HD-001 | Enum: 26AC-BA-HD-001, 8800356757700, 8800356758554 |
| `composition_type` | VARCHAR | SINGLE |  |
| `status` | VARCHAR | SALE | 상태값 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |
| `sku_group_id` | BIGINT | 293104036469952 | sku_group 참조 ID (FK) |
| `description` | VARCHAR | Baseball | Enum: Baseball, CDP, KEY RING |
| `material_code` | VARCHAR | NULL |  ⚠️ NULL 포함 |
| `country_of_origin` | VARCHAR | CN |  |
| `usage_type` | VARCHAR | MAIN |  |

## 주의사항
- `deleted_at`: NULL 비율 100%
- `material_code`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `length`: 135 / 145 / 230
- `width`: 135 / 145 / 230
- `name`: MINI DOLL KEY RING_D.O. / SUPER  CD PLAYER SET_LEETEUK / 삼성라이온즈 하드 로고볼
- `sku_code`: 26AC-BA-HD-001 / 8800356757700 / 8800356758554
- `description`: Baseball / CDP / KEY RING

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  manufacturer_id,
  height,
  length
FROM journi_y222.sku_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- length별 집계
SELECT
  length,
  COUNT(*) AS cnt
FROM journi_y222.sku_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY length
ORDER BY cnt DESC;
```
