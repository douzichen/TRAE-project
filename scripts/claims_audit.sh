#!/bin/sh
# [M4-a] 认领表格式审计：docs/CLAIMS.md 可被机器读，且不重复规则口径
cd "$(git rev-parse --show-toplevel)" || exit 1

f=docs/CLAIMS.md
[ -f "$f" ] || { echo "[M4] 缺少 docs/CLAIMS.md（多 Agent 并行认领表）"; exit 1; }

fail=0

for col in 认领人 文件或目录 开始时间 预计结束 状态; do
  grep -q "$col" "$f" || { echo "[M4] CLAIMS.md 缺少表头列：$col"; fail=1; }
done

# 数据行判定：以 | 开头、列数足够、第 2 列不是表头也不是分隔行
rows=$(awk -F'|' 'NF>=7 && $2 !~ /认领人|---/ && $0 !~ /示例|填写/ {print}' "$f")

bad_time=$(echo "$rows" | awk -F'|' 'NF>=7 {print $5}' \
  | grep -vE '^ *$' | grep -vE '^ *[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} \+08:00 *$' || true)
[ -n "$bad_time" ] && {
  echo "[M4] CLAIMS.md 开始时间格式不合规（应为 YYYY-MM-DD HH:MM +08:00）："; echo "$bad_time"; fail=1; }

bad_state=$(echo "$rows" | awk -F'|' 'NF>=7 {print $6}' \
  | grep -vE '^ *$' | grep -vE '^ *(进行中|待审查|已完成|已放弃) *$' || true)
[ -n "$bad_state" ] && {
  echo "[M4] CLAIMS.md 状态枚举不合规（只允许 进行中/待审查/已完成/已放弃）："; echo "$bad_state"; fail=1; }

if grep -qE '过期|回收|2 小时' "$f"; then
  echo "[M4] CLAIMS.md 重复了规则口径（过期/回收），口径必须只在 rules/13 维护"
  fail=1
fi

[ "$fail" -eq 1 ] && exit 1
echo "[M4] 认领表审计通过"
