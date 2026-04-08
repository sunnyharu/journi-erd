#!/usr/bin/env python3
"""
schema.md 65개를 파싱해서 erd_interactive.html의
COL_DESCS / ENUM_VALS / TABLES 타입을 업데이트한다.
"""

import os, re, json

SCHEMA_DIR = "/Users/journi-y222-l/claude project/raw/datasets"
ERD_FILE   = "/Users/journi-y222-l/Downloads/erd_interactive.html"

# ──────────────────────────────────────────────────────────────
# 1. schema.md 파싱
# ──────────────────────────────────────────────────────────────

def parse_schema_md(path):
    """
    Returns:
      cols  : [ {name, type, sample, desc} ]
      enums : { col_name: [val, ...] }
      json_cols : [ col_name ]
      nullable_cols: [ col_name ]   (NULL 비율 > 5%)
    """
    with open(path, encoding='utf-8') as f:
        text = f.read()

    cols = []
    enums = {}
    json_cols = []
    nullable_cols = []

    # 컬럼 정의 테이블 파싱 (| `col` | TYPE | sample | desc |)
    in_table = False
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('| 컬럼명') or line.startswith('|-----'):
            in_table = True
            continue
        if in_table and line.startswith('|'):
            parts = [p.strip() for p in line.split('|')]
            parts = [p for p in parts if p != '']
            if len(parts) < 3:
                continue
            col_raw  = parts[0].strip('`')
            type_raw = parts[1].strip()
            sample   = parts[2].strip() if len(parts) > 2 else ''
            desc     = parts[3].strip() if len(parts) > 3 else ''

            # nullable 감지
            if '⚠️ NULL' in desc or '(nullable)' in desc:
                nullable_cols.append(col_raw)
            # desc 정리
            desc = re.sub(r'⚠️ NULL 포함|\\(nullable\\)', '', desc).strip()

            # JSON 타입
            if 'JSON' in type_raw:
                json_cols.append(col_raw)

            cols.append({'name': col_raw, 'type': type_raw, 'sample': sample, 'desc': desc})
        elif in_table and not line.startswith('|'):
            # 테이블 끝났으면 다음 섹션
            if line.startswith('##'):
                in_table = False

    # 주의사항 섹션에서 Enum 값 추출
    # 패턴: - `col_name`: VAL1 / VAL2 / VAL3
    enum_section = re.search(r'\*\*Enum성 컬럼 값 목록:\*\*(.*?)(?=\*\*|##|$)', text, re.DOTALL)
    if enum_section:
        for m in re.finditer(r'-\s*`(.+?)`:\s*(.+)', enum_section.group(1)):
            col = m.group(1).strip()
            vals_raw = m.group(2).strip()
            vals = [v.strip() for v in vals_raw.split(' / ') if v.strip()]
            # 80자 초과 val은 제외 (긴 JSON 값)
            vals = [v for v in vals if len(v) <= 80]
            # timestamp처럼 보이는 값 제외
            vals = [v for v in vals if not re.match(r'\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}', v)]
            if vals:
                enums[col] = vals

    return cols, enums, json_cols, nullable_cols


# ──────────────────────────────────────────────────────────────
# 2. 타입 매핑 (schema.md → ERD 내부 short 타입)
# ──────────────────────────────────────────────────────────────

def to_short_type(type_str):
    t = type_str.upper()
    if 'TIMESTAMP' in t:  return 'ts'
    if 'BIGINT'   in t:   return 'bigint'
    if 'DOUBLE'   in t:   return 'double'
    if 'BOOLEAN'  in t:   return 'bool'
    if 'JSON'     in t:   return 'json'
    return 'varchar'


# ──────────────────────────────────────────────────────────────
# 3. 전체 스키마 수집
# ──────────────────────────────────────────────────────────────

all_cols    = {}   # table -> [ {name,type,sample,desc} ]
all_enums   = {}   # table -> { col: [val] }
all_json    = {}   # table -> [ col ]
all_nullable= {}   # table -> [ col ]

for fname in sorted(os.listdir(SCHEMA_DIR)):
    if not fname.endswith('-schema.md'):
        continue
    table = fname.replace('-schema.md', '')
    path  = os.path.join(SCHEMA_DIR, fname)
    cols, enums, jcols, ncols = parse_schema_md(path)
    all_cols[table]     = cols
    all_enums[table]    = enums
    all_json[table]     = jcols
    all_nullable[table] = ncols

print(f"Parsed {len(all_cols)} schema files")


# ──────────────────────────────────────────────────────────────
# 4. COL_DESCS JS 문자열 생성
# ──────────────────────────────────────────────────────────────

def escape_js(s):
    return s.replace('\\', '\\\\').replace("'", "\\'")

col_descs_lines = ["const COL_DESCS = {"]
for table, cols in sorted(all_cols.items()):
    entries = []
    for c in cols:
        desc = c['desc']
        if not desc:
            continue
        entries.append(f"    {c['name']}:'{escape_js(desc)}'")
    if entries:
        col_descs_lines.append(f"  {table}: {{")
        col_descs_lines.append(",\n".join(entries))
        col_descs_lines.append("  },")
col_descs_lines.append("};")
COL_DESCS_JS = "\n".join(col_descs_lines)


# ──────────────────────────────────────────────────────────────
# 5. ENUM_VALS JS 문자열 생성
# ──────────────────────────────────────────────────────────────

enum_vals_lines = ["const ENUM_VALS = {"]
for table, enums in sorted(all_enums.items()):
    if not enums:
        continue
    entries = []
    for col, vals in sorted(enums.items()):
        vals_js = json.dumps(vals, ensure_ascii=False)
        entries.append(f"    {col}:{vals_js}")
    if entries:
        enum_vals_lines.append(f"  {table}: {{")
        enum_vals_lines.append(",\n".join(entries))
        enum_vals_lines.append("  },")
enum_vals_lines.append("};")
ENUM_VALS_JS = "\n".join(enum_vals_lines)


# ──────────────────────────────────────────────────────────────
# 6. HTML 읽기 → 3개 블록 교체
# ──────────────────────────────────────────────────────────────

with open(ERD_FILE, encoding='utf-8') as f:
    html = f.read()

# 6-a. COL_DESCS 교체
old_col_descs = re.search(r'const COL_DESCS = \{.*?\};', html, re.DOTALL)
if old_col_descs:
    html = html[:old_col_descs.start()] + COL_DESCS_JS + html[old_col_descs.end():]
    print("✅ COL_DESCS replaced")
else:
    print("⚠️  COL_DESCS not found")

# 6-b. ENUM_VALS 교체
old_enum_vals = re.search(r'const ENUM_VALS = \{.*?\};', html, re.DOTALL)
if old_enum_vals:
    html = html[:old_enum_vals.start()] + ENUM_VALS_JS + html[old_enum_vals.end():]
    print("✅ ENUM_VALS replaced")
else:
    print("⚠️  ENUM_VALS not found")

# 6-c. TABLES 내 컬럼 타입 업데이트
# 각 테이블의 cols 배열에서 ['colname','oldtype','annotation'] 패턴을 찾아
# schema.md 기반의 새 타입으로 교체 (annotation은 유지)

type_updates = 0
for table, cols in all_cols.items():
    type_map = {c['name']: to_short_type(c['type']) for c in cols}
    for col_name, new_type in type_map.items():
        # ['col_name','old_type','annotation']  or  ['col_name','old_type']
        pattern = rf"(\['{re.escape(col_name)}',\s*')[^']*('(?:,\s*'[^']*')?\])"
        def replacer(m, nt=new_type):
            return m.group(1) + nt + m.group(2)
        new_html, n = re.subn(pattern, replacer, html)
        if n > 0:
            html = new_html
            type_updates += n

print(f"✅ TABLES type updates: {type_updates} cells")


# ──────────────────────────────────────────────────────────────
# 7. nullable 컬럼에 시각적 힌트 data 속성 추가 (선택)
#    renderTableCard에서 data-nullable을 이미 지원하면 활용 가능
# (현재는 COL_DESCS desc에 "(nullable)" 텍스트로 힌트 전달)
# ──────────────────────────────────────────────────────────────

# 저장
with open(ERD_FILE, 'w', encoding='utf-8') as f:
    f.write(html)

print(f"\n✅ Done. Saved: {ERD_FILE}")
print(f"   COL_DESCS tables : {len(all_cols)}")
print(f"   ENUM_VALS tables : {sum(1 for e in all_enums.values() if e)}")
print(f"   JSON cols total  : {sum(len(v) for v in all_json.values())}")
print(f"   Nullable cols    : {sum(len(v) for v in all_nullable.values())}")
