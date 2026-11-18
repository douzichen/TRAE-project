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

# 5) 技能同步门禁：skills/workflows 不允许存在未提交的散改（改了不提交=未同步=任务未完成）
if ! git diff --quiet -- skills workflows; then
  echo "[SYNC] skills/workflows 存在未提交改动，视为未同步，禁止提交一部分留一部分"; fail=1
fi

# 6) 同步核对（非阻断提醒）：领先远端即"未推送=同步未完成"
ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
if [ "$ahead" -gt 0 ]; then
  echo "[SYNC] 分支领先远端 $ahead 个提交，未推送=同步未完成（推送后须核对 ahead 0）" >&2
fi

if [ "$fail" -eq 0 ]; then
  echo "[P-004] md 完整性校验通过"
else
  exit 1
fi
