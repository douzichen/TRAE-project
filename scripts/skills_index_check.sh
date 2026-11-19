#!/bin/sh
# 技能元数据校验（S-001~S-004 十栏 + INDEX 触发词列）
#
# 用途：
#   1) 每个 skills/S-*.md 必须含十栏且内容非空：
#      名称 / 编号 / 适用场景 / 前置输入 / 步骤 / 判定标准（验收）/
#      触发词 / 不适用 / 完成判据 / 单一来源。
#      字段值去掉空白后为空，或含「待填」「TODO」「<」等占位字样，均判为问题。
#   2) 每个 S-*.md 必须登记在 skills/INDEX.md；只认以「| S-00x」开头的表格行
#      （锚定 ^| *S-00x），按 | 分列后「触发词」列必须存在且去除空白后非空。
#      不使用全局首个匹配，避免误认正文中的编号引用。
#   3) INDEX 表头必须有「触发词」列。
#
# 两种模式（默认不阻断）：
#   告警模式（默认）：逐条打印 [SKILL-META] <文件>：<问题>，最后打印
#     [SKILL-META] 告警模式：N 项问题（本次不阻断），exit 0；
#   阻断模式：SKILL_META_ENFORCE=1 时打印同样的问题清单，最后打印
#     [SKILL-META] 阻断模式：N 项问题（SKILL_META_ENFORCE=1），exit 1。
#
# 平台：本脚本仅在 Linux 验证（P-017/ADR-012）；只用仓库内相对路径，不写临时文件。
cd "$(git rev-parse --show-toplevel)" || exit 1

INDEX="skills/INDEX.md"
n=0

report() { # $1=文件或对象  $2=问题描述
  printf '[SKILL-META] %s：%s\n' "$1" "$2"
  n=$((n + 1))
}

field() { # $1=文件  $2=字段名（不含 ** 号），输出该栏内容（首行及缩进续行）
  awk -v lab="**$2**" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    BEGIN { pre = "- " lab; L = length(pre) }
    substr($0, 1, L) == pre {
      rest = substr($0, L + 1)
      sub(/^[[:space:]]*[：:]/, "", rest)
      rest = trim(rest)
      if (rest != "") { print rest; exit }
      found = 1
      next
    }
    found && /^- \*\*/ { exit }
    found {
      line = trim($0)
      if (line != "") out = (out == "" ? line : out " " line)
    }
    END { if (found && out != "") print out }
  ' "$1" 2>/dev/null
}

[ -f "$INDEX" ] || report "$INDEX" "索引文件缺失"

col=""
if [ -f "$INDEX" ]; then
  col=$(awk -F'|' 'index($0, "触发词") > 0 && /^[[:space:]]*\|/ {
    for (i = 1; i <= NF; i++) if (index($i, "触发词") > 0) { print i; exit }
  }' "$INDEX")
  [ -n "$col" ] || report "$INDEX" "表头缺少「触发词」列"
fi

for f in skills/S-*.md; do
  [ -e "$f" ] || continue
  base=${f##*/}
  id=$(printf '%s' "$base" | sed -n 's/^\(S-[0-9][0-9][0-9]\).*/\1/p')

  # 1) 十栏存在且内容非空，拒绝占位字样
  for key in 名称 编号 适用场景 前置输入 步骤 判定标准（验收） 触发词 不适用 完成判据 单一来源; do
    if ! grep -qF -- "- **${key}**" "$f" 2>/dev/null; then
      report "$f" "缺少「${key}」字段"
      continue
    fi
    val=$(field "$f" "$key")
    if [ -z "$val" ]; then
      report "$f" "「${key}」内容为空"
    elif printf '%s' "$val" | tr -d '[:space:]' | grep -qE '^(待填|TODO|todo|TBD|tbd|\.{3}|…)$|^<'; then
      report "$f" "「${key}」仅含占位字样"
    fi
  done

  # 2) 已登记在 INDEX：只认锚定的表格行 | S-00x
  [ -f "$INDEX" ] || continue
  row=""
  if [ -n "$id" ]; then
    row=$(grep -E "^[[:space:]]*[|][[:space:]]*${id}[[:space:]]*[|]" "$INDEX" | head -n 1)
  fi
  if [ -z "$row" ]; then
    report "$f" "未在 ${INDEX} 登记（需以 | ${id} 开头的表格行）"
    continue
  fi

  # 3) INDEX 该行「触发词」列去空白后必须非空
  if [ -n "$col" ]; then
    cell=$(printf '%s\n' "$row" | awk -F'|' -v c="$col" '{ print $c }')
    cell=$(printf '%s' "$cell" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    if [ -z "$cell" ]; then
      report "$f" "INDEX ${id} 行「触发词」列为空"
    fi
  fi
done

if [ "$n" -gt 0 ]; then
  if [ "${SKILL_META_ENFORCE:-0}" = "1" ]; then
    echo "[SKILL-META] 阻断模式：${n} 项问题（SKILL_META_ENFORCE=1）"
    exit 1
  fi
  echo "[SKILL-META] 告警模式：${n} 项问题（本次不阻断）"
  exit 0
fi

echo "[SKILL-META] 技能元数据校验通过"
exit 0
