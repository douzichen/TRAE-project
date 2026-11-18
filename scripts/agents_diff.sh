#!/bin/sh
# P-002 机械代理：AGENTS.md 有改动时自动生成"新增段落 diff + 全文"，供直接粘贴进回复
# 说明：聊天输出行为无法由 hook 全自动拦截，本脚本自动化其中机械部分（P-002 状态=半自动）
cd "$(git rev-parse --show-toplevel)"
if git diff --quiet HEAD -- AGENTS.md 2>/dev/null; then
  echo "[P-002] AGENTS.md 无改动，无需输出全文"
  exit 0
fi
echo "## 一、本次新增/修改的段落"
git diff HEAD -- AGENTS.md | grep -E '^\+[^+]' | sed 's/^+//'
echo ""
echo "## 二、改动后的全文"
cat AGENTS.md
