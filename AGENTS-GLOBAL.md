# AGENTS-GLOBAL（跨项目长期记忆 · 全局规则索引）

> 目的：把"方法论铁律"从单个项目带出来，跨项目复用。
> 单一事实源原则：本文件只是**索引与引导**，不复制规则正文。规则正文的唯一权威版本是本仓库的 `AGENTS.md`——防止两份正文漂移（对齐红线）。

## 权威来源

- 仓库：`https://github.com/douzichen/TRAE-project.git`
- 规则正文：仓库根目录 [AGENTS.md](AGENTS.md)
- 坑账本：仓库根目录 [PITFALLS.md](PITFALLS.md)
- 派发模板：[skills/S-001-subagent-dispatch.md](skills/S-001-subagent-dispatch.md)

## 通用层与项目特定层划分

| 层 | 内容 | 跨项目复用方式 |
| --- | --- | --- |
| 通用层 | 执行前必读、技能同步规则、记忆收录说明、子会话约束传递、接管规矩（口径先行—子写—主审）、待确认事项、交接五要素、对齐红线、子 Agent 执行控制、文档一致性维护、版本管理与历史留存、经验沉淀、坑账本机制、回滚机制 | 原文照搬，一个字不改 |
| 通用层（规则 14） | 项目创建与需求收集：[rules/14-project-bootstrap.md](rules/14-project-bootstrap.md)（R1~R6 需求收集、A1~A8 项目创建、内网与数据红线） | 原文照搬，一个字不改 |
| 项目特定层 | 项目路径（`/workspace/...`）、PITFALLS 中环境特定条目（如 P-001 密钥机制）、Deploy key 与凭据 | 按新项目实际情况改写 |

## 新项目引导（bootstrap，三步）

1. **取规则**：clone 本仓库（或由用户将 AGENTS.md 正文导入新项目环境）。
2. **落位**：AGENTS.md 放到新项目根目录作为规则库；按新项目改写"项目特定层"，通用层原文不动。
3. **装门禁**：复制 `scripts/` 与 `.githooks/`，执行 `git config core.hooksPath .githooks`，跑 `sh scripts/md_check.sh` 验证通过后再开工。

## 使用纪律

- 任何新项目/新会话开工：先读 AGENTS.md 全文再动手——这条本身即通用层第一规则。
- 全局规则的修订只在本权威仓库进行；其他项目的副本一律视为镜像，改镜像视为违规（与技能同步规则同理）。
- 长期记忆的持久物理载体只有两处：本环境 `/workspace` 与 GitHub 远端。对话上下文、家目录 `~` 均不持久（P-001 已证），不得作为记忆载体。
