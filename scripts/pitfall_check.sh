#!/bin/sh
# [M4-b] 坑账本字段审计：每条坑必须有「根因」「状态」「证据」，缺任一项即阻断（既有规则，不变）
# ADR-034 实质校验（ENFORCE=1 阻断、默认告警退 0；接线同 skills_index_check 的 SKILL_META_ENFORCE 风格）：
#   ① 状态枚举双轨（对抗审查③）：规范词=已落实|待落实|已升级|已闭环|已记录|部分落实；
#      祖传词=已修复|已落条款|机制已定|项目侧已追加更正——祖传词仅存量条目豁免
#      （命中输出告警"祖传状态词，新条目禁用，见 ADR-034"，不阻断）；新增条目须用规范词；
#      既非规范词也非祖传词 → ENFORCE 下 fail、默认告警。
#   ② 证据分级（对抗审查④）：强证据=含反引号 / file:line（形如 .sh|.md|.py|.conf|.ps1|.txt|.json:行号）/
#      无（待落实）任一，ENFORCE 下必须；弱证据=仅裸文件名（无 :line）→ 告警"证据为裸文件名（无行号/命令），
#      建议升级为 file:line 或命令输出"，不阻断；两者都不满足才 fail（默认告警）。
#      语义真伪不可机判，仍属文本审查（如实降级）。
#   ③ 判定依据（对抗审查②）：暂存区内容优先——git show :PITFALLS.md，失败回退工作区文件，输出注明判定依据，
#      使"改 PITFALLS 的提交"能通过自己的 pre-commit；临时文件用仓库内相对路径＋$$ 后缀
#      （P-017/ADR-012，防并行竞态），trap 清理。
# 背景：P-047——此前只 grep 三词即放行，字段可为空壳；台账与报告无机械对账（P-034 同族，ADR-034）。
cd "$(git rev-parse --show-toplevel)" || exit 1

enforce=${ENFORCE:-0}

f=PITFALLS.md
[ -f "$f" ] || { echo "[M4] 缺少 PITFALLS.md"; exit 1; }

# 判定依据：暂存区内容优先（ADR-034）；临时文件 $$ 后缀防并行竞态
content=".git/pitfall-check-$$.tmp"
: > "$content" 2>/dev/null || content="docs/.pitfall-check-$$.tmp"
trap 'rm -f "$content" 2>/dev/null || true' EXIT
if git show ":$f" > "$content" 2>/dev/null && [ -s "$content" ]; then
  basis="暂存区（index）内容"
else
  cat "$f" > "$content" 2>/dev/null || true
  basis="工作区文件（暂存区不可读）"
fi
[ -s "$content" ] || { echo "[M4] PITFALLS.md 内容为空，无法审计"; exit 1; }

ids=$(grep -oE '^#{2,3} P-[0-9]+' "$content" | grep -oE 'P-[0-9]+')
[ -z "$ids" ] && { echo "[M4] PITFALLS.md 未找到任何坑条目"; exit 1; }

fail=0; warn=0
for id in $ids; do
  body=$(awk -v id="$id" 'BEGIN{p=0} /^#{2,3} P-[0-9]+/{p=(index($2,id)==1)} p' "$content")
  echo "$body" | grep -q '根因' || { echo "[M4] $id 缺少「根因」字段"; fail=1; }
  echo "$body" | grep -q '状态' || { echo "[M4] $id 缺少「状态」字段"; fail=1; }
  echo "$body" | grep -q '证据' || { echo "[M4] $id 缺少「证据」字段（须可复现，不得编造）"; fail=1; }

  # ADR-034 ①：状态枚举双轨（祖传词仅存量条目豁免，告警不阻断）
  st=$(echo "$body" | grep '\*\*状态\*\*：' | head -n 1 | sed 's/^.*\*\*状态\*\*：//')
  if [ -n "$st" ]; then
    if echo "$st" | grep -qE '^(已落实|待落实|已升级|已闭环|已记录|部分落实)'; then :;
    elif echo "$st" | grep -qE '^(已修复|已落条款|机制已定|项目侧已追加更正)'; then
      echo "[M4] $id 状态为祖传状态词，新条目禁用，见 ADR-034：$st"
      warn=1
    else
      echo "[M4] $id 状态值不在枚举内：须以「已落实|待落实|已升级|已闭环|已记录|部分落实」之一开头，现值「$st」（ADR-034）"
      if [ "$enforce" = "1" ]; then fail=1; else warn=1; fi
    fi
  fi

  # ADR-034 ②：证据分级（强证据 ENFORCE 下必须；弱证据仅告警；两者皆无才 fail）
  ev=$(echo "$body" | grep '\*\*证据\*\*：' | head -n 1 | sed 's/^.*\*\*证据\*\*：//')
  if [ -n "$ev" ]; then
    ev_strong=0
    echo "$ev" | grep -qF '`' && ev_strong=1
    echo "$ev" | grep -qE '\.(sh|md|py|conf|ps1|txt|json):[0-9]+' && ev_strong=1
    echo "$ev" | grep -qF '无（待落实）' && ev_strong=1
    if [ "$ev_strong" -eq 0 ]; then
      if echo "$ev" | grep -qE '[A-Za-z0-9_./-]+\.(sh|md|py|conf|ps1|txt|json)'; then
        echo "[M4] $id 证据为裸文件名（无行号/命令），建议升级为 file:line 或命令输出"
        warn=1
      else
        echo "[M4] $id 证据无实质载体：须含反引号代码片段 / file:line 引用 / 无（待落实）之一（ADR-034）"
        if [ "$enforce" = "1" ]; then fail=1; else warn=1; fi
      fi
    fi
  fi
done

[ "$fail" -eq 1 ] && exit 1
[ "$warn" -eq 1 ] && { echo "[M4] 坑账本字段审计通过（含告警项，见上列；判定依据：$basis）"; exit 0; }
echo "[M4] 坑账本字段审计通过（$id 等共 $(echo "$ids" | wc -l | tr -d ' ') 条；判定依据：$basis）"
