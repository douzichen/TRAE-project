#!/bin/sh
# 复盘落库缺口检测（只读、只告警；ADR-025）
# 背景：每日 00:00 复盘跑在空沙箱，只输出会话内报告；落库归主会话。
#       2026-11-21～23 连续三日未落库（P-034，P-019 第 2 次复发）。
# 判定（定义式，非代理推断）：docs/handoff/RETRO-LOG.md 中无该日期的 `RETRO <YYYY-MM-DD>` 行即缺口。
#   落库复盘时须追加一行：RETRO 2026-11-23 P-034~P-037（示例）
# 用法：sh scripts/retro_pending_check.sh [回看天数，默认 7]
# 退出码：恒为 0（告警模式，参照 P-015）
set -u
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || { echo "[RETRO] 不在 git 仓库内"; exit 0; }

days=${1:-7}
case "$days" in ''|*[!0-9]*) days=7 ;; esac
[ "$days" -gt 30 ] && days=30

log=docs/handoff/RETRO-LOG.md
if [ ! -f "$log" ]; then
  echo "[RETRO] 缺少落库台账 $log：无法判定，按未落库处理"
fi

# 可移植性（ADR-012）：非 GNU date 不支持 -d 时不得静默判"通过"
if ! TZ=Asia/Shanghai date -d '-1 day' +%Y-%m-%d >/dev/null 2>&1; then
  echo "[RETRO] 本机 date 不支持 -d（非 GNU）：改为输出台账最近三条供人工核对"
  [ -f "$log" ] && grep '^RETRO ' "$log" | tail -3
  exit 0
fi

echo "[RETRO] 回看 $days 天（Asia/Shanghai），判定依据：$log 的 RETRO 行"
first=$(git log --reverse --format='%ad' --date=short 2>/dev/null | head -1)
missing=""
i=1
while [ "$i" -le "$days" ]; do
  d=$(TZ=Asia/Shanghai date -d "-$i day" +%Y-%m-%d 2>/dev/null)
  [ -z "$d" ] && break
  # 越过仓库首个提交日即停（建仓前不算缺口）
  if [ -n "$first" ] && [ "$d" \< "$first" ]; then break; fi
  if [ -f "$log" ] && grep -q "^RETRO $d" "$log" 2>/dev/null; then :; else missing="$missing $d"; fi
  i=$((i + 1))
done

if [ -z "$missing" ]; then
  echo "[RETRO] 通过：近 $days 天均有 RETRO 落库记录"
else
  echo "[RETRO] 落库缺口（台账无记录）："
  for m in $missing; do echo "  - $m"; done
  echo "[RETRO] 处置：按 schedules「执行后验证」当日补跑，补写 PITFALLS/CURRENT 后在 $log 追加 RETRO 行，再提交推送"
fi
echo "[RETRO] 说明：本检测只见台账，不见会话；无记录≠一定漏跑，但必须补齐记录才能消除告警"
exit 0
