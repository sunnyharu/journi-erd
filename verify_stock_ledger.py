"""
재고수불부 검증 스크립트
stock_sample.xlsx를 읽어 stock_ledger.sql과 동일한 로직으로
재고수불부 DataFrame을 생성하고 stock_ledger_result.xlsx로 저장합니다.

기초재고/기말재고 계산 방법 (체인 기반):
  이벤트 로그의 before_quantity/after_quantity는 연속 체인을 이룸.
  기초재고 = 어떤 이벤트의 after_quantity에도 등장하지 않는 before_quantity
  기말재고 = 어떤 이벤트의 before_quantity에도 등장하지 않는 after_quantity
  이 방법은 동일 타임스탬프에 여러 이벤트가 병렬 처리된 경우에도 정확함.
"""

import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).parent
INPUT_FILE  = BASE_DIR / "stock_sample.xlsx"
OUTPUT_FILE = BASE_DIR / "stock_ledger_result.xlsx"

# ── 1. 데이터 로드 ────────────────────────────────────────────────────────────
xl = pd.read_excel(INPUT_FILE, sheet_name=None, dtype=str)

su        = xl["stock_usage_ro"].copy()
sku       = xl["sku_ro"].copy()
sku_group = xl["sku_group_ro"].copy()

su["updated_at"]       = pd.to_datetime(su["updated_at"])
su["before_quantity"]  = pd.to_numeric(su["before_quantity"])
su["after_quantity"]   = pd.to_numeric(su["after_quantity"])
su["delta"]            = pd.to_numeric(su["delta"])
su["dt"] = su["updated_at"].dt.date.astype(str)

# ── 2. 체인 기반 기초재고 / 기말재고 계산 ─────────────────────────────────────
# stock_id(창고)별로 체인을 분리해 기초/기말을 계산한 뒤 합산.
# 동일 SKU가 여러 창고에 분산된 경우에도 정확히 처리됨.

def get_opening_closing_per_stock(group):
    """
    (dt, sku_id, stock_id) 단위로 체인 집합 방식으로 기초/기말재고를 계산.
    - opening: before_quantity 집합 중 어떤 이벤트의 after_quantity에도 없는 값
    - closing: after_quantity 집합 중 어떤 이벤트의 before_quantity에도 없는 값
    - 순환 체인인 경우 가장 이른/늦은 타임스탬프 기준으로 fallback
    """
    bq_set = set(group["before_quantity"])
    aq_set = set(group["after_quantity"])
    opening_set = bq_set - aq_set
    closing_set = aq_set - bq_set

    if opening_set:
        opening = min(opening_set)
    else:
        earliest_ts = group["updated_at"].min()
        eg = group[group["updated_at"] == earliest_ts]
        cand = set(eg["before_quantity"]) - set(eg["after_quantity"])
        opening = min(cand) if cand else int(group.sort_values("updated_at").iloc[0]["before_quantity"])

    if closing_set:
        closing = max(closing_set)
    else:
        latest_ts = group["updated_at"].max()
        lg = group[group["updated_at"] == latest_ts]
        cand = set(lg["after_quantity"]) - set(lg["before_quantity"])
        closing = max(cand) if cand else int(group.sort_values("updated_at").iloc[-1]["after_quantity"])

    return pd.Series({"기초재고": int(opening), "기말재고": int(closing)})

# stock_id별로 기초/기말 계산 후 (dt, sku_id) 단위로 합산
per_stock = (
    su.groupby(["dt", "sku_id", "stock_id"])
    .apply(get_opening_closing_per_stock, include_groups=False)
    .reset_index()
)
stock_bounds = (
    per_stock.groupby(["dt", "sku_id"])[["기초재고", "기말재고"]]
    .sum()
    .reset_index()
)

# ── 3. type별 delta 합계 ──────────────────────────────────────────────────────
def sum_delta_by_type(df, type_val, col_name):
    mask = df["type"] == type_val
    return (
        df[mask]
        .groupby(["dt", "sku_id"])["delta"]
        .sum()
        .reset_index()
        .rename(columns={"delta": col_name})
    )

incoming_agg   = sum_delta_by_type(su, "INCOMING_COMPLETED",   "입고수량")
adjustment_agg = sum_delta_by_type(su, "ADJUSTMENT_COMPLETED", "조정수량")
out_req_agg    = sum_delta_by_type(su, "OUTGOING_REQUESTED",   "출고요청")
out_can_agg    = sum_delta_by_type(su, "OUTGOING_CANCELLED",   "출고취소")

net_delta = (
    su.groupby(["dt", "sku_id"])["delta"]
    .sum()
    .reset_index()
    .rename(columns={"delta": "순변동"})
)

# ── 4. SKU 정보 조인 ──────────────────────────────────────────────────────────
sku_info = (
    sku[sku["deleted_at"].isna()][["id", "name", "sku_code", "sku_group_id"]]
    .rename(columns={"id": "sku_id", "name": "sku_nm"})
    .merge(
        sku_group[sku_group["deleted_at"].isna()][["id", "biz_partner_id"]],
        left_on="sku_group_id", right_on="id",
        how="left"
    )
    .drop(columns=["id", "sku_group_id"])
)

# ── 5. 전체 결합 ──────────────────────────────────────────────────────────────
base = net_delta.copy()
for agg_df in [stock_bounds, incoming_agg, adjustment_agg, out_req_agg, out_can_agg]:
    base = base.merge(agg_df, on=["dt", "sku_id"], how="left")

num_cols = ["기초재고", "입고수량", "조정수량", "출고요청", "출고취소", "기말재고"]
base[num_cols] = base[num_cols].fillna(0).astype(int)

result = base.merge(sku_info, on="sku_id", how="left")
result = result[[
    "dt", "sku_id", "sku_nm", "sku_code", "biz_partner_id",
    "기초재고", "입고수량", "조정수량", "출고요청", "출고취소", "순변동", "기말재고"
]].sort_values(["dt", "biz_partner_id", "sku_id"])

# ── 6. 검증 출력 ──────────────────────────────────────────────────────────────
print(f"총 행수: {len(result)}")
print(f"날짜 범위: {result['dt'].min()} ~ {result['dt'].max()}")
print(f"고유 SKU 수: {result['sku_id'].nunique()}")

print("\n[일별 요약]")
summary = result.groupby("dt").agg(
    SKU수=("sku_id", "nunique"),
    입고합계=("입고수량", "sum"),
    조정합계=("조정수량", "sum"),
    출고요청합계=("출고요청", "sum"),
    출고취소합계=("출고취소", "sum"),
    순변동합계=("순변동", "sum"),
).reset_index()
print(summary.to_string(index=False))

print("\n[상위 10행 미리보기]")
print(result.head(10).to_string(index=False))

# 검증: 기초재고 + 순변동 = 기말재고
check = result.copy()
check["계산기말"] = check["기초재고"] + check["순변동"]
mismatch = check[check["계산기말"] != check["기말재고"]]
print(f"\n[검증] 기초재고 + 순변동 = 기말재고 불일치 건수: {len(mismatch)}")
if len(mismatch) > 0:
    print("불일치 샘플 (원인: 당일 동일 재고가 여러 체인 경로 존재 가능):")
    print(mismatch[["dt","sku_id","기초재고","순변동","계산기말","기말재고"]].head(10).to_string(index=False))

# ── 7. Excel 출력 ─────────────────────────────────────────────────────────────
with pd.ExcelWriter(OUTPUT_FILE, engine="openpyxl") as writer:
    result.to_excel(writer, sheet_name="재고수불부", index=False)
    summary.to_excel(writer, sheet_name="일별요약", index=False)

    from openpyxl.styles import Font, PatternFill, Alignment
    from openpyxl.utils import get_column_letter

    wb = writer.book

    header_font  = Font(name="Arial", bold=True, color="FFFFFF")
    header_fill  = PatternFill("solid", start_color="2F5496")
    header_align = Alignment(horizontal="center", vertical="center")
    num_fmt      = "#,##0;(#,##0);\"-\""

    # ── 재고수불부 시트 ──
    ws = wb["재고수불부"]
    col_widths = {"A":12,"B":20,"C":40,"D":22,"E":18,
                  "F":12,"G":12,"H":12,"I":12,"J":12,"K":12,"L":12}
    for col_letter, width in col_widths.items():
        ws.column_dimensions[col_letter].width = width

    for cell in ws[1]:
        cell.font      = header_font
        cell.fill      = header_fill
        cell.alignment = header_align

    num_col_idx = set(range(6, 13))  # F~L (1-indexed)
    for row in ws.iter_rows(min_row=2, max_row=ws.max_row):
        for cell in row:
            cell.font = Font(name="Arial")
            if cell.column in num_col_idx:
                cell.number_format = num_fmt
                cell.alignment = Alignment(horizontal="right")

    # ── 일별요약 시트 ──
    ws2 = wb["일별요약"]
    for cell in ws2[1]:
        cell.font      = header_font
        cell.fill      = header_fill
        cell.alignment = header_align
    for col in ws2.columns:
        ws2.column_dimensions[get_column_letter(col[0].column)].width = 16

print(f"\n저장 완료: {OUTPUT_FILE}")
