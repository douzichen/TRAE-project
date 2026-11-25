# 当前交接（最后更新：2026-11-25，与交付同一提交内更新）

> 唯一"当前交接"，细则见 [rules/07](../../rules/07-pending-and-handoff.md)、[ADR-013](../adr/ADR-013-handoff-snapshot.md)；只写 git log 与交付报告看不到的内容，限 ~30 行。

## 目标
规则库进化双机制（ADR-023）试用期观察，至 2026-12-21 凭实证复审；外部规则收集仅走白名单＋三道闸。财税项目本体尚无需求输入，第一个动作由用户下一条指令决定。

## 现状
- ADR-023：指令喜好双层结构（提炼层 rules/01「指令偏好」＋原始层 `.local/` 本地不入库）；外部收集并入周日体检第 8 步，首扫 2026-12-06，沉淀 skills/S-007；外部候选不入常驻集（rules/12 失败模式 ④）。
- 调度器：`._LP-ABG40ZAUH` message 与真源第 21 行逐字一致；`S.KN9NA53ZX_LB` 为例行简报（≤15 行）。
- **2026-11-23 补跑**：11-21～11-23 三日复盘合并落库（审查报告 [reports/R4](../../reports/R4-review-daily-2026-11-23.md)），账本 P-033 → **P-037**；九项问题处置见 [ADR-025](../adr/ADR-025-mechanical-root-cause-elimination.md)（六项机械化、两项模板降级、一项文本）；落库台账 [RETRO-LOG](RETRO-LOG.md)。
- **2026-11-23 既有项目接入**：Qoder 三轮实测（既有财税项目，代号"项目 L"，规则库外置）后落 [ADR-027](../adr/ADR-027-legacy-project-onboarding.md) 与 [rules/14](../../rules/14-project-bootstrap.md) C 节（外置引用/只追加/快照范围/只读档作用域）；项目侧 `AGENTS.md` §20 已追加、未提交，待项目自身 §15/§17 流程。
- **2026-11-23 度量与门禁修订**：账本 P-041~P-043（状态码通配符误判、体积/合计口径、正则筛候选假阴性）落库；[ADR-028](../adr/ADR-028-measurement-and-gate-revision.md) 定：METRICS 自动追加移出工作区（`.git/metrics.log` + `--flush` 人工并入）、`closure_check.sh` 非阻断不计序号、pre-push 仅阻 secrets 与 BACKLINKS 新鲜度、PS 最小层。遗留：CI no-go（无 push 权限/依赖暂存区/事后性）；PS 仅 2 个脚本，Windows 侧不构成完整门禁。

## 已定决策
- handoff v2：随交付同提交更新、不设 archive、~30 行不入固定必读集（ADR-013）。
- 状态表述一律以"可复现证据＋行号"支撑，禁止无证据的"已落实"（P-002/P-004）。

## 坑与未决
- 提炼层残余风险：每轮"用户指令观察"仍靠主会话自觉，无机械保障；漏记按 rules/10 复发即升级。
- 原始层红线：`.local/` 永不入库不推送，违规即停（ADR-023 推翻条件 4）；脱敏判定标准已闭环（rules/08「脱敏判定标准」，ADR-026），残余＝语义级判定仍靠人工。
- 11-22 体检 9 条候选**已裁决**（ADR-026）：6 项轻级落地、1 项告警档脚本、2 项不采纳（.trae 入口维持、rules/03 原话不动）。
- P-038~P-040（老项目接入无流程／嵌套规则库建仓风险／"自动注入"自称不实）已由 ADR-027 与 rules/14 C 节承接；项目侧 §20 尚未提交，属已知悬置。
- 试用期复审条件（2026-12-21）：记录条数／重复模式数／确认入册数／命中率；开工自检已加期限告警（剩 ≤30 天提示）。
- 既有未决沿用：D-7 门禁转阻断等首个真实业务/政策文档（ADR-010）。
- 到期看板（2026-11-25 登记）：ADR-030 12-01（项目 L 路径未提供，对撞挂起）｜ADR-026 12-06（首扫，候选清单须过 `scan_candidate_check.sh`，不过即无效）｜ADR-023/024/026 12-21（试用期/观察期复审）；开工自检剩 ≤30 天告警。

## 下一步
- 每日开工必跑 `sh scripts/retro_pending_check.sh`（有缺口当日补跑）与 `sh scripts/fact_digest.sh`（报告数字只取此处）。
- 按 [ADR-028](../adr/ADR-028-measurement-and-gate-revision.md) 落地顺序：`closure_check.sh`（含 ` M`/`.prev` 负样例自测）→ `metrics_collect.sh --flush` 与 post-commit 改写 `.git/metrics.log` → pre-push 区间复核 → 两个 PS 脚本与 fixtures 对拍；每步贴命令输出，未落地不得宣称已生效。
- 遗留不变：CI no-go；PS 仅 2 个脚本（closure_check/triage_untracked），Windows 侧非完整门禁；`--flush` 与 `closure_check` 均依赖人工主动调用。
- `docs/AGENT-ADAPTER.md` 现 128/130：冻结增补，下次改动前先合并重复的"只读/降级/回传"表述，腾出 ≥10 行再谈新增；豆包 2026-11-25 已确认暂停增补。

## 沉淀
- skills/S-007 v1.1；ADR-025、ADR-026、ADR-027；scripts/{fact_digest,retro_pending_check,scan_candidate_check}.sh；规则体检 9 项裁决落地（rules/04/06/08/09/14）；rules/14 C 节（既有项目接入）。

## 新鲜度核对
- 读者执行 `git log -1 --format='%h %s' -- docs/handoff/CURRENT.md` 与本文件核对，不一致以 git log 为准（P-018）。
