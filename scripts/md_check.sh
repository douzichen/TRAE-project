#!/bin/sh
# P-004 markdown 完整性校验（pre-commit 卡点）：INDEX 登记、坑编号连续、标题去重
set -e
cd "$(git rev-parse --show-toplevel)"
fail=0

# 1) skills：每个 S-*.md 必须登记在 skills/INDEX.md
for f in skills/S-*.md; do
  [ -e "$f" ] || continue
  grep -q "$(basename "$f")" skills/INDEX.md || { echo "[P-004] 未登记: $f"; fail=1; }
done

# 2) workflows：每个 W-*.md 必须登记在 workflows/INDEX.md
for f in workflows/W-*.md; do
  [ -e "$f" ] || continue
  grep -q "$(basename "$f")" workflows/INDEX.md || { echo "[P-004] 未登记: $f"; fail=1; }
done

# 3) PITFALLS.md 编号从 P-001 起连续递增
prev=0
for n in $(grep -oE '^### P-[0-9]{3}' PITFALLS.md | grep -oE '[0-9]{3}'); do
  if [ "$n" -ne $((prev + 1)) ]; then
    echo "[P-004] 坑编号不连续：期望 P-$(printf '%03d' $((prev + 1)))，实际 P-$n"; fail=1
  fi
  prev=$n
done

# 4) AGENTS.md 章节标题不允许重复
dups=$(grep -E '^## ' AGENTS.md | sort | uniq -d)
if [ -n "$dups" ]; then
  echo "[P-004] AGENTS.md 存在重复章节：$dups"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "[P-004] md 完整性校验通过"
else
  exit 1
fi
