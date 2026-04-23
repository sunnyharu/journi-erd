#!/usr/bin/env python3
"""
weekly_report.py — 주간 TOP 상품 외부 트렌드 자동 리포트

사용법:
  python weekly_report.py --start 2026-04-14 --end 2026-04-20 --input sample_input.csv

필수 패키지:
  pip install anthropic requests
"""

import argparse
import csv
import json
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

import anthropic
import requests


# ══════════════════════════════════════════════════════
# 1. CONFIG
# ══════════════════════════════════════════════════════

def load_config():
    path = Path(__file__).parent / "config.json"
    if not path.exists():
        print("❌ config.json 없음. config.json을 먼저 작성하세요.")
        sys.exit(1)
    with open(path, encoding="utf-8") as f:
        return json.load(f)


# ══════════════════════════════════════════════════════
# 2. 내부 데이터 (Redash에서 export한 CSV)
# ══════════════════════════════════════════════════════

def load_top_products(csv_path: str, top_n: int, weights: dict) -> list:
    """방문자 + 구매자 가중점수 기준 TOP N 추출"""
    products = []
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            visitor = int(row.get("visitor_cnt") or 0)
            buyer   = int(row.get("buyer_cnt")   or 0)
            products.append({
                "product_name": row.get("product_name", "").strip(),
                "artist_name":  row.get("artist_name",  "").strip(),
                "visitor_cnt":  visitor,
                "buyer_cnt":    buyer,
                "order_cnt":    int(row.get("order_cnt") or 0),
                "gmv":          int(float(row.get("gmv") or 0)),
                "score":        visitor * weights["visitor"] + buyer * weights["buyer"],
            })
    products.sort(key=lambda x: x["score"], reverse=True)
    return products[:top_n]


# ══════════════════════════════════════════════════════
# 3. 네이버 DataLab — 검색어 트렌드
# ══════════════════════════════════════════════════════

def get_search_trend(cid: str, csec: str, keyword: str, start: str, end: str) -> dict | None:
    """이번 주 vs 전주 검색량 지수 비교"""
    prev_start = (datetime.strptime(start, "%Y-%m-%d") - timedelta(days=7)).strftime("%Y-%m-%d")
    prev_end   = (datetime.strptime(end,   "%Y-%m-%d") - timedelta(days=7)).strftime("%Y-%m-%d")

    try:
        resp = requests.post(
            "https://openapi.naver.com/v1/datalab/search",
            headers={
                "X-Naver-Client-Id":     cid,
                "X-Naver-Client-Secret": csec,
                "Content-Type":          "application/json",
            },
            json={
                "startDate":    prev_start,
                "endDate":      end,
                "timeUnit":     "date",
                "keywordGroups": [{"groupName": keyword, "keywords": [keyword]}],
            },
            timeout=10,
        )
        resp.raise_for_status()
        data_list = resp.json().get("results", [{}])[0].get("data", [])

        this_w = [d["ratio"] for d in data_list if start <= d["period"] <= end]
        prev_w = [d["ratio"] for d in data_list if prev_start <= d["period"] <= prev_end]

        this_avg = round(sum(this_w) / len(this_w), 1) if this_w else 0
        prev_avg = round(sum(prev_w) / len(prev_w), 1) if prev_w else 0
        chg      = round((this_avg - prev_avg) / prev_avg * 100, 1) if prev_avg else 0

        return {
            "this_avg": this_avg,
            "prev_avg": prev_avg,
            "change_pct": chg,
            "daily": [{"date": d["period"], "ratio": d["ratio"]} for d in data_list if start <= d["period"] <= end],
            "prev_start": prev_start,
            "prev_end": prev_end,
        }
    except Exception as e:
        print(f"  ⚠️ DataLab 오류 ({keyword}): {e}")
        return None


# ══════════════════════════════════════════════════════
# 4. 네이버 뉴스 검색
# ══════════════════════════════════════════════════════

def get_news(cid: str, csec: str, keyword: str, start: str, end: str) -> list:
    """키워드 관련 최신 뉴스 5건"""
    TAG = re.compile(r"<[^>]+>")

    def clean(text: str) -> str:
        return TAG.sub("", text).replace("&quot;", '"').replace("&amp;", "&").strip()

    # pubDate 파싱 (예: "Mon, 14 Apr 2026 10:23:00 +0900")
    def parse_date(pub: str) -> str:
        try:
            return datetime.strptime(pub[:16], "%a, %d %b %Y").strftime("%Y-%m-%d")
        except Exception:
            return ""

    try:
        resp = requests.get(
            "https://openapi.naver.com/v1/search/news.json",
            headers={"X-Naver-Client-Id": cid, "X-Naver-Client-Secret": csec},
            params={"query": keyword, "display": 20, "sort": "date"},
            timeout=10,
        )
        resp.raise_for_status()
        items = resp.json().get("items", [])

        # 기간 필터 (클라이언트 사이드)
        filtered = []
        for item in items:
            pub_date = parse_date(item.get("pubDate", ""))
            if pub_date and start <= pub_date <= end:
                filtered.append({
                    "title":       clean(item.get("title", "")),
                    "link":        item.get("originallink") or item.get("link", ""),
                    "description": clean(item.get("description", "")),
                    "pubDate":     pub_date,
                })
            if len(filtered) >= 5:
                break

        # 기간 내 기사가 없으면 최근 5건이라도 반환
        if not filtered:
            for item in items[:5]:
                filtered.append({
                    "title":       clean(item.get("title", "")),
                    "link":        item.get("originallink") or item.get("link", ""),
                    "description": clean(item.get("description", "")),
                    "pubDate":     parse_date(item.get("pubDate", "")),
                })
        return filtered

    except Exception as e:
        print(f"  ⚠️ 뉴스 API 오류 ({keyword}): {e}")
        return []


# ══════════════════════════════════════════════════════
# 5. Claude 분석
# ══════════════════════════════════════════════════════

def analyze(client: anthropic.Anthropic, product: dict, trend: dict | None, news: list,
            start: str, end: str) -> str:
    conv_rate = (
        round(product["buyer_cnt"] / product["visitor_cnt"] * 100, 1)
        if product["visitor_cnt"] > 0 else 0
    )

    trend_text = "검색 트렌드 데이터 없음"
    if trend:
        direction = (
            "📈 상승" if trend["change_pct"] > 5
            else "📉 하락" if trend["change_pct"] < -5
            else "➡️ 보합"
        )
        trend_text = (
            f"네이버 검색량 지수: 이번주 평균 {trend['this_avg']} / 전주 평균 {trend['prev_avg']} "
            f"({direction} {abs(trend['change_pct'])}%)"
        )

    news_text = "\n".join(
        [f"- [{n['pubDate']}] {n['title']}: {n['description']}" for n in news]
    ) or "관련 뉴스 없음"

    prompt = f"""다음 상품의 주간 외부 트렌드를 분석해주세요.

## 상품 정보
- 상품명: {product['product_name']}
- 아티스트: {product['artist_name']}
- 분석 기간: {start} ~ {end}

## 내부 실적
- 방문자수: {product['visitor_cnt']:,}명
- 구매자수: {product['buyer_cnt']:,}명
- 전환율: {conv_rate}%
- 거래액: {product['gmv']:,}원

## 외부 트렌드
{trend_text}

## 관련 뉴스 ({len(news)}건)
{news_text}

아래 3가지를 각각 2~3문장으로 간결하게 작성해주세요:
1. **외부 트렌드 요약**: 이번 주 외부 반응 흐름
2. **내외부 연관성**: 내부 실적과 외부 트렌드의 관계
3. **다음 주 전망**: 한 줄로

마크다운 bold(**) 표시는 유지하고, 전체 200자 이내로 작성하세요."""

    msg = client.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=600,
        messages=[{"role": "user", "content": prompt}],
    )
    return msg.content[0].text


# ══════════════════════════════════════════════════════
# 6. HTML 리포트 생성
# ══════════════════════════════════════════════════════

def _trend_arrow(pct: float) -> str:
    if pct > 5:  return f'<span class="up">▲ {abs(pct):.1f}%</span>'
    if pct < -5: return f'<span class="dn">▼ {abs(pct):.1f}%</span>'
    return f'<span class="flat">― {abs(pct):.1f}%</span>'


def _sparkline(daily: list) -> str:
    """SVG 스파크라인"""
    if not daily:
        return ""
    vals = [d["ratio"] for d in daily]
    mn, mx = min(vals), max(vals)
    rng = mx - mn or 1
    W, H = 120, 32
    pts = []
    for i, v in enumerate(vals):
        x = i / max(len(vals) - 1, 1) * W
        y = H - ((v - mn) / rng * (H - 4) + 2)
        pts.append(f"{x:.1f},{y:.1f}")
    poly = " ".join(pts)
    return (
        f'<svg width="{W}" height="{H}" viewBox="0 0 {W} {H}" class="spark">'
        f'<polyline points="{poly}" fill="none" stroke="#6366f1" stroke-width="1.5" stroke-linejoin="round"/>'
        f"</svg>"
    )


def generate_html(results: list, start: str, end: str, out_path: str):
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    # 카드 HTML 생성
    cards_html = ""
    for rank, r in enumerate(results, 1):
        p   = r["product"]
        tr  = r["trend"]
        nws = r["news"]
        ai  = r["analysis"]

        conv = (
            round(p["buyer_cnt"] / p["visitor_cnt"] * 100, 1)
            if p["visitor_cnt"] > 0 else 0
        )

        # 트렌드 섹션
        if tr:
            spark_svg = _sparkline(tr.get("daily", []))
            trend_html = f"""
            <div class="trend-box">
              <div class="trend-row">
                <div>
                  <div class="trend-label">네이버 검색량 지수</div>
                  <div class="trend-nums">
                    이번주 <b>{tr['this_avg']}</b>
                    <span class="sep">vs</span>
                    전주 <b>{tr['prev_avg']}</b>
                    &nbsp;{_trend_arrow(tr['change_pct'])}
                  </div>
                </div>
                <div class="spark-wrap">{spark_svg}</div>
              </div>
            </div>"""
        else:
            trend_html = '<div class="no-data">검색 트렌드 데이터 없음</div>'

        # 뉴스 섹션
        if nws:
            news_items = "".join([
                f'<li><a href="{n["link"]}" target="_blank">{n["title"]}</a>'
                f'<span class="news-date">{n["pubDate"]}</span></li>'
                for n in nws
            ])
            news_html = f'<ul class="news-list">{news_items}</ul>'
        else:
            news_html = '<div class="no-data">관련 뉴스 없음</div>'

        # AI 분석 텍스트 (bold 처리)
        ai_html = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", ai)
        ai_html = ai_html.replace("\n", "<br>")

        cards_html += f"""
    <div class="card">
      <div class="card-rank">#{rank}</div>
      <div class="card-header">
        <div>
          <div class="product-name">{p['product_name']}</div>
          <div class="artist-name">{p['artist_name']}</div>
        </div>
        <div class="kpi-group">
          <div class="kpi">
            <div class="kpi-val">{p['visitor_cnt']:,}</div>
            <div class="kpi-label">방문자</div>
          </div>
          <div class="kpi">
            <div class="kpi-val">{p['buyer_cnt']:,}</div>
            <div class="kpi-label">구매자</div>
          </div>
          <div class="kpi">
            <div class="kpi-val">{conv}%</div>
            <div class="kpi-label">전환율</div>
          </div>
          <div class="kpi">
            <div class="kpi-val">₩{p['gmv']//10000:,}만</div>
            <div class="kpi-label">거래액</div>
          </div>
        </div>
      </div>

      <div class="card-body">
        <div class="col">
          <div class="col-title">📈 외부 검색 트렌드</div>
          {trend_html}
          <div class="col-title mt">📰 관련 뉴스</div>
          {news_html}
        </div>
        <div class="col ai-col">
          <div class="col-title">🤖 AI 트렌드 해석</div>
          <div class="ai-box">{ai_html}</div>
        </div>
      </div>
    </div>"""

    html = f"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>주간 트렌드 리포트 {start} ~ {end}</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    font-family: 'Apple SD Gothic Neo', 'Malgun Gothic', Arial, sans-serif;
    background: #f1f5f9;
    color: #1e293b;
    font-size: 13px;
    padding: 32px 24px;
  }}
  .page-header {{
    margin-bottom: 28px;
  }}
  .page-title {{
    font-size: 20px;
    font-weight: 700;
    color: #0f172a;
  }}
  .page-sub {{
    font-size: 12px;
    color: #64748b;
    margin-top: 4px;
  }}

  /* ── 카드 ── */
  .card {{
    background: #fff;
    border-radius: 14px;
    border: 1px solid #e2e8f0;
    margin-bottom: 20px;
    overflow: hidden;
    position: relative;
  }}
  .card-rank {{
    position: absolute;
    top: 14px; left: 16px;
    font-size: 11px;
    font-weight: 800;
    color: #94a3b8;
    letter-spacing: 0.5px;
  }}
  .card-header {{
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 20px 14px 46px;
    border-bottom: 1px solid #f1f5f9;
    flex-wrap: wrap;
    gap: 12px;
  }}
  .product-name {{
    font-size: 16px;
    font-weight: 700;
    color: #0f172a;
  }}
  .artist-name {{
    font-size: 12px;
    color: #64748b;
    margin-top: 2px;
  }}
  .kpi-group {{
    display: flex;
    gap: 24px;
    flex-wrap: wrap;
  }}
  .kpi {{
    text-align: center;
  }}
  .kpi-val {{
    font-size: 15px;
    font-weight: 700;
    color: #334155;
  }}
  .kpi-label {{
    font-size: 10px;
    color: #94a3b8;
    margin-top: 2px;
    font-weight: 600;
    letter-spacing: 0.3px;
  }}

  /* ── 카드 바디 ── */
  .card-body {{
    display: flex;
    gap: 0;
  }}
  .col {{
    flex: 1;
    padding: 16px 20px;
    min-width: 0;
  }}
  .col + .col {{
    border-left: 1px solid #f1f5f9;
  }}
  .ai-col {{
    background: #fafbff;
    flex: 0 0 340px;
  }}
  .col-title {{
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.8px;
    text-transform: uppercase;
    color: #94a3b8;
    margin-bottom: 10px;
  }}
  .col-title.mt {{ margin-top: 16px; }}

  /* ── 트렌드 박스 ── */
  .trend-box {{
    background: #f8faff;
    border: 1px solid #e0e7ff;
    border-radius: 8px;
    padding: 10px 14px;
  }}
  .trend-row {{
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }}
  .trend-label {{
    font-size: 11px;
    color: #64748b;
    margin-bottom: 4px;
  }}
  .trend-nums {{
    font-size: 13px;
    color: #334155;
  }}
  .trend-nums b {{ color: #1e293b; }}
  .sep {{ color: #cbd5e1; margin: 0 4px; }}
  .up   {{ color: #16a34a; font-weight: 700; }}
  .dn   {{ color: #dc2626; font-weight: 700; }}
  .flat {{ color: #64748b; font-weight: 700; }}
  .spark-wrap {{ flex-shrink: 0; }}
  .spark {{ display: block; }}

  /* ── 뉴스 리스트 ── */
  .news-list {{
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }}
  .news-list li {{
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 8px;
    font-size: 12px;
    line-height: 1.5;
    border-bottom: 1px solid #f8fafc;
    padding-bottom: 5px;
  }}
  .news-list li:last-child {{ border-bottom: none; padding-bottom: 0; }}
  .news-list a {{
    color: #3b4ff8;
    text-decoration: none;
    flex: 1;
  }}
  .news-list a:hover {{ text-decoration: underline; }}
  .news-date {{
    font-size: 10px;
    color: #94a3b8;
    white-space: nowrap;
    flex-shrink: 0;
  }}

  /* ── AI 박스 ── */
  .ai-box {{
    font-size: 12.5px;
    line-height: 1.8;
    color: #334155;
    background: #fff;
    border: 1px solid #e0e7ff;
    border-radius: 8px;
    padding: 12px 14px;
  }}
  .ai-box strong {{ color: #4f46e5; }}

  /* ── 기타 ── */
  .no-data {{
    font-size: 12px;
    color: #cbd5e1;
    padding: 6px 0;
  }}
  .footer {{
    margin-top: 24px;
    text-align: right;
    font-size: 11px;
    color: #94a3b8;
  }}

  @media (max-width: 800px) {{
    .card-body {{ flex-direction: column; }}
    .ai-col {{ flex: 1; border-left: none; border-top: 1px solid #f1f5f9; }}
  }}
</style>
</head>
<body>

<div class="page-header">
  <div class="page-title">📊 주간 실적 트렌드 리포트</div>
  <div class="page-sub">분석 기간: {start} ~ {end} &nbsp;|&nbsp; 생성: {now} &nbsp;|&nbsp; TOP {len(results)} 상품 (방문자·구매자 가중 점수 기준)</div>
</div>

{cards_html}

<div class="footer">Generated by weekly_report.py · Claude API + Naver DataLab/News</div>
</body>
</html>"""

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)


# ══════════════════════════════════════════════════════
# 7. MAIN
# ══════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="주간 TOP 상품 외부 트렌드 리포트")
    parser.add_argument("--start",  required=True, help="시작일 YYYY-MM-DD")
    parser.add_argument("--end",    required=True, help="종료일 YYYY-MM-DD")
    parser.add_argument("--input",  required=True, help="주간 데이터 CSV 경로")
    parser.add_argument("--top",    type=int, default=None, help="TOP N 상품 수 (기본: config.json의 top_n)")
    parser.add_argument("--output", default=None, help="출력 HTML 파일명 (기본: report_YYYYMMDD_YYYYMMDD.html)")
    args = parser.parse_args()

    cfg    = load_config()
    top_n  = args.top or cfg.get("top_n", 5)
    w      = cfg.get("score_weight", {"visitor": 0.4, "buyer": 0.6})
    out    = args.output or f"report_{args.start}_{args.end}.html"

    print(f"\n📊 주간 트렌드 리포트 생성 시작")
    print(f"   기간: {args.start} ~ {args.end}")
    print(f"   TOP {top_n}개 상품 · 가중치: 방문자 {w['visitor']} / 구매자 {w['buyer']}\n")

    products = load_top_products(args.input, top_n, w)
    if not products:
        print("❌ CSV에서 상품 데이터를 읽을 수 없습니다.")
        sys.exit(1)

    print(f"✅ 상품 로드 완료: {len(products)}개")
    for i, p in enumerate(products, 1):
        print(f"   {i}. {p['product_name']} ({p['artist_name']}) — 방문자 {p['visitor_cnt']:,} / 구매자 {p['buyer_cnt']:,}")

    claude  = anthropic.Anthropic(api_key=cfg["claude_api_key"])
    cid     = cfg["naver_client_id"]
    csec    = cfg["naver_client_secret"]

    results = []
    for i, product in enumerate(products, 1):
        print(f"\n[{i}/{len(products)}] {product['product_name']} 분석 중...")

        print("  → DataLab 검색 트렌드 조회")
        trend = get_search_trend(cid, csec, product["product_name"], args.start, args.end)

        kw = f"{product['artist_name']} {product['product_name']}"
        print(f"  → 뉴스 검색 ({kw})")
        news = get_news(cid, csec, kw, args.start, args.end)
        print(f"     기사 {len(news)}건 수집")

        print("  → Claude 분석 중...")
        ai_text = analyze(claude, product, trend, news, args.start, args.end)

        results.append({"product": product, "trend": trend, "news": news, "analysis": ai_text})
        print("  ✓ 완료")

    out_path = Path(__file__).parent / out
    generate_html(results, args.start, args.end, str(out_path))
    print(f"\n✅ 리포트 생성 완료: {out_path}")


if __name__ == "__main__":
    main()
