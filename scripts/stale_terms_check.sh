#!/bin/sh
# [M5] 口径漂移校验：活文档不得残留被取代的旧口径字样（P-019 复盘聚类，ADR-016）
# 违禁清单放独立文件（数据与代码分离），审计资产（docs/adr/、PITFALLS.md、reports/）豁免——
# 它们引用历史原文是合法的，拦截它们等于篡改审计记录。
cd "$(git rev-parse --show-toplevel)" || exit 1

DENY="scripts/stale-terms.txt"
[ -f "$DENY" ] || { echo "[M5] 缺少违禁清单 scripts/stale-terms.txt"; exit 1; }

problems=".git/stale-problems.tmp"
: > "$problems" 2>/dev/null || problems="docs/.stale-problems.tmp"
trap 'rm -f .git/stale-problems.tmp docs/.stale-problems.tmp 2>/dev/null || true' EXIT

git ls-files '*.md' | grep -vE '^(docs/adr/|reports/|\.uploads/)' | grep -vx 'PITFALLS.md' | while IFS= read -r f; do
  grep -nE -f "$DENY" "$f" 2>/dev/null | while IFS=: read -r ln line; do
    trim=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
    case "$trim" in \#*) continue;; esac
    printf '%s:%s:%s\n' "$f" "$ln" "$line"
  done
done > "$problems"

if [ -s "$problems" ]; then
  cat "$problems"
  echo "[M5] 口径漂移校验失败：上列活文档残留旧口径（豁免仅限审计资产），更正为现行口径或移入豁免路径。"
  exit 1
fi

echo "[M5] 口径漂移校验通过"
