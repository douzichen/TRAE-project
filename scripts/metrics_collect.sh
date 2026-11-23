#!/bin/sh
# 度量采集（ADR-021 决策①）：把提交事件记成可数的事件流
#
# 默认模式（仍由 .githooks/pre-commit 末尾调用）：
#   只向 .git/metrics.log 追加一行 TSV（日期<TAB>短sha<TAB>提交首行），**不修改工作区任何文件**。
#   因此提交后工作区保持干净，不再出现"每次提交都把 docs/METRICS.md 弄脏"的问题。
#   非阻断：任何失败只打警告，恒 exit 0。
#
# --flush（手动执行）：
#   把 .git/metrics.log 中尚未入账的事件（按短 sha 去重）并入 docs/METRICS.md 事件流水末尾，
#   行格式 `| 日期 | 提交信息首行截 40 字 | 11 门禁 | - |`；成功后清空 .git/metrics.log。
#   幂等：重复执行不会重复追加（docs 中已有同样一行、或 .git/metrics.flushed 已记该 sha 即跳过）。
#
# 滞后一行语义（P-023）：pre-commit 阶段 HEAD 仍是上一提交，故记录的是上一提交事件；
#   本次提交的事件由下一次提交的钩子补记，最后一次提交用 `sh scripts/metrics_collect.sh` 手动补记。
#
# 可移植：仓库内相对路径，禁 mktemp / 绝对路径 rm / sed -i / readlink -f（P-017、ADR-012）。

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
gitdir=$(git rev-parse --git-dir 2>/dev/null) || gitdir=".git"
log="$gitdir/metrics.log"
flushed="$gitdir/metrics.flushed"
docs="docs/METRICS.md"

usage() {
  cat <<'EOF'
用法：
  sh scripts/metrics_collect.sh          # 追加 HEAD 提交事件到 .git/metrics.log（非阻断，不改工作区）
  sh scripts/metrics_collect.sh --flush  # 把 .git/metrics.log 并入 docs/METRICS.md（幂等），随后清空日志
EOF
}

mode=append
for a in "$@"; do
  case "$a" in
    --flush) mode=flush ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[METRICS] 未知参数：$a" >&2; usage >&2; exit 2 ;;
  esac
done

TAB=$(printf '\t')

do_append() {
  sha=$(git log -1 --format='%h' 2>/dev/null | head -n 1)
  if [ -z "$sha" ]; then
    echo "[METRICS] 警告：取不到 HEAD 短 sha，本次不记录（非阻断）" >&2
    return 0
  fi
  day=$(git log -1 --format='%ad' --date=short 2>/dev/null | head -n 1)
  [ -n "$day" ] || day=$(date +%Y-%m-%d 2>/dev/null) || day="（未知日期）"
  msg=$(git log -1 --format='%s' 2>/dev/null | head -n 1 | tr '\t' ' ')
  [ -n "$msg" ] || msg="（未取得提交信息）"

  # 钩子重跑/重复调用时同一 sha 不再重复入库
  if [ -f "$log" ] && awk -F"$TAB" -v s="$sha" '$2 == s { found = 1 } END { exit !found }' "$log"; then
    echo "[METRICS] $sha 已在 $log 中，跳过重复记录（非阻断）" >&2
    return 0
  fi
  # 已通过 --flush 入账过的 sha 不再重复写入日志
  if [ -f "$flushed" ] && grep -qxF -- "$sha" "$flushed" 2>/dev/null; then
    echo "[METRICS] $sha 已入账 docs/METRICS.md，跳过（非阻断）" >&2
    return 0
  fi

  if printf '%s\t%s\t%s\n' "$day" "$sha" "$msg" >> "$log"; then
    echo "[METRICS] 已记录 $sha 到 $log（非阻断度量；入账请执行 --flush）" >&2
  else
    echo "[METRICS] 警告：写 $log 失败，本次不记录（非阻断）" >&2
  fi
  return 0
}

do_flush() {
  if [ ! -f "$docs" ]; then
    echo "[METRICS] 缺少 $docs，无法入账" >&2
    return 1
  fi
  if [ ! -f "$log" ] || [ ! -s "$log" ]; then
    echo "[METRICS] 无待入账事件（$log 为空或不存在）"
    return 0
  fi

  uniq="$gitdir/metrics-flush.uniq"
  newlines="$gitdir/metrics-flush.new"
  shas="$gitdir/metrics-flush.shas"
  : > "$uniq" || return 1
  : > "$newlines" || return 1
  : > "$shas" || return 1
  [ -f "$flushed" ] || : > "$flushed"

  # 按短 sha 去重；要求至少三列
  awk -F"$TAB" 'NF >= 3 && !seen[$2]++ { print }' "$log" > "$uniq" || {
    echo "[METRICS] 读取 $log 失败" >&2; return 1; }

  added=0
  skipped=0
  while IFS="$TAB" read -r day sha msg; do
    [ -n "$sha" ] || continue
    [ -n "$day" ] || day=$(date +%Y-%m-%d 2>/dev/null) || day="（未知日期）"
    # 已入账过（同一 sha）或文档中已有完全一致的行 → 跳过，保证幂等
    if grep -qxF -- "$sha" "$flushed" 2>/dev/null; then
      skipped=$((skipped + 1)); continue
    fi
    short=$(printf '%s' "$msg" | awk '{ gsub(/\|/, "／"); gsub(/`/, "-"); print substr($0, 1, 40); exit }')
    line="| $day | $short | 11 门禁 | - |"
    if grep -qF -- "$line" "$docs" 2>/dev/null; then
      printf '%s\n' "$sha" >> "$shas"
      skipped=$((skipped + 1)); continue
    fi
    printf '%s\n' "$line" >> "$newlines" || { echo "[METRICS] 写临时文件失败" >&2; return 1; }
    printf '%s\n' "$sha" >> "$shas"
    added=$((added + 1))
  done < "$uniq"

  if [ "$added" -gt 0 ]; then
    # 确保表格末尾换行后再追加，避免与上一行粘连
    [ -n "$(tail -c 1 "$docs" 2>/dev/null)" ] && printf '\n' >> "$docs"
    if ! cat "$newlines" >> "$docs"; then
      echo "[METRICS] 追加 $docs 失败，$log 保留待重试" >&2
      return 1
    fi
    echo "[METRICS] 已入账 $added 行到 $docs（跳过已入账 $skipped 行）"
  else
    echo "[METRICS] 无新事件可入账（跳过已入账 $skipped 行）"
  fi

  # 文档写入成功后，才把本次处理过的 sha 记为已入账
  cat "$shas" >> "$flushed" 2>/dev/null || true

  # 入账成功后清空日志；失败路径不清空，便于重试
  : > "$log" || { echo "[METRICS] 警告：清空 $log 失败" >&2; }
  rm -f "$uniq" "$newlines" "$shas" 2>/dev/null || true
  return 0
}

case "$mode" in
  append) do_append; exit 0 ;;
  flush) do_flush; exit $? ;;
esac
