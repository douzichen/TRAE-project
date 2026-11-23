#!/bin/sh
# 敏感信息扫描（C-2：此前仅在 rules/08 有一句话，无任何机械拦截）
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0

files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null; git diff --name-only --diff-filter=ACM 2>/dev/null)
[ -z "$files" ] && { echo "[SECRET] 无待检查改动"; exit 0; }

patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}'

oldIFS=$IFS
IFS='
'
for f in $files; do
  [ -f "$f" ] || continue
  case "$f" in .secrets/*|*.jpg|*.jpeg|*.png|*.zip) continue ;; esac
  # 必须用 -e：$patterns 以 "-----BEGIN" 开头，不加 -e 会被 grep 当作选项，整条规则静默失效
  if grep -nE -e "$patterns" "$f" >/dev/null 2>&1; then
    echo "[SECRET] 疑似凭据泄露：$f（命中私钥/Token 特征）"; fail=1
  fi
  if grep -nEI 'password[[:space:]]*=[[:space:]]*[^ "]{6,}' "$f" >/dev/null 2>&1; then
    echo "[SECRET] 疑似明文口令：$f"; fail=1
  fi
  # [ADR-026] 脱敏机械辅助：仅高精度模式，先告警不阻断（rules/10；判定标准见 rules/08）
  if grep -nEI '(^|[^0-9])[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]([^0-9A-Za-z]|$)' "$f" >/dev/null 2>&1; then
    echo "[PII][WARN] 疑似身份证号：$f（按 rules/08 脱敏；告警档，不阻断）"
  fi
  if grep -nEI '(^|[^0-9])1[3-9][0-9]{9}([^0-9]|$)' "$f" >/dev/null 2>&1; then
    echo "[PII][WARN] 疑似手机号：$f（按 rules/08 脱敏；告警档，不阻断）"
  fi
done
IFS=$oldIFS

if [ "$fail" -eq 0 ]; then echo "[SECRET] 敏感信息扫描通过"; else echo "[SECRET] 禁止提交，请移除凭据或加入 .gitignore"; exit 1; fi
