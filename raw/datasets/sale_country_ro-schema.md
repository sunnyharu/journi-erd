# sale_country_ro 테이블
sale_country_ro 테이블 데이터.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.sale_country_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 8 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-09-29 08:11:41.706 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-09-29 08:11:41.706 | 수정 일시 |
| `country` | VARCHAR | TH | 국가 코드 |
| `currency` | VARCHAR | THB | 통화 코드 |
| `name` | VARCHAR | 태국 |  |
| `language` | VARCHAR | EN | Enum: EN, JA, ZH_HANS |

## 주의사항

**Enum성 컬럼 값 목록:**
- `country`: AU / BR / JP / MN / RU / SG / TH / TR / US / VN
- `currency`: AUD / BRL / JPY / MNT / RUB / SGD / THB / TRY / USD / VND
- `language`: EN / JA / ZH_HANS

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  country,
  currency,
  name
FROM journi_y222.sale_country_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- country별 집계
SELECT
  country,
  COUNT(*) AS cnt
FROM journi_y222.sale_country_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY country
ORDER BY cnt DESC;
```
