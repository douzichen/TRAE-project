# 项目全局记忆（规则库·总纲）

> 本文件是规则库的**总纲与索引**，不承载全部细则：细则在 `rules/` 各分册，**细则与本文摘要冲突时以分册为准**，并立即修正摘要。
> 本文件与 `rules/` 下的内容均为铁律，主会话与所有子会话、所有接入本仓库的 Agent 均须遵守。

## 新规则落到哪一册（路由表，禁止靠猜）

| 你要写的内容 | 落到 |
| --- | --- |
| 用户身份、职业边界、沟通偏好 | [01](rules/01-user-profile.md) |
| 收到指令后的行为（复述、边界确认、交付格式） | [02](rules/02-intake-and-dod.md) |
| skill/workflow 的同步与副本一致性 | [03](rules/03-skill-sync.md) |
| 主/子 Agent 分工、派发、执行控制 | [04](rules/04-roles-and-dispatch.md) |
| 需求是否成立、财税合规依据 | [05](rules/05-requirement-review.md) |
| 决策方法、审查方法、复盘节奏、任务分级 | [06](rules/06-quality.md) |
| 待确认事项、会话交接 | [07](rules/07-pending-and-handoff.md) |
| 文档一致性、提交推送、版本与 tag | [08](rules/08-alignment-and-versioning.md) |
| 沉淀 skill/workflow 的触发与做法 | [09](rules/09-precipitation.md) |
| 坑的记录、复盘与升级 | [10](rules/10-lessons.md) |
| 回滚手段 | [11](rules/11-rollback.md) |

- 多条都像时，写入**最贴近的那一册**，并在其"相关分册"补链接；仍无法归类才考虑新建分册，且须先记入待确认事项请用户确认。

## 会话启动阅读顺序（固定，不得跳读）

1. 本文件（总纲 + 核心红线速查）
2. [00 执行前必读](rules/00-core.md)
3. [01 用户背景](rules/01-user-profile.md)
4. [02 指令接收与交付清单](rules/02-intake-and-dod.md)
5. 再按任务类型读下表对应分册

## 核心红线速查（完整表述见对应分册）

| # | 红线 | 细则 |
| --- | --- | --- |
| 1 | 动手前先读完规则库，不凭记忆办事 | [00](rules/00-core.md) |
| 2 | 用户是财税从业者；不把技术决策推回给用户；不附和 | [01](rules/01-user-profile.md) |
| 3 | 收到指令先复述需求、列出边界，确认后再动手 | [02](rules/02-intake-and-dod.md) |
| 4 | 交付必须给全 D-1~D-6，禁止"如需再贴请说"式推迟 | [02](rules/02-intake-and-dod.md) |
| 5 | 财税判断必须写出政策条款并核实清楚，不确定不得下结论 | [05](rules/05-requirement-review.md) |
| 6 | 口径先行—子 Agent 撰写—主 Agent 审查，审查通过才算交付 | [04](rules/04-roles-and-dispatch.md) |
| 7 | 文档与文档、文档与实现必须对齐；改动须给影响面表 | [08](rules/08-alignment-and-versioning.md)（对齐）、[06](rules/06-quality.md)（影响面表） |
| 8 | 坑必须落成防复发机制；复发即升级；每日复盘 | [10](rules/10-lessons.md)、[06](rules/06-quality.md) |
| 9 | 改前备回滚；审计资产（账本、审查结论、ADR）永不删 | [11](rules/11-rollback.md)、[06](rules/06-quality.md) |
| 10 | 改任何 Skill 必须同步副本并核对报出结果 | [03](rules/03-skill-sync.md) |

## 分册索引

| 编号 | 分册 | 何时必读 |
| --- | --- | --- |
| 00 | [执行前必读](rules/00-core.md) | 每次会话开始 |
| 01 | [用户背景](rules/01-user-profile.md) | 每次会话开始 |
| 02 | [指令接收与交付清单（DoD）](rules/02-intake-and-dod.md) | 每次会话开始与每次交付 |
| 03 | [技能同步规则](rules/03-skill-sync.md) | 修改 skills/ 或 workflows/ 时 |
| 04 | [角色分工与子 Agent 派发](rules/04-roles-and-dispatch.md) | 派发子 Agent、拆解任务时 |
| 05 | [需求定义审查](rules/05-requirement-review.md) | 需求含财税判断或用户定义可能有误时 |
| 06 | [问题与决策质量](rules/06-quality.md) | 方案设计、审查、复盘时 |
| 07 | [待确认事项与交接](rules/07-pending-and-handoff.md) | 开工前汇总、会话交接时 |
| 08 | [对齐与版本管理](rules/08-alignment-and-versioning.md) | 任何文档/实现改动、提交推送时 |
| 09 | [经验沉淀与工作流](rules/09-precipitation.md) | 任务验收后 |
| 10 | [坑账本与避坑机制](rules/10-lessons.md) | 出坑、派发任务、复盘时 |
| 11 | [回滚机制](rules/11-rollback.md) | 任何改动前 |

## 规则库结构约定（双向链接）

- **修改或新增任何规则条款，一律属"重"级任务**，不适用"单份文档修订属轻"的豁免：须走对抗审查、留 ADR、按 D-1~D-6 交付。
- 每个分册首行必须有"归属总纲"链接，末尾必须有"相关分册"链接，保证**双向可回溯**。
- 链接一律用**标准 Markdown 相对路径**，不使用 `[[wikilink]]`（GitHub 与多数平台不渲染该语法）。
- 反向链接由 `scripts/link_check.sh` 扫描生成 [docs/BACKLINKS.md](docs/BACKLINKS.md)，并校验死链；**死链即拦截提交**。
- 新增分册必须同时：登记本索引表 + 在至少一个分册的"相关分册"中被引用；否则视为孤立文件，校验不通过。
- 体积红线：单分册超过 120 行须考虑再拆；本总纲超过 100 行须精简——防止总纲重新膨胀成巨石文件。

## 定时任务（仓库为真源，调度器为运行时副本）

- 任务定义真源：[schedules/daily-retro.md](schedules/daily-retro.md)（每日 00:00，Asia/Shanghai）。
- 调度器实例与真源不一致时，以真源为准并立即修正调度器；重建步骤与降级方案见该文件。
- 新增/修改定时任务，必须同步该文件并提交推送，不得只改调度器。

## 跨 Agent 使用（非 TRAE 环境必读）

- 其他 Agent（豆包、豆包工作、千问助手、DSH、WorkBuddy 等）取用本规则库前，必须先读 [docs/AGENT-ADAPTER.md](docs/AGENT-ADAPTER.md)。
- 核心要求：可按自身角色改名、按自身能力降级，但**不得改写规则原意、不得删除审计资产、不得把降级当合规**。
- 本规则库的通用层与项目层划分见 [AGENTS-GLOBAL.md](AGENTS-GLOBAL.md)。

## 变更与维护

- 改细则 → 改对应 `rules/` 分册；改结构 → 改本总纲并同步索引表，两者必须同一次提交。
- 任何改动按 [02 交付清单](rules/02-intake-and-dod.md) 的 D-1~D-6 交付，并走 [08 对齐与版本管理](rules/08-alignment-and-versioning.md) 的提交推送流程。
