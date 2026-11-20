#!/bin/sh
# 度量采集（ADR-021 决策①）：每次 commit 向 docs/METRICS.md 追加一行提交事件
# 滞后一行语义（P-023）：提交 N 的钩子记录提交 N-1 的事件，读 HEAD 而非 COMMIT_EDITMSG。
# 挂载：.githooks/pre-commit 末尾（delivery_report.sh 之后），非阻断度量，不计入门禁序号。
# 非阻断约束：本脚本身处 pre-commit 中，任何失败都不得阻断提交——结尾恒 exit 0，追加失败仅打警告。
# 防递归：只做 >> 追加，不 git add、不改门禁逻辑，不会触发新一轮钩子。
# 可移植：仓库内相对路径，禁 mktemp / 绝对路径 rm / sed -i / readlink -f（P-017、ADR-012）。
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

f="docs/METRICS.md"
if [ ! -f "$f" ]; then
  echo "[METRICS] 警告：缺 $f，跳过度量采集（非阻断）" >&2
  exit 0
fi

# 取上一提交（HEAD）主题首行——pre-commit 阶段本次消息尚未写入 .git/COMMIT_EDITMSG，
# 实测读到的是上一提交遗留的旧消息（P-023），故禁止读它推断本次消息。
msg=$(git log -1 --format=%s 2>/dev/null | head -n 1)
[ -n "$msg" ] || msg="（未取得提交信息）"

# 表格安全化：竖线会破坏行格式，反引号会被裸路径校验扫描，统一替换；截 40 字
short=$(printf '%s' "$msg" | awk '{ gsub(/\|/, "／"); gsub(/`/, "-"); print substr($0, 1, 40); exit }')
day=$(date +%Y-%m-%d 2>/dev/null) || day="（未知日期）"

if printf '%s\n' "| $day | $short | 11 门禁 | - |" >> "$f"; then
  echo "[METRICS] 已记录提交事件到 $f（非阻断度量）" >&2
else
  echo "[METRICS] 警告：追加度量行失败，本次不记录（非阻断，不影响提交）" >&2
fi
exit 0
