#!/bin/sh
# 敏感信息扫描（C-2：此前仅在 rules/08 有一句话，无任何机械拦截）
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0

files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null; git diff --name-only --diff-filter=ACM 2>/dev/null)
[ -z "$files" ] && { echo "[SECRET] 无待检查改动"; exit 0; }

patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}'

for f in $files; do
  [ -f "$f" ] || continue
  case "$f" in .secrets/*|*.jpg|*.jpeg|*.png|*.zip) continue ;; esac
  if grep -nEI "$patterns" "$f" >/dev/null 2>&1; then
    echo "[SECRET] 疑似凭据泄露：$f（命中私钥/Token 特征）"; fail=1
  fi
  if grep -nEI 'password[[:space:]]*=[[:space:]]*[^ "]{6,}' "$f" >/dev/null 2>&1; then
    echo "[SECRET] 疑似明文口令：$f"; fail=1
  fi
done

if [ "$fail" -eq 0 ]; then echo "[SECRET] 敏感信息扫描通过"; else echo "[SECRET] 禁止提交，请移除凭据或加入 .gitignore"; exit 1; fi
