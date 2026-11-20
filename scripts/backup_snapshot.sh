#!/bin/sh
# 灾备兜底快照（P-022 / ADR-021 决策④）
# 用途：① 推送链路不可用或重大交付后的本地灾备兜底；② 恢复演练输入（演练步骤：clone GitHub → 核对 HEAD 与快照一致 → 跑 scripts/session_start_check.sh → 报告结果）。
# 行为：在仓库父目录生成全量快照 TRAE-project-backup-<日期>-<short-HEAD>.tar.gz（含 .git 与未提交改动的工作区）。
# 退出码：0=成功（打印快照路径与字节数）；1=失败。
# 可移植性：仓库内相对路径操作；禁 mktemp / sed -i / readlink -f / 绝对路径 rm（P-017、ADR-012）。
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "[BACKUP] 失败：当前目录不在 git 仓库内"; exit 1; }

root=$(pwd)
repo_dir=$(basename "$root")
tpar=$(dirname "$root")
parent="$tpar"
case "$parent" in /) parent="" ;; esac   # 父目录为根时避免出现 // 双斜杠
head_short=$(git rev-parse --short HEAD 2>/dev/null) || head_short="noHEAD"
day=$(date +%Y-%m-%d 2>/dev/null) || day="unknown"
target="$parent/TRAE-project-backup-$day-$head_short.tar.gz"

# 快照写父目录（仓库外，不入库）；同名旧快照直接被 tar 覆盖，不预删
if tar -czf "$target" -C "$tpar" "$repo_dir"; then
  bytes=$(wc -c < "$target" | tr -d ' ')
  echo "[BACKUP] 快照已生成：$target（$bytes 字节，含 .git）"
  echo "[BACKUP] 提醒：快照在仓库父目录，不入库；恢复演练按本脚本头注释步骤执行"
  exit 0
else
  echo "[BACKUP] 失败：快照生成未完成（检查父目录写权限与磁盘空间），可删除残缺文件后重试：$target"
  exit 1
fi
