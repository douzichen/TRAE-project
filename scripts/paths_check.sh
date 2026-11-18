#!/bin/sh
# [M1] 裸路径存在性校验 + [M1-b] 门禁脚本跨平台写法校验
# M1：只校验"看起来确实是仓库内路径"的反引号内容：首段必须是仓库内已知目录，
#     或本身就是根目录已知文件；避免把 origin/main、Asia/Shanghai 这类非路径误判。
# M1-b：按 scripts/portable-deny.txt 拦截只在 Linux/GNU 成立的写法（见 P-017、ADR-012）。
cd "$(git rev-parse --show-toplevel)" || exit 1

KNOWN_DIRS='^(rules|docs|scripts|skills|workflows|schedules|prompts|reports|\.githooks)/'
KNOWN_ROOT='^(AGENTS|AGENTS-GLOBAL|README|PITFALLS|CLAUDE|GEMINI)\.md$'

# 临时文件一律用仓库内相对路径：绝对路径在 Windows/git-bash 与 safe-delete 环境会被拒绝（P-017）
problems=".git/paths-problems.tmp"
: > "$problems" 2>/dev/null || problems="docs/.paths-problems.tmp"
trap 'rm -f .git/paths-problems.tmp docs/.paths-problems.tmp 2>/dev/null || true' EXIT

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
  exit 1
fi

# [M1-b] 跨平台可移植性：门禁脚本不得使用只在一个平台成立的写法。
# 违禁清单放独立文件，避免本脚本自我匹配（清单本身是数据，不是代码）。
DENY="scripts/portable-deny.txt"
if [ -f "$DENY" ]; then
  bad=$(for f in scripts/*.sh .githooks/*; do
    [ -f "$f" ] || continue
    grep -Fn -f "$DENY" "$f" 2>/dev/null | while IFS=: read -r ln line; do
      trim=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
      case "$trim" in \#*) continue;; esac
      [ -n "$line" ] && printf '%s:%s:%s\n' "$f" "$ln" "$line"
    done
  done)
  if [ -n "$bad" ]; then
    printf '%s\n' "$bad"
    echo "[M1-b] 跨平台写法校验失败：上列为不可移植写法，改用仓库内相对路径并见 P-017。"
    exit 1
  fi
  echo "[M1-b] 跨平台写法校验通过"
fi

echo "[M1] 裸路径校验通过"
