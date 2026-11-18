# ADR-015：验证型外部 Agent 只读（禁止推送与上传）

- **日期**：2026-11-18
- **状态**：已接受
- **关联**：[ADR-011](ADR-011-no-auto-injection.md)（显式传递）、[ADR-014](ADR-014-session-start-selfcheck.md)（开工自检）；rules/03（技能同步）、rules/04（角色与派发）、rules/13（并发）

## 约束（用户业务决定，2026-11-18 口述）

- 豆包、豆包工作、千问助手、DSH、WorkBuddy 等外部 Agent 接入本规则库，目的是**实测规则能否被正确执行**，不是参与维护。
- 用户明确要求：这些 Agent 一律**不得把文档上传到 GitHub**，写入权只属主 Agent（TRAE）。
- 这是一条项目级限制，不是某台机器的环境约束。

## 决策

1. 外部验证型 Agent 的边界：**可**clone/pull/读取/试跑脚本/**本地 commit**（`md_check` 会拦未提交散改，不 commit 无法跑门禁）；**不可** push、开 PR、改远端分支或标签、上传任何文件。
2. 接入方式：HTTPS 匿名 clone，不配 deploy key / token / `gh auth login`，不安装 `.githooks`（`pre-push-check.sh` 会自动恢复推送凭据）。
3. 交付必报"未推送"，并附任务前后 `git ls-remote origin` 的 HEAD/分支快照；主 Agent 以此核验，而非只听自述。
4. `rules/03` 的"改 Skill 必须提交推送"收窄适用范围：推送义务只对有写权限的主 Agent 生效，外部 Agent 的本地适配不触发推送。
5. 外部 Agent 不认领 `docs/CLAIMS.md`，不计入并行参与者（rules/13 的"只读不写不触发"）。

## 否决项

| 方案 | 否决理由 |
| --- | --- |
| 只写"不要上传"一句 | 靠自觉，无核验动作；P-002 已证"靠人记必失效" |
| 禁止本地 commit | 与 `md_check` 冲突：存在未提交散改即拦，外部 Agent 将无法试跑门禁 |
| 靠"匿名 clone"就认为机械保证 | 环境里若已有 token/gh 登录/credential helper 仍可推；且 `.githooks` 会自动恢复密钥 |
| 进 AGENTS.md 新增第 12 条红线 | 总纲 99/100 行，只剩 1 行；改写现有"跨 Agent 使用"条目即可（ADR-004 预算约束） |
| 只改 S-004，不改 rules/03 | rules/03 第 14 行括注把"外部 Agent"列为需比对并报出同步结果者，会派生出推送义务 |

## 已知局限

- 公开仓库无法阻止任意第三方 fork、开 issue 或提 PR；本条只约束**自愿接入并配合验证**的 Agent。
- issue、gist、网页上传不在 git 视野内，只能靠"不带凭据"这一前置条件降低风险，无法事后从 git 侧发现。
- 主 Agent 只能核验远端分支/标签/提交是否新增，无法核验对方把文件传到了别处。

## 可推翻条件

1. 某外部 Agent 被用户单独授权写入——按 ADR 记录授权范围与时限，并在 S-004 增加该 Agent 的例外声明。
2. 将来出现可写权限的"协作型"外部 Agent（非验证用途）——需区分角色，另立条款。
3. 仓库转为私有并提供只读 token——可用 token 权限机械约束，届时可简化第 2 条。
