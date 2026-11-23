#!/bin/sh
# 事实取数摘要（只读）：复盘/简报/审查报告里的数字一律引用本脚本输出，禁止手算子
# 依据：ADR-025；P-036（churn 当净差、文件数与行数误报）、P-030（绝对化声明无佐证）
# 用法：sh scripts/fact_digest.sh    （不改工作区、不联网、不 fetch）
set -u
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || { echo "[FACT] 不在 git 仓库内，先 clone"; exit 1; }

w=$(TZ=Asia/Shanghai date +%u 2>/dev/null || date +%u)
case "$w" in
  1) wd=周一 ;; 2) wd=周二 ;; 3) wd=周三 ;; 4) wd=周四 ;;
  5) wd=周五 ;; 6) wd=周六 ;; 7) wd=周日 ;; *) wd=未知 ;;
esac
echo "[FACT] 日期：$(TZ=Asia/Shanghai date +%Y-%m-%d)（$wd，Asia/Shanghai）"

# 版本
head_short=$(git rev-parse --short HEAD 2>/dev/null)
head_subj=$(git log -1 --format='%s' 2>/dev/null)
echo "[FACT] HEAD：$head_short $head_subj"

# 近 24h / 48h 提交（只算数量与清单，不做净变更推算）
c24=$(git rev-list --count --since='24 hours ago' HEAD 2>/dev/null)
c48=$(git rev-list --count --since='48 hours ago' HEAD 2>/dev/null)
echo "[FACT] 近 24h 提交数：${c24:-0}｜近 48h：${c48:-0}"
git log --oneline --date=short --pretty='  %h %ad %s' --since='48 hours ago' 2>/dev/null | head -20

# 净变更口径必须显式标注：唯一文件数与净增删用 diff --shortstat，churn 单列
echo "[FACT] 统计口径说明：净增删须用 git diff --shortstat <A>..<B>（唯一文件数与净增删）；churn（多次提交加减之和）单独标注，两者不得混用"

# 坑账本
if [ -f PITFALLS.md ]; then
  n=$(grep -c '^### P-[0-9][0-9]' PITFALLS.md 2>/dev/null)
  mx=$(grep -o '^### P-[0-9][0-9][0-9]' PITFALLS.md 2>/dev/null | tail -1 | sed 's/^### //')
  lines=$(wc -l < PITFALLS.md | tr -d ' ')
  lastc=$(git log -1 --format='%ad' --date=short -- PITFALLS.md 2>/dev/null)
  echo "[FACT] PITFALLS：${n:-0} 条｜最大编号 ${mx:-无}｜${lines} 行｜最后提交 ${lastc:-无}"
fi

# 交接快照新鲜度
if [ -f docs/handoff/CURRENT.md ]; then
  cs=$(git log -1 --format='%h %ad' --date=short -- docs/handoff/CURRENT.md 2>/dev/null)
  behind=$(git rev-list --count "$(git log -1 --format='%H' -- docs/handoff/CURRENT.md 2>/dev/null)..HEAD" 2>/dev/null)
  echo "[FACT] CURRENT.md：${cs:-未入库}｜落后 HEAD ${behind:-?} 个提交"
fi

# 报告与原始层
rn=$(ls reports/*.md 2>/dev/null | wc -l | tr -d ' ')
tracked_local=$(git ls-files 2>/dev/null | grep -c '^\.local/' || true)
echo "[FACT] reports/*.md 文件数：${rn:-0}｜.local/ 入库条目：${tracked_local:-0}（应为 0）"

# METRICS 尾部
if [ -f docs/METRICS.md ]; then
  echo "[FACT] METRICS 尾部两行："
  tail -2 docs/METRICS.md | sed 's/^/  /'
fi

# 工作区
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  echo "[FACT] 工作区：干净"
else
  echo "[FACT] 工作区未提交改动："
  git status --porcelain 2>/dev/null | sed 's/^/  /'
fi
echo "[FACT] 以上数字可直接引用；未出现在本输出中的数字不得写进报告"
