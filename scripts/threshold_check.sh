#!/bin/sh
# [M3] 阈值单一来源校验
# 目的：预算阈值只在 scripts/budget.conf 定义一次；rules/12 的表格必须与之一致，
#       防止"文档写一套、脚本跑另一套"（P-012 根因）。
cd "$(git rev-parse --show-toplevel)" || exit 1
. scripts/budget.conf || { echo "[M3] 缺少 scripts/budget.conf"; exit 1; }

fail=0

# 只取表格行（以 | 开头）中的 "NNN 行"，避免把正文里的 "8~12 行" 之类当阈值
declared=$(grep -E '^\|' rules/12-context-budget.md 2>/dev/null \
  | grep -oE '[0-9]{2,3} 行' | grep -oE '[0-9]+' | sort -un | tr '\n' ' ')
expected=$(printf '%s\n' "$CORE_MAX" "$FILE_MAX" "$INDEX_MAX" | sort -un | tr '\n' ' ')

if [ "$declared" != "$expected" ]; then
  echo "[M3] rules/12 表格中的阈值与 scripts/budget.conf 不一致"
  echo "     规则文本：${declared:-（未找到）}"
  echo "     配置文件：$expected"
  fail=1
fi

if grep -qE '(total|core|idx|n).{0,14}-gt [0-9]{2,3}' scripts/context_budget.sh 2>/dev/null; then
  echo "[M3] scripts/context_budget.sh 存在硬编码阈值，必须改为引用 scripts/budget.conf"
  fail=1
fi

[ "$fail" -eq 1 ] && exit 1
echo "[M3] 阈值单一来源校验通过（必读集 ${CORE_MAX} / 单册 ${FILE_MAX} / 总纲 ${INDEX_MAX}）"
