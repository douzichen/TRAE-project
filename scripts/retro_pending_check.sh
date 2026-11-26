#!/bin/sh
# 复盘落库缺口检测（ADR-034 强制版；由 ADR-025 告警版升级）
# 背景：每日 00:00 复盘跑在空沙箱，只输出会话内报告；落库归主会话。
#       2026-11-21～23 连续三日未落库（P-034）；本脚本上线后恒退 0 告警，期间 14 笔提交
#       未覆盖台账仍判"通过"；2026-11-26 三日复盘审计确认 11-24 台账失真、编号复用
#       （P-034 第 2 次复发，P-019 同族），依 ADR-034 升级为强制（P-047）。
# 覆盖锚（ADR-034）：2026-11-26 起的 RETRO 行必须以（覆盖至 <sha7>）结尾（全角括号），
#       sha 须为 7~40 位十六进制、git cat-file -e 存在且为当前提交（HEAD）祖先（merge-base --is-ancestor）；
#       2026-11-26 之前的旧行豁免（祖传，不追溯）。
# 语义边界：覆盖锚＝复盘报告生成时审阅的仓库 HEAD；落库提交本身及其后的同日提交属次日复盘内容，不由本行锚覆盖（限明限制，见 ADR-034 推翻条件②）。
# 判定依据：暂存区内容优先——git show :docs/handoff/RETRO-LOG.md，失败回退工作区文件；
#       使"补 RETRO 行的提交"能通过自己的 pre-commit。
# 严格模式：ENFORCE=1 时存在任一缺口（①回看窗口内日期无 RETRO 行；
#       ②≥2026-11-26 的 RETRO 行缺覆盖锚或 sha 无效）→ 退出码 1；
#       默认（无 ENFORCE）恒退 0 仅告警（兼容 session_start_check.sh 现有调用）。
# 用法：sh scripts/retro_pending_check.sh [回看天数，默认 7]
set -u
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || { echo "[RETRO] 不在 git 仓库内"; exit 0; }

enforce=${ENFORCE:-0}

days=${1:-7}
case "$days" in ''|*[!0-9]*) days=7 ;; esac
[ "$days" -gt 30 ] && days=30

log=docs/handoff/RETRO-LOG.md
anchor_since=2026-11-26

# 判定依据：暂存区内容优先（ADR-034）；临时文件用仓库内相对路径（P-017/ADR-012）
content=".git/retro-log-check-$$.tmp"
: > "$content" 2>/dev/null || content="docs/.retro-log-check-$$.tmp"
trap 'rm -f "$content" 2>/dev/null || true' EXIT
if git show ":$log" > "$content" 2>/dev/null; then
  basis="暂存区（index）内容"
else
  cat "$log" > "$content" 2>/dev/null || true
  basis="工作区文件（暂存区不可读）"
fi
if [ ! -s "$content" ]; then
  echo "[RETRO] 缺少落库台账 $log：无法判定，按未落库处理"
fi

# 可移植性（ADR-012）：非 GNU date 不支持 -d 时不得静默判"通过"
if ! TZ=Asia/Shanghai date -d '-1 day' +%Y-%m-%d >/dev/null 2>&1; then
  echo "[RETRO] 本机 date 不支持 -d（非 GNU）：改为输出台账最近三条供人工核对"
  grep '^RETRO ' "$content" 2>/dev/null | tail -3
  if [ "$enforce" = "1" ]; then
    echo "[RETRO] ENFORCE=1：本机无法机械判定缺口，按 fail-closed 阻断（ADR-012：不得静默判通过）"
    exit 1
  fi
  exit 0
fi

# 防"长时间无提交 → 旧缺口滑出固定窗口"：以台账最新 RETRO 日期为起点补足回看天数（上限 30）
last=$(grep '^RETRO ' "$content" 2>/dev/null | awk '{print $2}' | sort | tail -1)
if [ -n "$last" ] && TZ=Asia/Shanghai date -d "$last" +%s >/dev/null 2>&1; then
  gd=$(( ( $(TZ=Asia/Shanghai date +%s) - $(TZ=Asia/Shanghai date -d "$last" +%s) ) / 86400 ))
  [ "$gd" -gt "$days" ] && days=$gd
  [ "$days" -gt 30 ] && days=30
fi
echo "[RETRO] 回看 $days 天（Asia/Shanghai），判定依据：$log（$basis）"
echo "[RETRO] 覆盖锚门槛（ADR-034）：$anchor_since 起的 RETRO 行须以（覆盖至 <sha7>）结尾，sha 经 git cat-file -e 校验；此前旧行豁免不追溯"

first=$(git log --reverse --format='%ad' --date=short 2>/dev/null | head -1)
missing=""
i=1
while [ "$i" -le "$days" ]; do
  d=$(TZ=Asia/Shanghai date -d "-$i day" +%Y-%m-%d 2>/dev/null)
  [ -z "$d" ] && break
  # 越过仓库首个提交日即停（建仓前不算缺口）
  if [ -n "$first" ] && [ "$d" \< "$first" ]; then break; fi
  grep -q "^RETRO $d" "$content" 2>/dev/null || missing="$missing $d"
  i=$((i + 1))
done

# 覆盖锚校验：≥2026-11-26 的 RETRO 行须以（覆盖至 <sha7~40>）结尾，sha 在本仓库存在且为当前提交（HEAD）祖先
anchor_bad=""
while IFS= read -r line; do
  case "$line" in RETRO\ *) : ;; *) continue ;; esac
  d=$(printf '%s\n' "$line" | awk '{print $2}')
  case "$d" in
    20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]) [ "$d" \< "$anchor_since" ] && continue ;;
    *) continue ;;
  esac
  sha=$(printf '%s\n' "$line" | sed -n 's/^.*（覆盖至 \([0-9a-fA-F]\{7,40\}\)）$/\1/p')
  if [ -z "$sha" ]; then
    anchor_bad="$anchor_bad
  - $d 行缺（覆盖至 <sha7>）锚：$line"
  elif ! git cat-file -e "$sha" 2>/dev/null; then
    anchor_bad="$anchor_bad
  - $d 行覆盖锚 sha 无效（git cat-file -e 失败）：$sha"
  elif ! git merge-base --is-ancestor "$sha" HEAD 2>/dev/null; then
    anchor_bad="$anchor_bad
  - $d 行覆盖锚 sha 不在当前提交历史中（merge-base --is-ancestor 失败）：$sha"
  fi
done < "$content"

rc=0
if [ -z "$missing" ] && [ -z "$anchor_bad" ]; then
  echo "[RETRO] 通过：近 $days 天均有 RETRO 落库记录，且 $anchor_since 起各 RETRO 行覆盖锚齐备"
else
  rc=1
  if [ -n "$missing" ]; then
    echo "[RETRO] 落库缺口（台账无记录）："
    for m in $missing; do echo "  - $m"; done
  fi
  if [ -n "$anchor_bad" ]; then
    echo "[RETRO] 覆盖锚缺失/无效（≥ $anchor_since 行，ADR-034）："
    printf '%s\n' "$anchor_bad"
  fi
  echo "[RETRO] 处置：按 schedules「执行后验证」当日补跑，补写 PITFALLS/CURRENT 后在 $log 追加带覆盖锚的 RETRO 行，再提交推送"
fi
echo "[RETRO] 说明：本检测只见台账，不见会话；无记录≠一定漏跑，但必须补齐记录才能消除缺口"

if [ "$enforce" = "1" ] && [ "$rc" -eq 1 ]; then
  echo "[RETRO] ENFORCE=1：存在缺口，阻断提交（ADR-034；此前恒退 0 告警期间 14 笔提交未覆盖仍判通过，P-034/P-047）"
  exit 1
fi
[ "$rc" -eq 1 ] && echo "[RETRO] 告警模式（未设 ENFORCE）：恒退 0，仅提示不阻断"
exit 0
