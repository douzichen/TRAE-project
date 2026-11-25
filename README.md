# TRAE-project

财税业务项目的唯一仓库：业务文档、代码、脚本、过程规则同仓管理。仓库即权威副本，回滚与历史追溯均以本仓库为准。

## 目录结构

```text
/workspace
├── AGENTS.md              # 全局记忆【总纲与索引】：红线速查 + 分册入口（细则在 rules/）
├── rules/                 # 规则分册：一册一主题，首尾带双向链接，细则的唯一来源
│   ├── 00-core.md         # 执行前必读
│   ├── 01-user-profile.md # 用户背景（职业、技术边界、沟通偏好）
│   ├── 02-intake-and-dod.md # 指令复述与边界确认（交付反馈清单见 15 册）
│   ├── 03-skill-sync.md   # 技能同步规则
│   ├── 04-roles-and-dispatch.md # 角色分工与子 Agent 派发控制
│   ├── 05-requirement-review.md # 需求定义审查（含财税合规依据要求）
│   ├── 06-quality.md      # 问题与决策质量（分级、对抗审查、ADR、复盘）
│   ├── 07-pending-and-handoff.md # 待确认事项与交接五要素
│   ├── 08-alignment-and-versioning.md # 对齐红线与版本管理
│   ├── 09-precipitation.md # 经验沉淀与工作流
│   ├── 10-lessons.md      # 坑账本与避坑机制
│   ├── 11-rollback.md     # 回滚机制
│   ├── 12-context-budget.md # 上下文预算与按需加载
│   ├── 13-concurrency-and-lifecycle.md # 并发认领、裁决优先级与功能退役
│   ├── 14-project-bootstrap.md # 需求收集、项目创建、内网与数据红线
│   └── 15-delivery-dod.md # 交付反馈清单（D-1~D-7 细则与分级）
├── AGENTS-GLOBAL.md       # 跨项目长期记忆索引：权威来源、通用/特定层划分、新项目引导
├── README.md              # 本文件：目录结构与会话入口
├── CLAUDE.md / GEMINI.md  # 工具入口指针（由 scripts/tool_entrypoints.sh 生成）
├── .cursorrules           # Cursor 入口指针（由 scripts/tool_entrypoints.sh 生成）
├── .gitignore             # 排除上传件、密钥、依赖等不入库内容
│
├── schedules/             # 定时任务定义真源（调度器为运行时副本）
│   └── daily-retro.md     # 每日 00:00 复盘任务：cron、message 原文、重建与降级方案
│
├── skills/                # 单个可复用技能（一个技能一个文件）
│   ├── TEMPLATE.md        # 技能模板（复制后改名填写）
│   └── INDEX.md           # 技能索引（新建前先查，避免重复）
│
├── workflows/             # 技能串联而成的工作流
│   ├── TEMPLATE.md        # 工作流模板（含流程图）
│   ├── W-001-new-project.md # 需求收集 → PRD 冻结 → bootstrap → 骨架验收
│   └── INDEX.md           # 工作流索引
│
├── templates/             # 可直接复制的模板（填写后落到对应目录）
│   ├── RQ-CARD.md         # 需求卡片模板：编号、验收标准、例外与失败处理
│   ├── ADR-000-project-init.md # 新项目初始化决策模板（每个新项目复制一份）
│   ├── SESSION-START.md   # 新会话开工令：同源自检 → 读规则 → 读交接 → 声明加载状态
│   └── HANDOFF.md         # 交接快照模板（五要素），落到 docs/handoff/CURRENT.md
│
├── PITFALLS.md            # 坑账本：出坑即记账，落到防复发机制
├── reports/               # 三路独立审计报告目录（结构 / 可执行性 / 覆盖性）
│
├── prompts/               # 提问库：用户提供的提问法原文存档（规则正文在 rules/06-quality.md）
│   └── QUESTION-BANK.md   # 十条提问法原文 + 用户修订版 + 处置对照表
│
├── docs/                  # 项目文档
│   ├── AGENT-ADAPTER.md   # 跨 Agent 适配说明（豆包/千问/DSH/WorkBuddy 等取用前必读）
│   ├── CLAIMS.md          # 并行认领台账（认领人/范围/时间/状态，规则见 rules/13）
│   ├── BACKLINKS.md       # 反向链接索引（由 scripts/link_check.sh 自动生成）
│   ├── CONFLICT-MATRIX.md # 分册×分册冲突交叉表（人工维护，规则改动后必须更新）
│   ├── ROLE-SWITCH-CHECK.md # 跨 Agent 接入前置自查（5 问，AGENT-ADAPTER 开工前置条件）
│   ├── handoff/           # 交接快照：CURRENT.md 为唯一"当前交接"（规则见 rules/07）
│   └── adr/               # 决策记录：一条一文件，写清理由与否决项
│       ├── INDEX.md       # ADR 索引
│       ├── TEMPLATE.md    # ADR 模板
│       └── ADR-001-adopt-ten-prompts.md # 等 22 条（adr 目录实际文件数）
│
├── deploy-key.pub         # Deploy key 公钥档案（可入库；私钥在 .secrets/，永不入库）
│
├── scripts/               # 防复发自检脚本（挂 git hook 自动执行）
│   ├── md_check.sh        # pre-commit：INDEX 登记、坑编号连续、标题去重、关键分册防误删
│   ├── link_check.sh      # pre-commit：死链校验、双向链接结构、分册索引登记、生成反向链接
│   ├── session_start_check.sh # 新窗口开工自检（只读）：同源、版本、交接快照、金丝雀
│   ├── stale_terms_check.sh  # pre-commit：[M5] 口径漂移拦截，清单见 stale-terms.txt
│   ├── pre-push-check.sh  # pre-push：凭据自检与密钥自动恢复
│   ├── delivery_report.sh # pre-commit：每次提交生成交付反馈清单草稿（D-1/D-2/D-3/D-5）
│   ├── context_budget.sh  # pre-commit：最小必读集与分册行数预算校验
│   ├── threshold_check.sh # pre-commit：[M3] 阈值单一来源校验（阈值取自 budget.conf）
│   ├── paths_check.sh     # pre-commit：[M1] 裸路径存在性与可移植性（清单见 portable-deny.txt）
│   ├── claims_audit.sh    # pre-commit：[M4-a] CLAIMS.md 认领表格式校验
│   ├── pitfall_check.sh   # pre-commit：[M4-b] 坑账本必填字段（根因/状态/证据，缺失即阻断）
│   ├── skills_index_check.sh # pre-commit：[M6] 技能头部元数据校验（ADR-020）
│   ├── policy_guard.sh    # pre-commit：[D-7] 涉税/政策依据核验（ADR-010，告警模式）
│   ├── secrets_scan.sh    # pre-commit：密钥/敏感信息扫描
│   ├── metrics_collect.sh # pre-commit 末尾：只写 .git/metrics.log（TSV，不改工作区）；--flush 幂等并入 docs/METRICS.md
│   ├── closure_check.sh   # 手动闭合校验：included+ignored=total 且 total=baseline-vanished；无参跳过、--strict 才阻断
│   └── backup_snapshot.sh # 仓库父目录生成全量快照（含 .git），重大交付后手动执行（ADR-021）
│
├── .githooks/             # git hooks（core.hooksPath 指向此处）
│
└── .secrets/              # 本地密钥等敏感文件（已 gitignore，不入库）
```

> 脚本以 `sh` 为规范实现；同名的 PowerShell 版本（如 `scripts/closure_check.ps1`）仅为 Windows 辅助，结论须与 sh 版一致，不作为门禁依据。

## 各目录职责

| 目录 / 文件 | 职责 | 命名规则 |
| --- | --- | --- |
| `AGENTS.md` | 规则库**总纲与索引**：红线速查、分册入口、结构约定（细则在 `rules/`） | 固定名称，唯一 |
| `rules/` | 规则分册：一册一主题，细则的唯一来源，首尾双向链接 | `NN-<英文短名>.md` |
| `schedules/` | 定时任务定义真源（cron、message 原文、重建与降级方案） | `daily-<用途>.md` |
| `AGENTS-GLOBAL.md` | 跨项目长期记忆**索引**（不复制规则正文）：权威来源、通用/特定层划分、新项目四步引导 | 固定名称，唯一 |
| `README.md` | 目录说明与入口，回答"东西该放哪" | 固定名称，唯一 |
| `skills/` | 一个任务沉淀一个技能，含适用场景、步骤、验收 | `S-001-<英文短名>.md` |
| `workflows/` | 多个技能按顺序串成的主线路径，含流程图 | `W-001-<英文短名>.md` |
| `templates/` | 可直接复制的模板：需求卡片、新项目初始化决策、会话开工令、交接快照、执行路径卡（外部系统调用前置）；填写后落到对应目录，模板本身不放具体项目内容 | 固定名称，唯一 |
| `PITFALLS.md` | 坑账本：返工/退回/回滚即记账，每条必须落到防复发机制 | `P-001` 起编号，一条一节 |
| `docs/CLAIMS.md` | 并行认领台账：谁在改哪些文件/目录、预计何时结束；格式与生命周期规则见 `rules/13` | 固定名称，唯一 |
| `reports/` | 三路独立审计报告（结构 / 可执行性 / 覆盖性），属审计资产，不删除 | `A-`、`B-`、`C-` 前缀 |
| `CLAUDE.md` / `GEMINI.md` / `.cursorrules` | 各工具入口指针，指向总纲、最小必读集与 12 册，由脚本生成，不手改 | 固定名称，由 `scripts/tool_entrypoints.sh` 生成 |
| `deploy-key.pub` | Deploy key 公钥永久档案：GitHub 登记依据，环境丢失后凭此重新登记 | 固定名称，唯一 |
| `scripts/` | 防复发自检脚本，挂 pre-commit / pre-push hook 自动拦截（`metrics_collect.sh` 为非阻断度量、`backup_snapshot.sh` 为手动灾备，二者不拦截） | 一个检查一个脚本 |
| `.secrets/` | 密钥、凭据等本机文件 | 不入库、不写入任何文档 |
| `docs/`（业务文档待建） | PRD、FSFSD、MOC 索引、维护指南；交接快照已落在 `docs/handoff/CURRENT.md` | 项目启动后按文档规范建立 |
| `src/`（待建） | 业务代码与脚本 | 项目启动后按技术方案建立 |

## 新增内容怎么放

- 新增技能：复制 `skills/TEMPLATE.md` → 命名 `S-xxx-<短名>.md` → 在 `skills/INDEX.md` 登记。新建前先查索引，同类优先修订。
- 新增工作流：复制 `workflows/TEMPLATE.md` → 命名 `W-xxx-<短名>.md` → 在 `workflows/INDEX.md` 登记，并写明包含哪些 skill。
- 任务收尾：按 `AGENTS.md` 的沉淀触发点，明确写清"沉淀了什么 / 复用了哪个 / 为何无需沉淀"。
- 改规则：先查 `docs/CONFLICT-MATRIX.md` 的对应格子，改动后更新受影响单元格（否则视为未对账）。

## 当前状态

- 已有：规则库、目录骨架、索引与模板。
- 待启动：`docs/`（PRD、FSFSD 等）与 `src/`，等业务口径确认后按"口径先行—子 Agent 撰写—主 Agent 审查"流程建立。
