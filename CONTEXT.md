# 프로젝트 컨텍스트

## 프로젝트 개요
- **목적**: Journi 플랫폼 데이터 분석을 위한 ERD 대시보드 및 재고수불부 구축
- **최종 목표**: LLM 기반 분석 쿼리 자동 생성 툴 개발

## 디렉토리 구조
```
/Users/journi-y222-l/claude project/
├── erd_interactive.html      # ERD 대시보드 (브라우저에서 열기)
├── sync_erd.py               # schema.md → ERD HTML 동기화 스크립트
├── generate_schemas.py       # sample_data.xlsx → schema.md 자동 생성
├── sample_data.xlsx          # 테이블별 샘플 데이터 (67개 시트)
├── order.sql                 # 판매 집계 쿼리 (Presto)
├── stock.sql                 # 재고수불부 쿼리 (Presto, 초안)
└── raw/datasets/             # 67개 테이블 schema.md 파일
```

## 주요 작업 내역
- 65개 → 67개 테이블 스키마 문서화 (`community_artist_ro`, `partner_ro` 추가)
- `erd_interactive.html` ERD 대시보드 구축 및 git 관리
- `sync_erd.py` 자동화:
  - 컬럼명 변경 자동 반영
  - 컬럼 추가/삭제 자동 반영
  - 신규 테이블 ERD 자동 추가 (domain 자동 추론)
- git pre-commit hook: schema.md 변경 시 `sync_erd.py` 자동 실행
- `artist_ro`: `berrizartistid` → `artistid`, `berrizartistname` → `artistname` 컬럼명 수정
- `artist_shop_ro`: `berrizcommunitykey` → `communitykey` 등 수정

## 데이터 엔진
- **Presto** (쿼리 문법 기준)
- 테이블 경로: `journi_y222.테이블명`
- 파티션 컬럼: `dt` (VARCHAR, 'YYYY-MM-DD')

## 재고수불부 현황 및 과제
- `stock.sql` 초안: `stock_usage_ro` + `stock_ro` 기반
- **한계**: 기초재고가 상대값, 날짜 필터 없음, 창고 구분 없음
- **warehouse_ro 테이블 없음** (warehouse_id만 존재)
- 필요 테이블: `stock_usage_ro`, `stock_ro`, `incoming_ro`, `incoming_item_ro`, `outgoing_ro`, `outgoing_item_ro`, `adjustment_ro`, `sku_ro`, `sku_group_ro`

## order.sql 알려진 이슈
- 90번째 줄 문법 오류: `SELECT DISTINCT` 뒤 불필요한 `,`
- `community_artist_ro`, `partner_ro` 스키마 추가 완료
- `journi_y222.iso_code` 외부 테이블 (스키마 없음)

## 워크플로우: 새 테이블 추가 시
1. `sample_data.xlsx`에 새 시트 추가 → GitHub push
2. `git pull` → `python3 generate_schemas.py`
3. `git add raw/datasets/` + `git commit` → pre-commit hook 자동 실행
   - `sync_erd.py` 실행 → ERD 자동 업데이트 및 커밋 포함

## GitHub
- **Repository**: https://github.com/sunnyharu/journi_project
- **Branch**: main
