# 当前交接（最后更新：2026-11-19；与交付同一提交内更新）

> 本文件是唯一"当前交接"，细则见 [rules/07](../../rules/07-pending-and-handoff.md)（[ADR-013](../adr/ADR-013-handoff-snapshot.md)）；只写 git log 与交付报告看不到的内容。

## 目标

规则库维护（本轮已落地"续窗衔接 handoff 机制"）；下一阶段待开工的是财税项目本体，尚无需求输入。

## 现状

- 上一提交完成：ADR-013、rules/07 交接快照节、HANDOFF 模板、SESSION-START 衔接步、冲突矩阵 07×02/12/13 三格、daily-retro 增 CURRENT.md 比对步并已同步调度器（`._LP-ABG40ZAUH`）、本文件首份实例。
- 本提交完成：P-018 第二次复发升级——新增只读 `scripts/session_start_check.sh`；SESSION-START 增第 0 步（同源/版本/交接/金丝雀）；rules/02 加一行指针（必读集 158/160）；README 四处同步；ADR-014。
- 本提交完成：验证型外部 Agent 只读落地——rules/04 新增专节；rules/03 收窄同步推送义务的适用范围；S-004、AGENT-ADAPTER、AGENTS.md、AGENTS-GLOBAL 同步；ADR-015；冲突矩阵 03×04、04×13 补依据。
- 本提交完成：两处轻级补丁——SESSION-START 第 0 步补 Windows 平台写法；自检脚本第 4 项加"快照距今 N 个提交"提示（不参与判定）；S-004 可粘贴指令第 1、2 条补"已有副本先 pull"与"先跑自检"；S-004 四处金丝雀表述统一为"只证明副本内容、不证明宿主加载"。
- 本提交完成：WorkBuddy 接入验证回报后的三处文档校正——ROLE-SWITCH-CHECK 问 4 改 D-1~D-7；ADR-008 补注 D 项数沿革；AGENT-ADAPTER 门禁降级改两档（零改动 2 项 / 本地试改全链 8 项）。
- 本提交完成：WorkBuddy 只读整改回执后的机制补强——S-004 第 7 条与 AGENT-ADAPTER 第五节明确"每个新 clone 都要置空 credential.helper 并 push --dry-run 自证失败"，堵住重 clone 后全局凭据复活的缺口。
- 本提交完成：P-019——每日复盘定时任务 00:00 派发但零产物（Executions:1、git 无提交），人工发现后当日补跑；防复发：产物锚（复盘必须以 git 提交为准）+ 每日首次会话核对派发/提交对应性，写入 schedules/daily-retro.md 新增「执行后验证」节。待确认：平台侧派发会话静默失败原因。
- 本提交完成：截图核实 P-019 平台根因（派发=全新沙箱，workspace 空、无凭据）并升级机制——真源任务消息改自举式（匿名 clone + 报告输出在会话、落库归主会话）；用户批准的 [M5] 口径漂移门禁上线（ADR-016，豁免审计资产），首轮即抓到 rules/06、rules/13 两处旧口径漏网并更正。
- 本提交完成：调度器消息同步落地（用户指令"同步"）——实例 `._LP-ABG40ZAUH` 换为自举式消息，与真源 schedules/daily-retro.md 第 21 行逐字一致，下次执行 2026-11-20 00:00:42；真源「调度器同步状态」标注更新为已同步。11-20 00:00 起按两层产物锚验证：派发会话报"未推送+报告在会话"→ 主会话落库。
- 未提交半成品：无（本提交即全部落地内容）。

## 已定决策

- handoff v2：随交付同提交更新；不设 archive（git 历史即归档）；~30 行不入常驻必读集；新鲜度用 `git log -1 -- docs/handoff/CURRENT.md` 比对；否决 archive 目录与口述主触发，理由见 [ADR-013](../adr/ADR-013-handoff-snapshot.md) 否决项。

## 未决与坑

- 待确认台账指针：rules/07 台账与最近交付 D-6。业务侧已清零——「不上传」经用户明确为**项目级限制**（外部 Agent 仅用于验证规则、一律只读），已落 [rules/04](../../rules/04-roles-and-dispatch.md#L48-L56) 与 [ADR-015](../adr/ADR-015-validation-agents-readonly.md)。
- 技术侧已清零：两处轻级补丁已获用户批准并落地（本提交）。
- D-7 门禁转阻断：事件触发，等首个真实业务/政策文档落地（[ADR-010](../adr/ADR-010-policy-evidence-gate.md)）。

## 下一步

- 新窗口按 SESSION-START 开工令：读规则 → 读本文件并核对新鲜度 → 复述差异 → 等用户确认再动手；第一个动作由用户下一条指令决定。

## 沉淀与记忆收录

- 本轮不新增 skill（机制已入 rules/07，再做 skill 会形成双口径）；详见最近交付 D-6。

## 新鲜度核对

- 填写时仓库 HEAD 见本提交；读者执行 `git log -1 --format='%h %s' -- docs/handoff/CURRENT.md` 复核，不一致以 git log 为准。
