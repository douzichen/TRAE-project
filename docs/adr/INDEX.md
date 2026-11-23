# ADR 索引（架构与规则决策记录）

> 作用：重要决策一条一文件，记录"为什么这么做、否决了什么、什么条件下应推翻"。
> 与 Git 历史的关系：ADR 优先——有 ADR 就不需要靠翻 Git 提交去猜当初的意图。
> 红线：ADR 属审计资产，永不算历史包袱，不得以清理为名删除。

| 编号 | 标题 | 日期 | 状态 |
| --- | --- | --- | --- |
| [ADR-001](ADR-001-adopt-ten-prompts.md) | 采纳"十条提问法"并做分级触发改造 | 2026-11-18 | 已接受 |
| [ADR-002](ADR-002-fix-conflicts-in-ten-prompts.md) | 修正十条提问法落地条款的三处自相矛盾 | 2026-11-18 | 已接受 |
| [ADR-003](ADR-003-rules-split-with-bidirectional-links.md) | 规则库改为总纲＋分册＋双向链接 | 2026-11-18 | 已接受 |
| [ADR-004](ADR-004-context-budget.md) | 为规则库设置上下文预算与按需加载 | 2026-11-18 | 部分被取代 |
| [ADR-005](ADR-005-first-self-audit-ruling.md) | 首次自检的三路审计裁定与修复分工 | 2026-11-18 | 部分被取代 |
| [ADR-006](ADR-006-rule-change-two-tier.md) | 规则条款变更改为"是否改变含义"两级制 | 2026-11-18 | 已接受 |
| [ADR-007](ADR-007-supersede-budget-threshold.md) | 以 160 行取代最小必读集预算阈值（取代 ADR-004/005 阈值条款） | 2026-11-18 | 已接受 |
| [ADR-008](ADR-008-project-bootstrap-and-requirements-intake.md) | 项目启动与需求受理采用"规则＋skill＋模板＋workflow"四件套 | 2026-11-18 | 已接受 |
| [ADR-009](ADR-009-move-dod-out-of-core.md) | 把 D-1~D-6 交付清单移出最小必读集，换回预算余量 | 2026-11-18 | 已接受 |
| [ADR-010](ADR-010-policy-evidence-gate.md) | 涉税/政策结论的依据核验门禁（业务类硬约束、技术类软约束） | 2026-11-18 | 已接受 |
| [ADR-011](ADR-011-no-auto-injection.md) | 本宿主无自动注入，改为显式传递与可检产物 | 2026-11-18 | 已接受 |
| [ADR-012](ADR-012-gate-script-portability.md) | 门禁脚本跨平台可移植性：机械拦截不可移植写法 | 2026-11-18 | 已接受 |
| [ADR-013](ADR-013-handoff-snapshot.md) | 续窗衔接机制：CURRENT.md 快照随交付更新、不设归档目录 | 2026-11-18 | 已接受 |
| [ADR-014](ADR-014-session-start-selfcheck.md) | 新窗口开工自检脚本与开工令第 0 步（P-018 二次复发升级） | 2026-11-18 | 已接受 |
| [ADR-015](ADR-015-validation-agents-readonly.md) | 验证型外部 Agent 只读：禁止推送与上传，收窄 rules/03 适用范围 | 2026-11-18 | 已接受 |
| [ADR-016](ADR-016-stale-terms-gate.md) | 口径漂移机械拦截：[M5] 活文档禁残留旧口径字样，审计资产豁免 | 2026-11-19 | 已接受 |
| [ADR-017](ADR-017-cross-project-operating-model.md) | 跨项目运行模型：规则唯一通道、写入口唯一、拉取式迭代 | 2026-11-19 | 已接受 |
| [ADR-018](ADR-018-clean-copy-repull.md) | 在途项目重拉采用干净副本基线与任务片边界换规 | 2026-11-19 | 已接受 |
| [ADR-019](ADR-019-startup-sync-gate.md) | 开工强制握手——本地落后远端即先拉再开工 | 2026-11-19 | 已接受 |
| [ADR-020](ADR-020-skill-metadata-spec.md) | 技能元数据化采用四栏规格＋机械校验，不做自动触发 | 2026-11-19 | 已接受 |
| [ADR-021](ADR-021-universal-hardening-eight-dispositions.md) | 通用化加固：八项缺口处置 | 2026-11-20 | 已接受（完整：第二远端双推已验证；条款一终局裁定不建） |
| [ADR-022](ADR-022-external-agent-field-test.md) | 外部 Agent 实测排班三棒收口：接入可行，红线全达成 | 2026-11-20 | 已接受 |
| [ADR-023](ADR-023-rulebase-evolution-mechanisms.md) | 规则库进化双机制：指令喜好双层结构（试用期至 2026-12-21）＋外部规则月度收集并入周日体检 | 2026-11-21 | 已接受 |
| [ADR-024](ADR-024-external-agent-instruction-observation.md) | 外部 Agent 指令偏好学习适配：平台分档原始层＋脱敏候选回传（扩展 ADR-023，限外部 Agent） | 2026-11-21 | 已接受 |
| [ADR-025](ADR-025-mechanical-root-cause-elimination.md) | 复盘与调查审查九项问题的机械化处置（三脚本＋台账制＋两处如实降级） | 2026-11-23 | 已接受 |

## 何时必须写 ADR

- 影响面大、不可逆、成本高的决策（规则库结构调整、技术选型、目录约定变更）。
- 有多个候选方案且被否决的方案后续可能被重新提出的情况。
- 小改动、措辞修订不写 ADR，避免噪音（改变含义的修订必须写 ADR）。
