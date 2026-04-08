# user_delivery_address_ro 테이블
회원별 배송지 주소 정보. 이름, 전화번호, 주소, 기본 배송지 여부 등 포함.

## 기본 정보
- 엔진: Presto
- 경로: `journi_y222.user_delivery_address_ro`
- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')
- 샘플 데이터 행 수: 10
- PK 컬럼: `id`

## 컬럼 정의

| 컬럼명 | 타입 | 샘플값 | 설명 |
|--------|------|--------|------|
| `id` | BIGINT | 189435602905152 | 식별자 (PK) |
| `created_at` | TIMESTAMP | 2025-09-25 15:27:43.247 | 생성 일시 |
| `updated_at` | TIMESTAMP | 2025-09-25 15:27:43.247 | 수정 일시 |
| `user_id` | BIGINT | 189433112881664 | user 참조 ID (FK) |
| `default_address` | BIGINT | 1 | Enum: 0, 1 |
| `city` | VARCHAR | hirose-machi,naka-ku,hiroshima-shi | Enum: Kab. Malang, New Taipei City, hirose-machi,naka-ku,hiroshima-shi ⚠️ NULL 포함 |
| `country` | VARCHAR | KR | 국가 코드 |
| `state_or_province` | VARCHAR | hiroshima | Enum: East Java, Taiwan, hiroshima ⚠️ NULL 포함 |
| `deleted_at` | VARCHAR | NULL | 삭제 일시 (NULL이면 미삭제) ⚠️ NULL 포함 |

## 주의사항
- `deleted_at`: NULL 비율 100%
- `city`: NULL 비율 70%
- `state_or_province`: NULL 비율 70%

**Enum성 컬럼 값 목록:**
- `default_address`: 0 / 1
- `city`: Kab. Malang / New Taipei City / hirose-machi,naka-ku,hiroshima-shi
- `country`: ID / JP / KR / TW
- `state_or_province`: East Java / Taiwan / hiroshima

**JSON 형식 컬럼:**
- `default_address`: JSON 형식 (구조 가변적)

## 샘플 쿼리 (Presto 문법)

```sql
-- 기본 조회 (최근 1일)
SELECT
  id,
  created_at,
  updated_at,
  user_id,
  default_address,
  city
FROM journi_y222.user_delivery_address_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;
```

```sql
-- default_address별 집계
SELECT
  default_address,
  COUNT(*) AS cnt
FROM journi_y222.user_delivery_address_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY default_address
ORDER BY cnt DESC;
```

```sql
-- default_address JSON 파싱 조회
SELECT
  id,
  json_extract_scalar(default_address, '$.key') AS default_address_key
FROM journi_y222.user_delivery_address_ro
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND default_address IS NOT NULL
LIMIT 100;
```
