# 夜间全库审查报告 YYYY-MM-DD（模板，勿直接提交本文件为某日报告）

> 00:00 复盘同次执行生成（ADR-036）；有自动修复或待裁决冲突才生成，七查全过无冲突则只在 RETRO 行声明"夜间七查通过、无冲突"；六节缺一即视为当日未完成；机械修复与待裁决必须分列，禁止混写。保留期 30 天；超期由主会话归档或删除（属报告、非审计资产），删除须在当日 RETRO 行注明。
## 1. 范围与 commit
<!-- 填：`git log --since='24 hours ago'` 区间与起止 sha7；纳入核对的规则/ADR/脚本/模板清单；未执行项写原因 -->

## 2. 自动修复清单
<!-- 逐条填：file:line｜修了什么｜为何属机械类（不改含义）｜复跑门禁输出摘要；无则写"无"。（示例占位：docs/X.md:12 死链 → ../../rules/06 已更正｜机械｜link_check 通过） -->

## 3. 待裁决冲突清单
<!-- 逐条填：冲突描述｜涉及条款 file:line（双方）｜候选处置｜依据；本清单只报不改，禁止出现"已修改"；无则写"无" -->

## 4. 七查结果
<!-- 逐项写"通过/异常＋摘要"：死链(scripts/link_check.sh)｜编号连续性(PITFALLS 与 S-*/W-* 由 scripts/md_check.sh；ADR 以 INDEX 登记为校验，无独立脚本)｜交叉引用(CONFLICT-MATRIX，人工核对)｜术语漂移(scripts/stale_terms_check.sh)｜预算(scripts/context_budget.sh)｜状态枚举(scripts/pitfall_check.sh)｜台账与事实(scripts/retro_pending_check.sh＋scripts/fact_digest.sh)；无法执行的写原因，不得判通过 -->

## 5. 未闭环项
<!-- 承接昨日未完成项并注明承接次数；同一冲突连续两日未裁决 → 标注"升级 P 条目候选" -->

## 6. 与昨日报告的差异
<!-- 新增/消失/降级的冲突与修复项；无差异写"无" -->
