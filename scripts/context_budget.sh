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

[ "$fail" -eq 1 ] && exit 1
echo "[P-010] 上下文预算校验通过（必读集 ${core}/${CORE_MAX}｜总纲 ${idx}/${INDEX_MAX}｜单册上限 ${FILE_MAX}）"
