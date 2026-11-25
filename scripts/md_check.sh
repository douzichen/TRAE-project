#!/bin/sh
# P-004 markdown 完整性校验（pre-commit 卡点）：INDEX 登记、坑编号连续、标题去重
set -e
cd "$(git rev-parse --show-toplevel)"
fail=0

# 1) skills：每个 S-*.md 必须登记在 skills/INDEX.md
for f in skills/S-*.md; do
  [ -e "$f" ] || continue
  grep -q "$(basename "$f")" skills/INDEX.md || { echo "[P-004] 未登记: $f"; fail=1; }
done

# 2) workflows：每个 W-*.md 必须登记在 workflows/INDEX.md
for f in workflows/W-*.md; do
  [ -e "$f" ] || continue
  grep -q "$(basename "$f")" workflows/INDEX.md || { echo "[P-004] 未登记: $f"; fail=1; }
done

# 3) PITFALLS.md 编号从 P-001 起连续递增
prev=0
for raw in $(grep -oE '^### P-[0-9]{3}' PITFALLS.md | grep -oE '[0-9]{3}'); do
  n=$(echo "$raw" | sed 's/^0*//'); [ -z "$n" ] && n=0
  if [ "$n" -ne $((prev + 1)) ]; then
    echo "[P-004] 坑编号不连续：期望 P-$(printf '%03d' $((prev + 1)))，实际 P-$raw"; fail=1
  fi
  prev=$n
done

# 4) AGENTS.md 章节标题不允许重复
dups=$(grep -E '^## ' AGENTS.md | sort | uniq -d)
if [ -n "$dups" ]; then
  echo "[P-004] AGENTS.md 存在重复章节：$dups"; fail=1
fi

# 5) 技能同步门禁：skills/workflows 不允许存在未提交的散改（改了不提交=未同步=任务未完成）
if ! git diff --quiet -- skills workflows; then
  echo "[SYNC] skills/workflows 存在未提交改动，视为未同步，禁止提交一部分留一部分"; fail=1
fi

# 6) 同步核对（非阻断提醒）：领先远端即"未推送=同步未完成"
ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
if [ "$ahead" -gt 0 ]; then
  echo "[SYNC] 分支领先远端 $ahead 个提交，未推送=同步未完成（推送后须核对 ahead 0）" >&2
fi

# 7) 关键铁律分册不得被误删，且必须有内容（P-006/P-007 防复发：只查文件存在拦不住整节被删）
for f in rules/00-core.md rules/01-user-profile.md rules/02-intake-and-dod.md rules/05-requirement-review.md rules/06-quality.md rules/10-lessons.md; do
  [ -e "$f" ] || { echo "[P-004] 缺失关键分册：$f"; fail=1; }
done
for key in "rules/00-core.md" "rules/01-user-profile.md" "rules/02-intake-and-dod.md" "rules/05-requirement-review.md" "rules/06-quality.md" "rules/10-lessons.md"; do
  grep -qF "$key" AGENTS.md || { echo "[P-004] 总纲索引未登记：$key"; fail=1; }
done

# 7b) 内容级校验：关键分册必须含其核心条款关键词（防"章节被清空但文件还在"）
for pair in "rules/01-user-profile.md:财税从业者" "rules/01-user-profile.md:提问只问业务" "rules/02-intake-and-dod.md:D-1" "rules/02-intake-and-dod.md:复述" "rules/05-requirement-review.md:政策" "rules/12-context-budget.md:未完整读取" "rules/13-concurrency-and-lifecycle.md:认领" "rules/04-roles-and-dispatch.md:执行路径卡" "rules/04-roles-and-dispatch.md:失败不漂移" "rules/08-alignment-and-versioning.md:客户数据入库" "rules/08-alignment-and-versioning.md:底稿默认不入 git" "rules/08-alignment-and-versioning.md:未列即禁" "rules/08-alignment-and-versioning.md:无远端不等于不外流"; do
  f=${pair%%:*}; k=${pair#*:}
  [ -e "$f" ] || continue
  grep -qF "$k" "$f" || { echo "[P-004] 核心条款缺失：$f 不含关键词「$k」"; fail=1; }
done

# 7c) 工具与执行路径判定节结构校验（ADR-031）：标题＋7 条锚点＋模板与 ADR 必须存在
[ -e templates/TOOL-PATH-CARD.md ] || { echo "[P-045] 缺失执行路径卡模板"; fail=1; }
[ -e docs/adr/ADR-031-tool-path-judgement.md ] || { echo "[P-045] 缺失 ADR-031"; fail=1; }
grep -qF '## 工具与执行路径判定' rules/04-roles-and-dispatch.md 2>/dev/null || { echo "[P-045] rules/04 缺失「工具与执行路径判定」节"; fail=1; }
for k in 路径卡先行 通道优先级 权限不足 失败不漂移 写前幂等盘点 授权由用户亲手确认 动作必回读; do
  grep -qF "$k" rules/04-roles-and-dispatch.md 2>/dev/null || { echo "[P-045] 工具路径条款缺失：$k"; fail=1; }
done

# 8) 审计资产只增不减（C-3：删掉末条坑或整份 ADR 也能过检 → 补此检查）
cnt_now=$(grep -cE '^### P-[0-9]{3}' PITFALLS.md || true)
cnt_head=$(git show HEAD:PITFALLS.md 2>/dev/null | grep -cE '^### P-[0-9]{3}' || true)
if [ -n "$cnt_head" ] && [ "${cnt_now:-0}" -lt "${cnt_head:-0}" ]; then
  echo "[P-010] 审计资产被删减：坑条目 $cnt_head → $cnt_now，账本只增不减"; fail=1
fi
adr_now=$(ls docs/adr/ADR-*.md 2>/dev/null | wc -l | tr -d ' ')
adr_head=$(git ls-tree --name-only HEAD docs/adr/ 2>/dev/null | grep -c '^docs/adr/ADR-.*\.md$' || true)
if [ -n "$adr_head" ] && [ "${adr_now:-0}" -lt "${adr_head:-0}" ]; then
  echo "[P-010] 审计资产被删减：ADR $adr_head → $adr_now，决策记录只增不减"; fail=1
fi

# 9) ADR 合卷门禁（rules/13 / ADR-021）：达 50 条而 INDEX 未分卷即拦截，不靠人眼
if [ "${adr_now:-0}" -ge 50 ] && ! grep -q '当前卷' docs/adr/INDEX.md 2>/dev/null; then
  echo "[P-004] ADR 已达 $adr_now 条（≥50），INDEX 未分'当前卷/历史卷'，须按 rules/13 合卷"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "[P-004] md 完整性校验通过"
else
  exit 1
fi
