#!/bin/sh
# [M1] 裸路径存在性校验
# 只校验"看起来确实是仓库内路径"的反引号内容：首段必须是仓库内已知目录，
# 或本身就是根目录已知文件；避免把 origin/main、Asia/Shanghai 这类非路径误判。
cd "$(git rev-parse --show-toplevel)" || exit 1

KNOWN_DIRS='^(rules|docs|scripts|skills|workflows|schedules|prompts|reports|\.githooks)/'
KNOWN_ROOT='^(AGENTS|AGENTS-GLOBAL|README|PITFALLS|CLAUDE|GEMINI)\.md$'

problems=$(mktemp)
git ls-files '*.md' | grep -vE '^(reports|\.uploads)/' | while IFS= read -r f; do
  d=$(dirname "$f")
  grep -oE '`[A-Za-z0-9_./-]+`' "$f" 2>/dev/null \
  | tr -d '`' \
  | grep -E "$KNOWN_DIRS$KNOWN_ROOT" \
  | grep -E '\.(md|sh|json|conf)$' \
  | grep -vE '\*|\.\.\.|<|\{|x\.md$|foo' \
  | while IFS= read -r p; do
      case "$p" in */) continue;; esac
      [ -e "$p" ] || [ -e "$d/$p" ] || echo "[M1] 失效路径：$f -> $p"
    done
done > "$problems"

if [ -s "$problems" ]; then
  cat "$problems"
  echo "[M1] 裸路径校验失败：上列路径不存在，请修正引用。"
  rm -f "$problems"
  exit 1
fi
rm -f "$problems"
echo "[M1] 裸路径校验通过"
