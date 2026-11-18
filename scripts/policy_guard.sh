#!/bin/sh
# 涉税/政策类结论的依据核验（pre-commit）
# 规则来源：rules/05「需求定义审查」、rules/15「D-7 依据核验」、ADR-010
# 上线方式（遵守 P-015）：先**告警模式**在真实仓库跑，误报清零后再转阻断；当前为告警模式（恒返回 0）。
# 判定口径（机械，不靠自觉）：文件命中下列任一即为"业务/政策类"，才做依据核验——
#   ① 路径位于 docs/policy/ 或 docs/business/
#   ② front-matter 含 scope: business
# 关键词只用于在业务类文件内**提示**缺失的依据，不用于把任意文档判成业务类（避免规则文档自身误报）。
set -e
cd "$(git rev-parse --show-toplevel)"

files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.md$' || true)
[ -z "$files" ] && { echo "[D-7] 无暂存 Markdown 改动，依据核验跳过"; exit 0; }

checked=0
warn=0
for f in $files; do
  [ -f "$f" ] || continue
  is_business=0
  case "$f" in
    docs/policy/*|docs/business/*) is_business=1 ;;
  esac
  if [ "$is_business" -eq 0 ] && head -20 "$f" | grep -qE '^scope:[[:space:]]*business'; then
    is_business=1
  fi
  [ "$is_business" -eq 1 ] || continue
  checked=$((checked + 1))

  # 依据三要素：政策名称（含"政策""公告""通知"或"财政部/税务总局"）、条款号（第..条 或 财税〔）、核实状态
  if ! grep -qE '政策|公告|通知|财政部|税务总局' "$f"; then
    echo "[D-7] 告警：$f 属业务/政策类，但未见政策名称"
    warn=$((warn + 1))
  fi
  if ! grep -qE '第[一二三四五六七八九十百零0-9]+条|财税〔|国家税务总局公告' "$f"; then
    echo "[D-7] 告警：$f 属业务/政策类，但未见具体条款号"
    warn=$((warn + 1))
  fi
  if ! grep -qE '已核实|尚未核实|不作结论' "$f"; then
    echo "[D-7] 告警：$f 未标注核实状态（应写明 已核实 / 尚未核实，未核实不得下结论）"
    warn=$((warn + 1))
  fi
done

if [ "$checked" -eq 0 ]; then
  echo "[D-7] 本次无业务/政策类文件改动，依据核验不适用"
elif [ "$warn" -eq 0 ]; then
  echo "[D-7] 依据核验通过（业务/政策类文件 $checked 个，依据与核实状态齐全）"
else
  echo "[D-7] 告警模式：$warn 处待补（按 P-015，误报清零后再转阻断；人工须在交付的 D-7 栏给出依据或改标'尚未核实'）"
fi
exit 0
