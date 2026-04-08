# exchange_rate_ro 테이블
환율 정보. 국가별 통화 환율.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.exchange_rate_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 10 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-06-25 00:41:13.892 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-06-30 14:00:28.198 | 수정 일시 |
| `base_unit` | BIGINT | 1 | Enum: 1, 100 |
| `exchange_rate` | DOUBLE | 1002.1800000000 |  |
| `base` | VARCHAR | CAD | Enum: CAD, IDR, JPY, KRW, USD |
| `counter` | VARCHAR | KRW | Enum: KRW, MOP, NZD, TRY, TWD, USD |
| `notified_at` | TIMESTAMP | 2025-06-30 13:59:32.000 |  |

## 주의사항

**Enum성 컬럼 값 목록:**
- `base_unit`: 1 / 100
- `base`: CAD / IDR / JPY / KRW / USD
- `counter`: KRW / MOP / NZD / TRY / TWD / USD

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  base_unit,
  exchange_rate,
  base
FROM journi_y222.exchange_rate_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- base_unit별 집계
SELECT
  base_unit,
  COUNT(*) AS cnt
FROM journi_y222.exchange_rate_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY base_unit
ORDER BY cnt DESC;
```
