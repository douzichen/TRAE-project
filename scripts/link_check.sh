#!/bin/sh
# 规则库链接与结构校验（pre-commit 卡点）：死链、双向链接结构、索引登记、反向链接生成
# 背景：AGENTS.md 已拆为"总纲 + rules/ 分册"，靠相对链接串联；链接一断，规则就找不到了
set -e
cd "$(git rev-parse --show-toplevel)"
fail=0

files=$(ls AGENTS.md AGENTS-GLOBAL.md README.md PITFALLS.md 2>/dev/null; find rules docs skills workflows schedules -name '*.md' 2>/dev/null | sort)

# 1) 死链校验：相对链接的目标必须存在
for f in $files; do
  dir=$(dirname "$f")
  for t in $(grep -oE '\]\([^)]+\)' "$f" | sed 's/^](//; s/)$//' | grep -vE '^(https?|mailto|#)' || true); do
    t=${t%%#*}
    [ -z "$t" ] && continue
    case "$t" in *BACKLINKS.md) continue ;; esac
    [ -e "$dir/$t" ] || { echo "[LINK] 死链：$f -> $t"; fail=1; }
  done
done

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
  base=$(basename "$f")
  hit=0
  for other in rules/*.md; do
    [ "$other" = "$f" ] && continue
    if grep -qE "\]\(([^)]*/)?$base(#[^)]*)?\)" "$other"; then hit=1; break; fi
  done
  [ "$hit" -eq 1 ] || { echo "[LINK] 孤立分册（无其他分册引用）：$f"; fail=1; }
done

# 4) 生成反向链接索引（自动生成，勿手改）
if [ "$fail" -eq 0 ]; then
  {
    echo "# 反向链接索引（自动生成，请勿手改）"
    echo ""
    echo "> 由 \`scripts/link_check.sh\` 生成。修改或新增分册后运行该脚本即可刷新。"
    echo ""
    for f in rules/*.md; do
      echo "## $(basename "$f")"
      echo ""
      for src in $files; do
        [ "$src" = "$f" ] && continue
        if grep -qE "\]\(([^)]*/)?$(basename "$f")(#[^)]*)?\)" "$src"; then
          echo "- $src"
        fi
      done
      echo ""
    done
  } > docs/BACKLINKS.md
  git add docs/BACKLINKS.md 2>/dev/null || true
  echo "[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md"
else
  echo "[LINK] 链接或结构校验失败，未生成反向链接索引"
  exit 1
fi
