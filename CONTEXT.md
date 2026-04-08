# 프로젝트 컨텍스트

## 프로젝트 개요
- **목적**: Journi 플랫폼 데이터 분석을 위한 ERD 대시보드 및 재고수불부 구축
- **최종 목표**: LLM 기반 분석 쿼리 자동 생성 툴 개발

## 디렉토리 구조
```
/Users/journi-y222-l/claude project/
├── erd_interactive.html        # ERD 대시보드 (브라우저에서 열기)
├── sync_erd.py                 # schema.md → ERD HTML 동기화 스크립트
├── generate_schemas.py         # sample_data.xlsx → schema.md 자동 생성
├── sample_data.xlsx            # 테이블별 샘플 데이터 (67개 시트)
├── extract_stock_sample.py     # Presto → stock_sample.xlsx 추출 스크립트
├── stock_sample.xlsx           # 재고 관련 9개 테이블 샘플 데이터 (실제 데이터)
├── stock_ledger.sql            # 재고수불부 Presto 쿼리
├── stock_ledger_result.xlsx    # 재고수불부 검증 결과 (재고수불부 + 일별요약 시트)
├── verify_stock_ledger.py      # stock_sample.xlsx 기반 재고수불부 Python 검증 스크립트
├── work_order.sql              # 작업지시서 6개 시트 Presto 쿼리 (ERD 기준, dt 없음)
├── sku_dashboard.py            # SKU 통합 현황 대시보드 생성 스크립트
├── sku_dashboard.xlsx          # SKU 통합 현황 결과 (4개 시트)
├── order.sql                   # 판매 집계 쿼리 (Presto)
├── stock.sql                   # 재고수불부 쿼리 초안 (구버전)
└── raw/datasets/               # 67개 테이블 schema.md 파일
```

## 데이터 엔진
- **Presto** (쿼리 문법 기준)
- 테이블 경로: `journi_y222.테이블명` (또는 `ods_commerce_production.테이블명`)
- 파티션 컬럼: `dt` (VARCHAR, 'YYYY-MM-DD')
- Presto 접속: `host='presto-adhoc.ka.io', port=8443, user='journi-y222', catalog='hadoop_kent'`

---

## ERD 대시보드

### 구축 내용
- 67개 테이블 스키마 문서화 (`raw/datasets/` 아래 각 `*-schema.md`)
- `erd_interactive.html`: 인터랙티브 ERD (도메인별 컬러, 컬럼 클릭 포커스 모드)
- `sync_erd.py` 자동화:
  - 컬럼명 변경/추가/삭제 자동 반영
  - 신규 테이블 ERD 자동 추가 (domain 자동 추론)
- git pre-commit hook: schema.md 변경 시 `sync_erd.py` 자동 실행

### 워크플로우: 새 테이블 추가 시
1. `sample_data.xlsx`에 새 시트 추가 → GitHub push
2. `git pull` → `python3 generate_schemas.py`
3. `git add raw/datasets/` + `git commit` → pre-commit hook 자동 실행
   - `sync_erd.py` 실행 → ERD 자동 업데이트 및 커밋 포함

---

## 재고수불부 (Stock Ledger)

### 핵심 테이블
`stock_usage_ro`, `stock_ro`, `incoming_ro`, `incoming_item_ro`,
`outgoing_ro`, `outgoing_item_ro`, `adjustment_ro`, `sku_ro`, `sku_group_ro`

### stock_usage_ro.type 종류
| type | 의미 | delta 방향 |
|------|------|-----------|
| `INCOMING_COMPLETED` | 입고 완료 | + |
| `ADJUSTMENT_COMPLETED` | 재고 조정 | +/- |
| `OUTGOING_COMPLETED` | 출고 완료 | - |
| `OUTGOING_REQUESTED` | 출고 예약 (가용→reserved) | - |
| `OUTGOING_CANCELLED` | 출고 취소 (예약 해제) | + |

### verify_stock_ledger.py 주요 로직
- **기초/기말재고 계산**: stock_id(창고)별로 이벤트 체인을 분리해서 기초/기말 계산 후 (dt, sku_id) 단위로 합산
  - 멀티창고 SKU 오류 수정: 동일 SKU가 여러 창고에 있을 때 min/max 혼합 버그 제거
- **검증**: 기초재고 + 순변동 = 기말재고 → **882행 전체 불일치 0건**
- **일별요약 이월(carry-forward)**: 당일 미활동 SKU는 전날 기말재고를 이월하여 창고 전체 재고 추이 집계
  - 이 방식이어야 날짜 간 기초/기말이 연속성 있게 이어짐

### stock_ledger_result.xlsx 컬럼 구성
**재고수불부 시트**: dt, sku_id, sku_nm, sku_code, biz_partner_id, 기초재고, 입고수량, 조정수량, 출고완료, 출고요청, 출고취소, 순변동, 기말재고

**일별요약 시트**: dt, 활동SKU수, 기초재고합계_이월포함, 입고합계, 조정합계, 출고완료합계, 출고요청합계, 출고취소합계, 순변동합계, 기말재고합계_이월포함

### extract_stock_sample.py 설정
- 기간: `START_DATE='2026-03-23'`, `END_DATE='2026-03-29'`, `SKU_START='2025-11-20'`
- 출력: 단일 Excel 파일 (`stock_sample.xlsx`) — 9개 시트 (테이블명)
- sku_ro 필터: `stock_usage_ro`에 존재하는 sku_id 기준 (incoming_item_ro 아님)
- 날짜 필터: `date(created_at AT TIME ZONE 'Asia/Seoul') BETWEEN date(START) AND date(END)`

---

## 작업지시서 (Work Order)

### 테이블 매핑 (가이드 → 실제)
| 가이드 | 실제 테이블 | 비고 |
|--------|-----------|------|
| `delivery` | `delivery_ro` | `delivery_ro.outgoing_id` → `outgoing_ro.id` |
| `delivery_item` | `delivery_item_ro` | `delivery_id`, `sku_id`, `quantity`, `item_info(JSON)` |
| `sku` | `sku_ro` | `composition_type` = SINGLE / BOM |
| `bom_component` | `bundled_sku_ro` | 컬럼명만 다름 |

### bundled_sku_ro 컬럼 매핑
| 가이드 컬럼 | 실제 컬럼 | 의미 |
|------------|---------|------|
| `bom_component.sku_id` | `bundled_sku_ro.sku_id` | BOM 완제품 SKU |
| `bom_component.component_sku_id` | `bundled_sku_ro.bundled_sku_id` | BOM 구성요소 SKU |
| `bom_component.quantity` | `bundled_sku_ro.quantity` | 구성 단위 수량 |

### work_order.sql 시트 구성
| 시트 | 내용 |
|------|------|
| Sheet 1 | 출고수량 — BOM 완제품 + 구성요소 SKU 전체 |
| Sheet 2 | 이관지시서 — 구성요소 필요 수량 (완제품 전개분 + 직접 포함분) |
| Sheet 3 | 유니폼 제작 필요 — BOM 완제품만 |
| Sheet 4 | 재고조정양식 — Sheet2 + `direction='M'`, `reason='ETC'` |
| Sheet 5 | CJ창고 입고요청 — Sheet1 + `type='G'` |
| Sheet 6 | 생산입고요청 — Sheet3 + `type='P'` |

### BOM 재고 영향
- 샘플 데이터 기준: BOM SKU 116개, SINGLE SKU 318개
- BOM 완제품 출고 시 `stock_usage_ro`에는 구성요소(SINGLE) 레벨로 대부분 기록됨
  - BOM OUTGOING_COMPLETED: 123건 vs SINGLE OUTGOING_COMPLETED: 19,139건

---

## SKU 통합 대시보드 (sku_dashboard.py)

### 개요
재고가용 + 출고이행률 + 기간재고변동을 SKU 기준으로 통합한 Excel 대시보드.
`stock_sample.xlsx` 읽어서 `sku_dashboard.xlsx` 생성.

### 시트 구성
| 시트 | 대상 | 내용 |
|------|------|------|
| 전체현황 | 전체 조회 | 434개 SKU 전체 |
| 미처리출고 🔴 | 물류팀 | 미처리수량 > 0인 58개 SKU |
| 재고부족위험 ⚠️ | MD/운영팀 | 가용재고 < 미처리수량인 46개 SKU |
| 이행완료 ✅ | 운영팀 | 이행률 100%인 153개 SKU |

### 컬럼 구성 (색상 섹션 구분)
- **[기본정보]** SKU ID/명/코드/거래처/구성유형/상태
- **[재고가용현황]** 물리재고, 가용재고, 예약재고 (stock_ro)
- **[출고이행률]** 출고지시수량, 실출고수량, 미처리수량, 이행률(%), 미처리사유 (outgoing_item_ro)
- **[기간변동]** 기간_입고, 기간_출고완료, 기간_조정 (stock_usage_ro)

### 기간변동 설명
- 샘플 기간(03-23~03-29) 동안 stock_usage_ro에 기록된 실제 재고 이벤트 집계
- 기간_출고완료 ≈ 실출고수량 이어야 정상 (차이 발생 시 직접 재고 조정 가능성)
- **다음 세션 논의 사항**: 기간변동과 출고이행률 중복 여부 검토, 필요시 통합

### 현재 데이터 한계
- 주문(orders_ro, order_line_ro) 데이터 없음 → 주문→출고→배송 전체 추적 불가
- stock_usage_ro에 OUTGOING_REQUESTED 없음 → 출고 예약은 stock_ro에서 직접 차감하는 방식
- 샘플 기간 한정 데이터 (실시간 아님)

## 알려진 이슈
- `order.sql` 90번째 줄: `SELECT DISTINCT` 뒤 불필요한 `,` (문법 오류)
- `journi_y222.iso_code`: 외부 테이블, 스키마 없음
- `warehouse_ro` 테이블 없음 (warehouse_id만 존재)

## GitHub
- **Repository**: https://github.com/sunnyharu/journi_project
- **Branch**: main
