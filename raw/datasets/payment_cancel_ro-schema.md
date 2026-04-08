# payment_cancel_ro 테이블
결제 취소 정보. 취소 금액, 사유, 처리 상태 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.payment_cancel_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 4
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 296890953503168 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2026-02-24 11:06:12.082 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2026-02-24 11:06:12.104 | 수정 일시 |
| `claim_id` | BIGINT | 296890953372096 | claim 참조 ID (FK) |
| `payment_id` | BIGINT | 296840619200960 | payment 참조 ID (FK) |
| `amount` | BIGINT | 23000.00 | 금액 |
| `currency` | VARCHAR | KRW | 통화 코드 |
| `pg_cancel_id` | VARCHAR | 1m01012602241824304049 | pg_cancel 참조 ID (FK) |
| `canceled_at` | TIMESTAMP | 2026-02-24 11:06:11.000 |  |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%

**Enum성 컬럼 값 목록:**
- `currency`: JPY / KRW
- `pg_cancel_id`: 13215FC635W0000167644308 / 1m01012601201421176929 / 1m01012602241824304049 / t1m0101260118153318a887

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  claim_id,
  payment_id,
  amount
FROM journi_y222.payment_cancel_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- currency별 집계
SELECT
  currency,
  COUNT(*) AS cnt
FROM journi_y222.payment_cancel_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY currency
ORDER BY cnt DESC;
```
