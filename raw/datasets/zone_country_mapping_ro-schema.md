# zone_country_mapping_ro 테이블
zone_country_mapping_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.zone_country_mapping_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 4 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-06-30 17:08:03.211 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-06-30 17:08:03.211 | 수정 일시 |
| `country` | VARCHAR | GM | 국가 코드 |
| `zone_code` | VARCHAR | J | Enum: H, I, J, K, M, Z |

## 주의사항

**Enum성 컬럼 값 목록:**
- `country`: BE / BR / CC / CN / EG / GM / RS / TG / TL / TV
- `zone_code`: H / I / J / K / M / Z

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  country,
  zone_code
FROM journi_y222.zone_country_mapping_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- country별 집계
SELECT
  country,
  COUNT(*) AS cnt
FROM journi_y222.zone_country_mapping_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY country
ORDER BY cnt DESC;
```
