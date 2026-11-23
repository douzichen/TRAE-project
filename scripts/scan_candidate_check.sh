#!/bin/sh
# 外部候选清单字段校验（ADR-023 M1 的机械执行；ADR-025）
# 背景：11-21 调查渠道表零 URL、含无出处断言，靠人眼判"已过闸"（P-035）。
# 用法：sh scripts/scan_candidate_check.sh <候选清单文件> [--strict]
# 模板（S-007 规定，机械识别）：每条候选以「- 候选：」或「### 候选：」开头，块内须含：
#   URL（http(s)://）、日期（YYYY-MM-DD）、一手/二手、T1、T2、T3
# 零候选：文件须含「本期零候选」，且不得同时出现候选块
# 退出码：默认告警模式（发现问题仍 exit 0，打印 [WARN]）；--strict 时发现问题 exit 1
# 依据 rules/10：未完成真实回归与第二平台实跑前，只能保持告警模式
set -u
f=""
strict=0
for a in "$@"; do
  case "$a" in
    --strict) strict=1 ;;
    -*) echo "[SCAN] 未知选项：$a"; exit 2 ;;
    *) f=$a ;;
  esac
done
[ -n "$f" ] || { echo "用法：sh scripts/scan_candidate_check.sh [--strict] <候选清单文件>"; exit 2; }
[ -f "$f" ] || { echo "[SCAN] 文件不存在：$f"; exit 2; }

mkdir -p .local/tmp
blocks=".local/tmp/scan_blocks.$$"
warns=".local/tmp/scan_warns.$$"

awk '
  /^[[:space:]]*([-*]|###)[[:space:]]*候选/ {
    if (blk != "") print blk "\n@@END@@"
    blk=$0; next
  }
  {
    if (blk != "") {
      if ($0 ~ /^[[:space:]]*$/) { print blk "\n@@END@@"; blk="" }
      else blk=blk "\n" $0
    }
  }
  END { if (blk != "") print blk "\n@@END@@" }
' "$f" > "$blocks"

awk '
  /@@END@@/ {
    if (blk == "") next
    miss=""
    if (blk !~ /https?:\/\//) miss=miss" URL"
    if (blk !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) miss=miss" 日期"
    if (blk !~ /一手/ && blk !~ /二手/) miss=miss" 一手/二手"
    if (blk !~ /T1/) miss=miss" T1"
    if (blk !~ /T2/) miss=miss" T2"
    if (blk !~ /T3/) miss=miss" T3"
    if (miss != "") printf "[WARN] 候选缺字段：%s｜首行：%s\n", miss, first
    blk=""; first=""
    next
  }
  { if (blk == "") first=$0; blk = blk "\n" $0 }
' "$blocks" > "$warns"

n=$(grep -c '@@END@@' "$blocks" 2>/dev/null); n=${n:-0}
nwarn=$(grep -c '^\[WARN\]' "$warns" 2>/dev/null); nwarn=${nwarn:-0}
zero=0
grep -q '本期零候选' "$f" 2>/dev/null && zero=1

if [ "$nwarn" -gt 0 ]; then cat "$warns"; fi

if [ "$n" -eq 0 ]; then
  if [ "$zero" -eq 1 ]; then
    echo "[SCAN] OK：明示「本期零候选」（须在图外说明检索范围与无候选理由）"
    rm -f "$blocks" "$warns"
    exit 0
  fi
  echo "[WARN] 未识别到候选块：候选须以「- 候选：」开头（S-007 模板），或明示「本期零候选」"
  nwarn=$((nwarn + 1))
fi

if [ "$zero" -eq 1 ] && [ "$n" -gt 0 ]; then
  echo "[WARN] 自相矛盾：声明「本期零候选」却又列出 $n 个候选"
  nwarn=$((nwarn + 1))
fi

rm -f "$blocks" "$warns"

if [ "$nwarn" -eq 0 ]; then
  echo "[SCAN] 通过：$n 个候选字段齐全"
  exit 0
fi

if [ "$strict" -eq 1 ]; then
  echo "[SCAN] strict 失败：$nwarn 处问题（M1：缺任一字段即清单无效）"
  exit 1
fi
echo "[SCAN] 告警模式：发现 $nwarn 处问题，修正后再交；2026-12-06 首扫零误报后转 --strict"
exit 0
