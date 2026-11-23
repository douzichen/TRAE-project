#!/bin/sh
# [P-010] 上下文预算校验：阈值唯一来源为 scripts/budget.conf（[M3] 强制，不得硬编码）
cd "$(git rev-parse --show-toplevel)" || exit 1
. scripts/budget.conf || { echo "[P-010] 缺少 scripts/budget.conf"; exit 1; }

fail=0
lines() { wc -l < "$1" | tr -d ' '; }

core=0
for f in AGENTS.md rules/00-core.md rules/01-user-profile.md rules/02-intake-and-dod.md; do
  [ -f "$f" ] || { echo "[P-010] 缺少必需文件：$f"; fail=1; continue; }
  n=$(lines "$f"); core=$((core + n))
  echo "[P-010] $f = ${n} 行"
done

echo "[P-010] 最小必读集合计 ${core} 行（上限 ${CORE_MAX}）"
[ "$core" -gt "$CORE_MAX" ] && {
  echo "[P-010] 超限：最小必读集 ${core} > ${CORE_MAX}，必须把细则移出常驻集（见 rules/12）"; fail=1; }

idx=$(lines AGENTS.md 2>/dev/null || echo 0)
[ "$idx" -gt "$INDEX_MAX" ] && {
  echo "[P-010] 超限：总纲 AGENTS.md ${idx} 行 > ${INDEX_MAX}，必须精简"; fail=1; }

for f in rules/*.md; do
  [ -f "$f" ] || continue
  n=$(lines "$f")
  [ "$n" -gt "$FILE_MAX" ] && {
    echo "[P-010] 超限：$f ${n} 行 > ${FILE_MAX}，必须再拆分"; fail=1; }
done

# [ADR-024 可推翻条件 4 / ADR-026] docs/AGENT-ADAPTER.md 自设上限（阈值取自 scripts/budget.conf）：先告警、不阻断（rules/10）
if [ -f docs/AGENT-ADAPTER.md ]; then
  n=$(lines docs/AGENT-ADAPTER.md)
  if [ "$n" -gt "$ADAPTER_MAX" ]; then
    echo "[WARN] docs/AGENT-ADAPTER.md ${n} 行 > 自设上限 ${ADAPTER_MAX} 行（ADR-024）：须压缩或外移增补节"
  elif [ "$n" -ge $((ADAPTER_MAX - ADAPTER_HEADROOM)) ]; then
    echo "[WARN] docs/AGENT-ADAPTER.md ${n} 行，距自设上限 ${ADAPTER_MAX} 行仅 $((ADAPTER_MAX - n)) 行余量（ADR-024）"
  fi
fi

[ "$fail" -eq 1 ] && exit 1
echo "[P-010] 上下文预算校验通过（必读集 ${core}/${CORE_MAX}｜总纲 ${idx}/${INDEX_MAX}｜单册上限 ${FILE_MAX}）"
