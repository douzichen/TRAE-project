# TRAE-project

财税业务项目的唯一仓库：业务文档、代码、脚本、过程规则同仓管理。仓库即权威副本，回滚与历史追溯均以本仓库为准。

## 目录结构

```text
/workspace
├── AGENTS.md              # 全局记忆（规则库，铁律，执行前必读）
├── AGENTS-GLOBAL.md       # 跨项目长期记忆索引：权威来源、通用/特定层划分、新项目引导
├── README.md              # 本文件：目录结构与会话入口
├── .gitignore             # 排除上传件、密钥、依赖等不入库内容
│
├── skills/                # 单个可复用技能（一个技能一个文件）
│   ├── TEMPLATE.md        # 技能模板（复制后改名填写）
│   └── INDEX.md           # 技能索引（新建前先查，避免重复）
│
├── workflows/             # 技能串联而成的工作流
│   ├── TEMPLATE.md        # 工作流模板（含流程图）
│   └── INDEX.md           # 工作流索引
│
├── PITFALLS.md            # 坑账本：出坑即记账，落到防复发机制
│
├── prompts/               # 提问库：用户提供的提问法原文存档（规则正文在 AGENTS.md）
│   └── QUESTION-BANK.md   # 十条提问法原文 + 用户修订版 + 处置对照表
│
├── docs/                  # 项目文档
│   └── adr/               # 决策记录：一条一文件，写清理由与否决项
│       ├── INDEX.md       # ADR 索引
│       ├── TEMPLATE.md    # ADR 模板
│       └── ADR-001-adopt-ten-prompts.md
│
├── deploy-key.pub         # Deploy key 公钥档案（可入库；私钥在 .secrets/，永不入库）
│
├── scripts/               # 防复发自检脚本（挂 git hook 自动执行）
│   ├── md_check.sh        # pre-commit：INDEX 登记、坑编号连续、标题去重
│   ├── pre-push-check.sh  # pre-push：凭据自检与密钥自动恢复
│   └── delivery_report.sh # pre-commit：每次提交生成交付反馈清单草稿（D-1/D-2/D-3/D-5）
│
├── .githooks/             # git hooks（core.hooksPath 指向此处）
│
└── .secrets/              # 本地密钥等敏感文件（已 gitignore，不入库）
```

## 各目录职责

| 目录 / 文件 | 职责 | 命名规则 |
| --- | --- | --- |
| `AGENTS.md` | 长期规则库：分工、对齐红线、交接、沉淀等铁律 | 固定名称，唯一 |
| `AGENTS-GLOBAL.md` | 跨项目长期记忆**索引**（不复制规则正文）：权威来源、通用/特定层划分、新项目三步引导 | 固定名称，唯一 |
| `README.md` | 目录说明与入口，回答"东西该放哪" | 固定名称，唯一 |
| `skills/` | 一个任务沉淀一个技能，含适用场景、步骤、验收 | `S-001-<英文短名>.md` |
| `workflows/` | 多个技能按顺序串成的主线路径，含流程图 | `W-001-<英文短名>.md` |
| `PITFALLS.md` | 坑账本：返工/退回/回滚即记账，每条必须落到防复发机制 | `P-001` 起编号，一条一节 |
| `deploy-key.pub` | Deploy key 公钥永久档案：GitHub 登记依据，环境丢失后凭此重新登记 | 固定名称，唯一 |
| `scripts/` | 防复发自检脚本，挂 pre-commit / pre-push hook 自动拦截 | 一个检查一个脚本 |
| `.secrets/` | 密钥、凭据等本机文件 | 不入库、不写入任何文档 |
| `docs/`（待建） | PRD、FSFSD、交接文档、MOC 索引、维护指南 | 项目启动后按文档规范建立 |
| `src/`（待建） | 业务代码与脚本 | 项目启动后按技术方案建立 |

## 新增内容怎么放

- 新增技能：复制 `skills/TEMPLATE.md` → 命名 `S-xxx-<短名>.md` → 在 `skills/INDEX.md` 登记。新建前先查索引，同类优先修订。
- 新增工作流：复制 `workflows/TEMPLATE.md` → 命名 `W-xxx-<短名>.md` → 在 `workflows/INDEX.md` 登记，并写明包含哪些 skill。
- 任务收尾：按 `AGENTS.md` 的沉淀触发点，明确写清"沉淀了什么 / 复用了哪个 / 为何无需沉淀"。

## 当前状态

- 已有：规则库、目录骨架、索引与模板。
- 待启动：`docs/`（PRD、FSFSD 等）与 `src/`，等业务口径确认后按"口径先行—子 Agent 撰写—主 Agent 审查"流程建立。
