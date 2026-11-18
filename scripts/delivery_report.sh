#!/bin/sh
# 交付反馈清单（DoD）机械代理：每次 commit 时生成可直接粘贴的交付报告草稿
# 覆盖 AGENTS.md「任务完成的交付反馈清单」的 D-1 / D-2 / D-3 / D-5；D-4 / D-6 需人工补写
# 升级来源：P-002 第三次复发（改用“如需我再贴一遍”推迟交付），按“复发即升级”由提醒升级为生成草稿
cd "$(git rev-parse --show-toplevel)" || exit 0

changed=$( { git diff --cached --name-only; git diff --name-only; } | grep -v '^$' | sort -u )

echo "===== 交付反馈清单（逐项对照 AGENTS.md，缺项=任务未完成）====="

echo ""
echo "## D-1 规则文件（AGENTS.md / rules/*.md）新增段 / 全文"
rulefiles=$(printf '%s\n' "$changed" | grep -E '^(AGENTS\.md|rules/[0-9]{2}-.*\.md)$' || true)
if [ -n "$rulefiles" ]; then
  echo "### 一、本次新增/修改的段落"
  for f in $rulefiles; do
    echo "--- $f ---"
    git diff HEAD -- "$f" | grep -E '^\+[^+]' | sed 's/^+//'
  done
  echo ""
  echo "### 二、改动后的全文"
  for f in $rulefiles; do
    echo "=== $f ==="
    cat "$f"
    echo ""
  done
else
  echo "规则库未改动 → 回复中须写明：规则库未改动，无全文义务"
fi

echo ""
echo "## D-2 本轮改动文件"
printf '%s\n' "$changed" | sed 's/^/- /'

echo ""
echo "## D-3 对账（逐份说明改动或未改的理由）"
for f in AGENTS.md AGENTS-GLOBAL.md README.md PITFALLS.md skills/INDEX.md workflows/INDEX.md; do
  if printf '%s\n' "$changed" | grep -qx "$f"; then
    echo "- $f：已改动（须写明改了哪一节）"
  else
    echo "- $f：未改动（须写明为何无需改）"
  fi
done

echo ""
echo "## D-5 验证与同步状态"
ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')
echo "- 当前领先远端 $ahead 个提交（本次提交会使该值 +1）；推送后必须核对 ahead 0"
echo "- 必须粘贴 md_check / pre-push 的实际输出，不得只写“已通过”"

echo ""
echo "## D-4 记忆收录说明（人工补写：写入哪些、不写哪些、理由、落点章节）"
echo "## D-6 沉淀与待确认（人工补写：沉淀了什么或为何无需沉淀；待确认事项状态）"
