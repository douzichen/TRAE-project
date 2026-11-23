# 当前交接（最后更新：2026-11-23，与交付同一提交内更新）

> 唯一"当前交接"，细则见 [rules/07](../../rules/07-pending-and-handoff.md)、[ADR-013](../adr/ADR-013-handoff-snapshot.md)；只写 git log 与交付报告看不到的内容，限 ~30 行。

## 目标
规则库进化双机制（ADR-023）试用期观察，至 2026-12-21 凭实证复审；外部规则收集仅走白名单＋三道闸。财税项目本体尚无需求输入，第一个动作由用户下一条指令决定。

## 现状
- ADR-023：指令喜好双层结构（提炼层 rules/01「指令偏好」＋原始层 `.local/` 本地不入库）；外部收集并入周日体检第 8 步，首扫 2026-12-06，沉淀 skills/S-007；外部候选不入常驻集（rules/12 失败模式 ④）。
- 调度器：`._LP-ABG40ZAUH` message 与真源第 21 行逐字一致；`S.KN9NA53ZX_LB` 为例行简报（≤15 行）。
- **2026-11-23 补跑**：11-21～11-23 三日复盘合并落库（审查报告 [reports/R4](../../reports/R4-review-daily-2026-11-23.md)），账本 P-033 → **P-037**；八项问题处置见 [ADR-025](../adr/ADR-025-mechanical-root-cause-elimination.md)（六项机械化、两项如实降级）；落库台账 [RETRO-LOG](RETRO-LOG.md)。

## 已定决策
- handoff v2：随交付同提交更新、不设 archive、~30 行不入固定必读集（ADR-013）。
- 状态表述一律以"可复现证据＋行号"支撑，禁止无证据的"已落实"（P-002/P-004）。

## 坑与未决
- 提炼层残余风险：每轮"用户指令观察"仍靠主会话自觉，无机械保障；漏记按 rules/10 复发即升级。
- 原始层红线：`.local/` 永不入库不推送，违规即停（ADR-023 推翻条件 4）；脱敏判定标准缺口（reports/C-coverage-audit.md ③）仍开，试点期从严。
- 11-22 周日体检的 9 条修剪候选**未裁决**，等用户逐条定夺（只列不改）。
- 试用期复审条件（2026-12-21）：记录条数／重复模式数／确认入册数／命中率。
- 既有未决沿用：D-7 门禁转阻断等首个真实业务/政策文档（ADR-010）。

## 下一步
- 每日开工必跑 `sh scripts/retro_pending_check.sh`（有缺口当日补跑）与 `sh scripts/fact_digest.sh`（报告数字只取此处）。
- 2026-12-06 首扫：候选清单须过 `sh scripts/scan_candidate_check.sh`，不过即清单无效。

## 沉淀
- skills/S-007 v1.1；ADR-025；scripts/{fact_digest,retro_pending_check,scan_candidate_check}.sh。

## 新鲜度核对
- 读者执行 `git log -1 --format='%h %s' -- docs/handoff/CURRENT.md` 与本文件核对，不一致以 git log 为准（P-018）。
