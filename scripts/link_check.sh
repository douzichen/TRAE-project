#!/bin/sh
# 规则库链接与结构校验（pre-commit 卡点）：死链、双向链接结构、索引登记、反向链接生成
# 背景：AGENTS.md 已拆为"总纲 + rules/ 分册"，靠相对链接串联；链接一断，规则就找不到了
# 性能：链接边只遍历一次并落临时文件，反向索引用单次 awk 计算（原实现对每个文件×每条分册都起一次 grep，约 27s，改造后 <2s）
set -e
export LC_ALL=C
cd "$(git rev-parse --show-toplevel)"
fail=0

files=$(ls AGENTS.md AGENTS-GLOBAL.md README.md PITFALLS.md 2>/dev/null; find rules docs skills workflows schedules -name '*.md' 2>/dev/null | sort)

# 临时文件一律放在仓库内相对路径（P-017）：mktemp 会返回带盘符/绝对路径，
# 在 Windows + git-bash 及带 safe-delete 包装的环境里会被拒绝，导致门禁误失败。
edges=".git/backlinks-edges.tmp"
: > "$edges" 2>/dev/null || edges="docs/.backlinks-edges.tmp"
trap 'rm -f .git/backlinks-edges.tmp docs/.backlinks-edges.tmp 2>/dev/null || true' EXIT

# 1) 死链校验 + 收集链接边（一次遍历，边格式：源文件<TAB>目标文件名）
for f in $files; do
  dir=$(dirname "$f")
  targets=$(grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed 's/^](//; s/)$//' | grep -vE '^(https?|mailto|#)' || true)
  if [ -n "$targets" ]; then
    for t in $targets; do
      t=${t%%#*}
      [ -z "$t" ] && continue
      case "$t" in *BACKLINKS.md) continue ;; esac
      [ -e "$dir/$t" ] || { echo "[LINK] 死链：$f -> $t"; fail=1; }
      printf '%s\t%s\n' "$f" "${t##*/}" >> "$edges"
    done
  fi
done

sort -u "$edges" -o "$edges"

# 2) 双向链接结构：每个分册必须有"归属总纲"与"相关分册"
for f in rules/*.md; do
  [ -e "$f" ] || continue
  grep -q '归属总纲' "$f" || { echo "[LINK] 缺少归属总纲：$f"; fail=1; }
  grep -q '相关分册' "$f" || { echo "[LINK] 缺少相关分册：$f"; fail=1; }
done

# 3) 分册必须在总纲索引中登记（防孤立文件）
for f in rules/*.md; do
  [ -e "$f" ] || continue
  grep -q "rules/$(basename "$f")" AGENTS.md || { echo "[LINK] 未在总纲索引登记：$f"; fail=1; }
done

# 3b) 分册必须被至少一个其他分册引用（防孤立分册长期无人读）
for f in rules/*.md; do
  [ -e "$f" ] || continue
  base=${f##*/}
  if ! awk -F'\t' -v b="$base" -v s="$f" '$2==b && $1!=s && $1 ~ /^rules\//' "$edges" | grep -q .; then
    echo "[LINK] 孤立分册（无其他分册引用）：$f"
    fail=1
  fi
done

# 4) 生成反向链接索引（自动生成，勿手改）
if [ "$fail" -eq 0 ]; then
  {
    echo "# 反向链接索引（自动生成，请勿手改）"
    echo ""
    echo '> 由 `scripts/link_check.sh` 生成。修改或新增分册后运行该脚本即可刷新。'
    echo ""
    for f in rules/*.md; do
      base=${f##*/}
      echo "## $base"
      echo ""
      awk -F'\t' -v b="$base" -v s="$f" '$2==b && $1!=s {print "- " $1}' "$edges"
      echo ""
    done
  } > docs/BACKLINKS.md
  git add docs/BACKLINKS.md 2>/dev/null || true
  echo "[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md"
else
  echo "[LINK] 链接或结构校验失败，未生成反向链接索引"
  exit 1
fi
