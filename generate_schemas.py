#!/usr/bin/env python3
"""Generate schema markdown files for each sheet in sample_data.xlsx"""

import pandas as pd
import numpy as np
import os
import re
from pathlib import Path

EXCEL_PATH = "/Users/journi-y222-l/Downloads/sample_data.xlsx"
OUTPUT_DIR = "/Users/journi-y222-l/claude project/raw/datasets"

# Known table descriptions based on domain knowledge + ERD
TABLE_DESCS = {
    "users_ro": "회원 기본 정보 테이블. 가입 국가, 회원 키, 상태, 접속 IP 등 포함.",
    "user_delivery_address_ro": "회원별 배송지 주소 정보. 이름, 전화번호, 주소, 기본 배송지 여부 등 포함.",
    "mall_ro": "쇼핑몰(브랜드/파트너) 기본 정보. i18n(다국어), 배너, 카테고리, URL 경로 등 포함.",
    "artist_ro": "아티스트 기본 정보. 이름, 프로필, 이미지 등 포함.",
    "product_ro": "상품 기본 정보. 상품명, 가격, 상태, SKU 그룹, 아티스트, 몰 연결 등 포함.",
    "product_snapshot_ro": "주문 시점 상품 스냅샷. 주문 생성 당시 상품 정보를 그대로 보존.",
    "sku_group_ro": "SKU 그룹(재고 묶음) 정보. 재고 관리 단위의 상위 그룹.",
    "sku_ro": "개별 SKU(재고 단위) 정보. 색상, 사이즈 등 옵션별 실제 재고 단위.",
    "sku_snapshot_ro": "주문 시점 SKU 스냅샷. 주문 생성 당시 SKU 정보를 그대로 보존.",
    "sku_option_ro": "SKU 옵션 정보. 각 SKU의 옵션 이름/값(색상, 사이즈 등).",
    "inventory_ro": "재고 수량 정보. SKU별 현재 재고량, 창고 연결.",
    "inventory_history_ro": "재고 변동 이력. 입출고, 취소 등 수량 변경 히스토리.",
    "cart_ro": "장바구니 정보. 회원별 담긴 상품(SKU) 목록.",
    "checkout_ro": "주문서(체크아웃) 정보. 결제 전 주문 생성 단계. 배송지, 쿠폰, 금액 등 포함.",
    "checkout_line_item_ro": "주문서 내 개별 상품 라인. 수량, 가격, SKU 등 포함.",
    "orders_ro": "최종 주문 정보. 결제 완료된 주문. 금액, 상태, 결제/배송 연결.",
    "order_line_item_ro": "주문 내 개별 상품 라인. 수량, 단가, 할인, 상태 등 포함.",
    "order_line_item_option_ro": "주문 라인 아이템의 추가 옵션(굿즈 옵션 등).",
    "claim_ro": "클레임(취소/반품/교환) 정보. 이유, 상태, 처리 결과 등 포함.",
    "claim_line_item_ro": "클레임 내 개별 상품 라인.",
    "delivery_ro": "배송 정보. 택배사, 송장번호, 배송 상태, 수령인 등 포함.",
    "delivery_line_item_ro": "배송 내 개별 상품 라인.",
    "payment_ro": "결제 정보. 결제 수단, 금액, 상태, PG사 연결 등 포함.",
    "payment_cancel_ro": "결제 취소 정보. 취소 금액, 사유, 처리 상태 등 포함.",
    "coupon_ro": "쿠폰 기본 정보. 쿠폰 코드, 할인율/금액, 유효기간, 조건 등 포함.",
    "coupon_issue_ro": "쿠폰 발급 이력. 회원별 발급된 쿠폰 및 사용 여부.",
    "coupon_use_ro": "쿠폰 사용 이력. 주문에 적용된 쿠폰 정보.",
    "point_ro": "포인트 정보. 회원별 포인트 잔액 및 적립/사용 이력.",
    "point_history_ro": "포인트 변동 이력. 적립/차감 사유, 금액 등.",
    "partner_ro": "파트너(공급사/브랜드) 기본 정보.",
    "partner_settlement_ro": "파트너 정산 정보. 정산 금액, 기간, 상태 등.",
    "settlement_ro": "정산 기본 정보. 정산 대상 주문/클레임 연결.",
    "settlement_line_item_ro": "정산 내 개별 상품 라인.",
    "notification_ro": "알림 발송 정보. 푸시/이메일/SMS 발송 이력.",
    "review_ro": "상품 리뷰 정보. 별점, 내용, 이미지, 좋아요 수 등.",
    "review_comment_ro": "리뷰 댓글 정보.",
    "review_like_ro": "리뷰 좋아요 정보.",
    "wishlist_ro": "위시리스트(찜) 정보. 회원별 찜한 상품 목록.",
    "event_ro": "이벤트 기본 정보. 이벤트명, 기간, 조건 등.",
    "event_participant_ro": "이벤트 참여 이력.",
    "search_log_ro": "검색 로그. 키워드, 결과 수, 클릭 등.",
    "display_ro": "전시/기획전 정보.",
    "display_product_ro": "전시별 상품 연결.",
    "category_ro": "상품 카테고리 정보.",
    "tag_ro": "상품 태그 정보.",
    "product_tag_ro": "상품-태그 연결 정보.",
    "exchange_rate_ro": "환율 정보. 국가별 통화 환율.",
    "country_ro": "국가 코드 및 정보.",
    "language_ro": "언어 코드 및 정보.",
    "currency_ro": "통화 코드 및 정보.",
    "warehouse_ro": "창고 정보. 재고 보관 위치.",
    "brand_ro": "브랜드 정보.",
    "cs_inquiry_ro": "CS 문의 정보. 문의 유형, 내용, 처리 상태.",
    "cs_inquiry_comment_ro": "CS 문의 댓글/답변.",
    "membership_ro": "멤버십 등급 정보.",
    "membership_history_ro": "멤버십 변동 이력.",
    "push_token_ro": "푸시 알림 토큰 정보.",
    "admin_ro": "관리자 계정 정보.",
    "log_ro": "시스템 로그.",
    "file_ro": "파일 업로드 정보.",
    "code_ro": "공통 코드 정보.",
    "config_ro": "시스템 설정 정보.",
}

# Columns that are likely JSON/object type
JSON_COL_PATTERNS = [
    r'snapshot', r'options?$', r'data$', r'info$', r'detail$', r'meta',
    r'address', r'images?$', r'categories?', r'slots', r'banners?',
    r'i18n', r'profile', r'ogimage', r'condition', r'discount',
]

def is_json_col(col_name):
    col_lower = col_name.lower()
    for pat in JSON_COL_PATTERNS:
        if re.search(pat, col_lower):
            return True
    return False

def infer_type(series, col_name):
    """Infer Presto data type from a pandas Series"""
    col_lower = col_name.lower()
    non_null = series.dropna()
    if len(non_null) == 0:
        return "VARCHAR"

    # ID columns
    if col_lower in ('id', '_id') or col_lower.endswith('_id'):
        # Check if numeric
        try:
            pd.to_numeric(non_null)
            return "BIGINT"
        except:
            return "VARCHAR"

    # Datetime columns
    if any(x in col_lower for x in ['_at', '_date', 'date_', 'time', '_dt', 'started', 'ended', 'created', 'updated', 'deleted', 'deactivated', 'expired', 'activated']):
        sample = str(non_null.iloc[0])
        if re.match(r'\d{4}-\d{2}-\d{2}', sample):
            if 'T' in sample or ':' in sample:
                return "TIMESTAMP"
            return "VARCHAR"  # date string
        return "VARCHAR"

    # JSON-like columns
    if is_json_col(col_lower):
        sample = str(non_null.iloc[0])
        if sample.startswith('{') or sample.startswith('['):
            return "VARCHAR (JSON)"

    # Try numeric
    try:
        numeric = pd.to_numeric(non_null)
        if (numeric == numeric.astype(int)).all():
            return "BIGINT"
        else:
            return "DOUBLE"
    except:
        pass

    # Boolean-like
    unique_vals = set(str(v).upper() for v in non_null.unique())
    if unique_vals <= {'TRUE', 'FALSE', '1', '0', 'YES', 'NO'}:
        return "BOOLEAN"

    # Check if it looks like a date string
    sample = str(non_null.iloc[0])
    if re.match(r'^\d{4}-\d{2}-\d{2}T', sample):
        return "TIMESTAMP"
    if re.match(r'^\d{4}-\d{2}-\d{2}$', sample):
        return "VARCHAR"

    return "VARCHAR"

def get_sample_val(series):
    """Get a clean sample value"""
    non_null = series.dropna()
    if len(non_null) == 0:
        return "NULL"
    val = non_null.iloc[0]
    s = str(val)
    # Truncate long values
    if len(s) > 60:
        s = s[:57] + "..."
    return s

def get_enum_vals(series, max_unique=15):
    """Return enum values if cardinality is low and values are short strings"""
    non_null = series.dropna()
    if len(non_null) == 0:
        return None
    unique = non_null.unique()
    if len(unique) <= max_unique and len(unique) > 1:
        # Check it's not just sequential numbers with wide range
        try:
            nums = pd.to_numeric(pd.Series(unique))
            if nums.max() - nums.min() > 100:
                return None  # too wide range = not enum
        except:
            pass
        # Skip if values are too long (not typical enum values)
        str_vals = [str(v) for v in unique]
        if any(len(v) > 80 for v in str_vals):
            return None
        return sorted(str_vals)
    return None

def col_desc(col_name, dtype, df, is_pk=False, is_fk=False):
    """Generate column description hint"""
    col_lower = col_name.lower()

    if col_lower in ('id', '_id'):
        return "식별자 (PK)"
    if is_pk:
        return "기본 키 (PK)"
    if col_lower.endswith('_id'):
        ref = col_lower.replace('_id', '')
        return f"{ref} 참조 ID (FK)"
    if col_lower in ('created_at',):
        return "생성 일시"
    if col_lower in ('updated_at',):
        return "수정 일시"
    if col_lower in ('deleted_at',):
        return "삭제 일시 (NULL이면 미삭제)"
    if col_lower in ('status',):
        return "상태값"
    if col_lower in ('type',):
        return "유형 구분"
    if col_lower in ('country',):
        return "국가 코드"
    if col_lower in ('currency',):
        return "통화 코드"
    if col_lower in ('amount', 'price', 'total', 'subtotal', 'discount'):
        return "금액"
    if col_lower in ('quantity', 'qty', 'count'):
        return "수량"
    if is_json_col(col_lower) and 'JSON' in dtype:
        return "JSON 형식 데이터"
    return ""

def detect_json_cols(df):
    """Detect columns that contain JSON strings"""
    json_cols = []
    for col in df.columns:
        non_null = df[col].dropna()
        if len(non_null) == 0:
            continue
        sample = str(non_null.iloc[0])
        if (sample.startswith('{') or sample.startswith('[')) and len(sample) > 5:
            json_cols.append(col)
        elif is_json_col(col.lower()):
            json_cols.append(col)
    return json_cols

def extract_json_fields(series):
    """Try to extract top-level keys from a JSON column"""
    import json
    fields = set()
    for val in series.dropna().head(10):
        try:
            obj = json.loads(str(val))
            if isinstance(obj, dict):
                fields.update(obj.keys())
            elif isinstance(obj, list) and len(obj) > 0 and isinstance(obj[0], dict):
                fields.update(obj[0].keys())
        except:
            pass
    return sorted(fields)

def generate_sample_queries(table_name, df, json_cols, enum_cols, nullable_cols, pk_col):
    """Generate Presto sample queries"""
    queries = []
    cols_str = ", ".join(df.columns[:8])

    # Query 1: Basic select with dt partition
    select_cols = ",\n  ".join(list(df.columns[:6]))
    q1 = f"""-- 기본 조회 (최근 1일)
SELECT
  {select_cols}
FROM journi_y222.{table_name}
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
LIMIT 100;"""
    queries.append(q1)

    # Query 2: Aggregation or status filter
    if enum_cols:
        enum_col = list(enum_cols.keys())[0]
        enum_vals = enum_cols[enum_col]
        first_val = enum_vals[0] if enum_vals else 'ACTIVE'
        q2 = f"""-- {enum_col}별 집계
SELECT
  {enum_col},
  COUNT(*) AS cnt
FROM journi_y222.{table_name}
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY {enum_col}
ORDER BY cnt DESC;"""
        queries.append(q2)
    elif pk_col:
        q2 = f"""-- 일별 신규 생성 건수 추이
SELECT
  dt,
  COUNT(*) AS cnt
FROM journi_y222.{table_name}
WHERE dt BETWEEN DATE_FORMAT(CURRENT_DATE - INTERVAL '7' DAY, '%Y-%m-%d')
              AND DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
GROUP BY dt
ORDER BY dt;"""
        queries.append(q2)

    # Query 3: JSON parsing query (if JSON cols exist)
    if json_cols:
        json_col = json_cols[0]
        import json as jsonlib
        non_null = df[json_col].dropna()
        fields = []
        for val in non_null.head(5):
            try:
                obj = jsonlib.loads(str(val))
                if isinstance(obj, dict):
                    fields = list(obj.keys())[:5]
                    break
            except:
                pass

        if fields:
            field_lines = "\n".join([f"  json_extract_scalar({json_col}, '$.{f}') AS {json_col}_{f}," for f in fields[:5]])
            q3 = f"""-- {json_col} JSON 파싱 조회
SELECT
  {pk_col or 'id'},
{field_lines.rstrip(',')}
FROM journi_y222.{table_name}
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND {json_col} IS NOT NULL
LIMIT 100;"""
        else:
            q3 = f"""-- {json_col} JSON 파싱 조회
SELECT
  {pk_col or 'id'},
  json_extract_scalar({json_col}, '$.key') AS {json_col}_key
FROM journi_y222.{table_name}
WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  AND {json_col} IS NOT NULL
LIMIT 100;"""
        queries.append(q3)

    return queries

def generate_md(sheet_name, df):
    """Generate markdown content for a sheet"""
    table_name = sheet_name
    table_desc = TABLE_DESCS.get(table_name, f"{table_name} 테이블 데이터.")

    total_rows = len(df)

    # Detect PK column
    pk_col = None
    for c in df.columns:
        if c.lower() in ('id', '_id'):
            pk_col = c
            break

    # Analyze each column
    col_rows = []
    nullable_cols = []
    enum_cols = {}
    json_cols_found = detect_json_cols(df)

    for col in df.columns:
        series = df[col]
        null_count = series.isna().sum()
        null_pct = null_count / total_rows * 100 if total_rows > 0 else 0

        dtype = infer_type(series, col)
        sample = get_sample_val(series)
        desc = col_desc(col, dtype, df, is_pk=(col == pk_col))

        # Enum detection
        enum_vals = get_enum_vals(series)
        col_lower = col.lower()
        is_likely_enum = any(x in col_lower for x in ['status', 'type', 'state', 'kind', 'method', 'reason', 'grade', 'level', 'role', 'gender', 'country', 'currency', 'lang'])

        # Never mark timestamp/datetime cols as enum
        is_datetime_col = any(x in col_lower for x in ['_at', '_date', 'createdat', 'updatedat', 'deletedat'])
        if enum_vals and not is_datetime_col and (is_likely_enum or (len(enum_vals) <= 8 and len(enum_vals) >= 2)):
            enum_cols[col] = enum_vals
            if not desc:
                desc = f"Enum: {', '.join(enum_vals[:6])}"

        if null_pct > 5:
            nullable_cols.append((col, null_pct))

        col_rows.append((col, dtype, sample, desc, null_pct, enum_vals))

    # Build markdown
    md_lines = []
    md_lines.append(f"# {table_name} 테이블")
    md_lines.append(f"{table_desc}")
    md_lines.append("")
    md_lines.append("## 기본 정보")
    md_lines.append("- 엔진: Presto")
    md_lines.append(f"- 경로: `journi_y222.{table_name}`")
    md_lines.append("- 파티션 컬럼: `dt` (VARCHAR, 형식: 'YYYY-MM-DD')")
    md_lines.append(f"- 샘플 데이터 행 수: {total_rows:,}")
    if pk_col:
        md_lines.append(f"- PK 컬럼: `{pk_col}`")
    md_lines.append("")

    # Column definitions
    md_lines.append("## 컬럼 정의")
    md_lines.append("")
    md_lines.append("| 컬럼명 | 타입 | 샘플값 | 설명 |")
    md_lines.append("|--------|------|--------|------|")

    for col, dtype, sample, desc, null_pct, enum_vals in col_rows:
        null_note = " ⚠️ NULL 포함" if null_pct > 30 else (" (nullable)" if null_pct > 5 else "")
        sample_display = sample.replace("|", "\\|").replace("\n", " ")
        desc_display = desc + null_note
        md_lines.append(f"| `{col}` | {dtype} | {sample_display} | {desc_display} |")

    md_lines.append("")

    # Notes
    md_lines.append("## 주의사항")
    notes = []

    if nullable_cols:
        for col, pct in sorted(nullable_cols, key=lambda x: -x[1])[:10]:
            notes.append(f"- `{col}`: NULL 비율 {pct:.0f}%")

    if enum_cols:
        notes.append("")
        notes.append("**Enum성 컬럼 값 목록:**")
        for col, vals in enum_cols.items():
            notes.append(f"- `{col}`: {' / '.join(vals)}")

    if json_cols_found:
        notes.append("")
        notes.append("**JSON 형식 컬럼:**")
        for jc in json_cols_found:
            fields = extract_json_fields(df[jc])
            if fields:
                notes.append(f"- `{jc}`: 주요 키 → {', '.join([f'`{f}`' for f in fields[:8]])}")
            else:
                notes.append(f"- `{jc}`: JSON 형식 (구조 가변적)")

    if not notes:
        notes.append("- 특이사항 없음")

    md_lines.extend(notes)
    md_lines.append("")

    # Sample queries
    md_lines.append("## 샘플 쿼리 (Presto 문법)")
    md_lines.append("")

    queries = generate_sample_queries(table_name, df, json_cols_found, enum_cols,
                                       {col: pct for col, pct in nullable_cols}, pk_col)

    for q in queries:
        md_lines.append("```sql")
        md_lines.append(q)
        md_lines.append("```")
        md_lines.append("")

    return "\n".join(md_lines)

def main():
    print(f"Reading {EXCEL_PATH}...")
    sheets = pd.read_excel(EXCEL_PATH, sheet_name=None, dtype=str)
    print(f"Found {len(sheets)} sheets")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    success = 0
    for i, (sheet_name, df) in enumerate(sheets.items(), 1):
        print(f"[{i:2d}/{len(sheets)}] Processing: {sheet_name} ({len(df)} rows, {len(df.columns)} cols)")
        try:
            md_content = generate_md(sheet_name, df)
            out_path = os.path.join(OUTPUT_DIR, f"{sheet_name}-schema.md")
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(md_content)
            success += 1
        except Exception as e:
            print(f"  ERROR: {e}")

    print(f"\nDone! {success}/{len(sheets)} files written to {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
