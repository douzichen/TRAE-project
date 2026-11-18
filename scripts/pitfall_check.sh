#!/bin/sh
# [M4-b] 坑账本字段审计：每条坑必须有「根因」与「状态」；缺证据/现象仅告警
cd "$(git rev-parse --show-toplevel)" || exit 1

f=PITFALLS.md
[ -f "$f" ] || { echo "[M4] 缺少 PITFALLS.md"; exit 1; }

ids=$(grep -oE '^#{2,3} P-[0-9]+' "$f" | grep -oE 'P-[0-9]+')
[ -z "$ids" ] && { echo "[M4] PITFALLS.md 未找到任何坑条目"; exit 1; }

fail=0; warn=0
for id in $ids; do
  body=$(awk -v id="$id" 'BEGIN{p=0} /^#{2,3} P-[0-9]+/{p=(index($2,id)==1)} p' "$f")
  echo "$body" | grep -q '根因' || { echo "[M4] $id 缺少「根因」字段"; fail=1; }
  echo "$body" | grep -q '状态' || { echo "[M4] $id 缺少「状态」字段"; fail=1; }
  echo "$body" | grep -q '证据' || { echo "[M4] $id 缺少「证据」字段（须可复现，不得编造）"; fail=1; }
done

[ "$fail" -eq 1 ] && exit 1
[ "$warn" -eq 1 ] && { echo "[M4] 坑账本字段审计通过（含告警项，建议补证据）"; exit 0; }
echo "[M4] 坑账本字段审计通过（$id 等共 $(echo "$ids" | wc -l | tr -d ' ') 条）"
