#!/bin/sh
# 上下文预算校验：防止规则库膨胀到任何 Agent 都读不完（见 rules/12-context-budget.md）
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0

count() { wc -l < "$1" 2>/dev/null | tr -d ' '; }

core_set="AGENTS.md rules/00-core.md rules/01-user-profile.md rules/02-intake-and-dod.md"
total=0
for f in $core_set; do
  [ -f "$f" ] || { echo "[P-010] 缺失必需文件：$f"; fail=1; continue; }
  n=$(count "$f"); total=$((total + n))
done

echo "[P-010] 最小必读集合计 ${total} 行（上限 160）"
[ "$total" -gt 160 ] && { echo "[P-010] 超限：最小必读集 ${total} 行 > 160，必须把细则移出常驻集（见 rules/12）"; fail=1; }

n=$(count AGENTS.md)
if [ "$n" -gt 100 ]; then echo "[P-010] 总纲 AGENTS.md 为 ${n} 行 > 100，必须精简（见 rules/12）"; fail=1; fi
echo "[P-010] 总纲 ${n} 行（上限 100）"

for f in rules/[0-9][0-9]-*.md; do
  [ -f "$f" ] || continue
  n=$(count "$f")
  if [ "$n" -gt 120 ]; then echo "[P-010] 超限：$f 为 ${n} 行 > 120，必须再拆分"; fail=1; fi
done

[ "$fail" -eq 0 ] && echo "[P-010] 上下文预算校验通过"
exit $fail
