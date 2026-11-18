# 当前交接（最后更新：2026-11-18；与交付同一提交内更新）

> 本文件是唯一"当前交接"，细则见 [rules/07](../../rules/07-pending-and-handoff.md)（[ADR-013](../adr/ADR-013-handoff-snapshot.md)）；只写 git log 与交付报告看不到的内容。

## 目标

规则库维护（本轮已落地"续窗衔接 handoff 机制"）；下一阶段待开工的是财税项目本体，尚无需求输入。

## 现状

- 上一提交完成：ADR-013、rules/07 交接快照节、HANDOFF 模板、SESSION-START 衔接步、冲突矩阵 07×02/12/13 三格、daily-retro 增 CURRENT.md 比对步并已同步调度器（`._LP-ABG40ZAUH`）、本文件首份实例。
- 本提交完成：P-018 第二次复发升级——新增只读 `scripts/session_start_check.sh`；SESSION-START 增第 0 步（同源/版本/交接/金丝雀）；rules/02 加一行指针（必读集 158/160）；README 四处同步；ADR-014。
- 未提交半成品：无（本提交即全部落地内容）。

## 已定决策

- handoff v2：随交付同提交更新；不设 archive（git 历史即归档）；~30 行不入常驻必读集；新鲜度用 `git log -1 -- docs/handoff/CURRENT.md` 比对；否决 archive 目录与口述主触发，理由见 [ADR-013](../adr/ADR-013-handoff-snapshot.md) 否决项。

## 未决与坑

- 待确认台账指针：rules/07 台账与最近交付 D-6。当前 1 项业务侧待确认：「不上传」约束是项目级红线还是 WorkBuddy 本机环境约束（用户未答复，原话存于该轮交付）。
- D-7 门禁转阻断：事件触发，等首个真实业务/政策文档落地（[ADR-010](../adr/ADR-010-policy-evidence-gate.md)）。

## 下一步

- 新窗口按 SESSION-START 开工令：读规则 → 读本文件并核对新鲜度 → 复述差异 → 等用户确认再动手；第一个动作由用户下一条指令决定。

## 沉淀与记忆收录

- 本轮不新增 skill（机制已入 rules/07，再做 skill 会形成双口径）；详见最近交付 D-6。

## 新鲜度核对

- 填写时仓库 HEAD 见本提交；读者执行 `git log -1 --format='%h %s' -- docs/handoff/CURRENT.md` 复核，不一致以 git log 为准。
