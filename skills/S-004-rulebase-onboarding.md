- 读本 skill 前先 git pull --ff-only origin main 并报出 commit；沉淀资产一律以仓库最新版为准，不凭记忆执行。
- **名称**：规则库接入（rulebase onboarding）
- **编号**：S-004
- **适用场景**：任何 Agent（豆包/千问/DSH/WorkBuddy/Claude Code 等）首次接入本规则库；或换工作区、换会话后确认规则是否真的生效
- **前置输入**：能执行 `git clone` 与读文件的工作区；本次任务的一句话目标
- **步骤**：见下方「执行步骤」，共 8 步，每步带判定
- **判定标准（验收）**：首条回复有加载声明；交付含 D-1~D-7；能复述金丝雀标记（证明读到文件）
- **触发词**：「怎么接入这个规则库」「新会话里规则好像没生效」「换了电脑还管用吗」「先把规矩读一遍再干活」「为什么你不记得我的要求了」「clone 下来按里面规则开工」「规则库怎么读」「确认一下规则真的加载了吗」「规则没加载怎么办」
- **不适用**：① 已在同源工作区、规则正常生效且无加载疑问 → 改走直接执行并按 `AGENTS.md` 行事；② 新项目要建骨架 → 改走 [S-002](S-002-project-bootstrap.md)；③ 需求还没成文 → 改走 [S-003](S-003-requirements-intake.md)
- **完成判据**：首条回复出现「已读：<文件清单>」或「未确认加载」；能复述 `AGENTS.md` 中的金丝雀标记；交付覆盖 `rules/15-delivery-dod.md` 的各项并附 `git rev-parse --short HEAD` 的 commit 号。
- **单一来源**：加载策略与预算阈值见 `rules/12-context-budget.md` 与 `scripts/budget.conf`（本文不复述数字），接入机制见 `docs/adr/ADR-011-no-auto-injection.md` 与 `docs/AGENT-ADAPTER.md`，交付清单见 `rules/15-delivery-dod.md`。
- **常见坑**：不 clone 就断言"机制失效"（P-016）；用摘要冒充已读；只改名不改规则
- **来源**：2026-11-18 三次盲测 + 端到端验证，见 [ADR-011](../docs/adr/ADR-011-no-auto-injection.md)
- **版本**：v1.3

## 为什么必须有这条 skill

- 本宿主**不自动注入**任何项目规则文件：`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`.cursorrules`、`.trae/rules` 三次盲测全部未生效（[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)）。
- 实测有效的组合是：**同源工作区（git clone）+ 开工令（显式要求读取并声明加载状态）**。缺任一环，会话表现为「未确认加载」。
- 金丝雀标记 `CANARY-TRAE-7F3A9C` 用于验证是否真读到文件：能复述 = 读到了这份副本；复述不出 = 没读到，不得假装。它**不证明宿主自动注入了规则**（[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)）。

## 核心区分：获取全量，读取分层（最容易做错）

| 动作 | 做法 | 理由 |
| --- | --- | --- |
| **获取 = 全量** | `git clone` 拿完整仓库，不挑文件 | 审计资产（PITFALLS、ADR、reports、审查结论）与 git 历史必须完整，缺了无法回滚与核对 |
| **读取 = 分层** | 常驻 `AGENTS.md` + `rules/00` + `01` + `02`；再按 `AGENTS.md` 路由表读相关 1~2 册；**禁止整库通读** | 整库通读会挤占上下文，反而降低质量，见 [rules/12](../rules/12-context-budget.md) |

## 执行步骤（每步带判定）

1. **确认同源**：当前目录须有 `AGENTS.md` 与 `rules/`；无则 `git clone https://github.com/douzichen/TRAE-project.git` 并进入目录。判定：两样都在 = 同源，进第 2 步。
2. **记录版本**：`git rev-parse --short HEAD`，把 commit 写进交付，便于回溯。判定：交付里能看到 commit 号。
3. **读常驻四件套**：`AGENTS.md`、`rules/00`、`01`、`02`，逐份读完。判定：有文件没读完或被截断，按「失败处理」声明。
4. **按路由表读相关 1~2 册**；交付类任务加读 [rules/15](../rules/15-delivery-dod.md)。判定：不整库通读。
5. **声明**：首条回复写「已读：<文件清单>」或「未确认加载」。判定：没有声明 = 未接入。
6. **金丝雀验证**（可选但推荐）：复述 `AGENTS.md` 中的 `CANARY-TRAE-7F3A9C`。判定：复述不出 → 视为未读该文件；复述得出只证明读到副本，不证明宿主加载。
7. **按自身能力适配**：只改第 4 节允许改的项，并逐项**声明降级**。
8. **交付自检**：按 `rules/15-delivery-dod.md` 的 D-1~D-7 逐项对照。

## 按自身调整清单

**必须按自身调整**（不改就会用错）

- ① 角色名/自称：换成你的角色体系，职责不变。
- ② 工具能力：无子 Agent 则声明"降级：无独立复审"，改用两个独立会话互审，不得自写自审。
- ③ 克隆目录的本地路径：把 `/workspace` 换成本机仓库根目录。
- ④ 定时/时区：有调度能力才建等价任务，无则标注"降级：会话内触发"。
- ⑤ 分册加载上限：上下文更小者少读，但 00/01/02 不可省。

**严禁改动**

- 规则原意、阈值数字（以 [scripts/budget.conf](../scripts/budget.conf) 为准）、审计资产（PITFALLS、ADR、reports、审查结论）、D-1~D-7 的项数。
- **推送权**：验证型 Agent 一律只读——可本地 commit 跑门禁，但禁止 `git push`、开 PR、上传任何文件到 GitHub；不装 `.githooks`（会自动恢复推送凭据）、不配 deploy key / token / `gh auth login`（用户明确限制，见 [rules/04](../rules/04-roles-and-dispatch.md)、[ADR-015](../docs/adr/ADR-015-validation-agents-readonly.md)）。

## 失败处理

- 读不到规则 → 首行写「未确认加载：含规则库」，不得以规则为名下任何结论。
- 工作区为空目录 → 先 clone 再重试，**不得误判为"机制失效"**（[P-016](../PITFALLS.md)）。
- 只读到摘要或部分文件 → 写「未完整读取：<文件清单>」并说明受限的判断范围。
- 平台差异 → 门禁脚本在 Linux 验证最充分；Windows/git-bash 报 `safe-delete`、盘符路径类错误时先按 [P-017](../PITFALLS.md) 核对脚本是否为相对路径，**不要直接 `--no-verify`**；报错按"平台 / 命令 / 退出码"三栏写进 D-5 可验证事实栏，作为门禁作者补第二平台证据的输入。
- 交付表述 → D-5 把"实际输出/退出码"与"根因推测"分栏写，推测必须注明"未确认"。

## 可直接粘贴的执行指令

```text
你是本规则库的协作 Agent。开工按顺序执行：
1. 确认同源与更新：当前目录须有 AGENTS.md 与 rules/；没有就先 git clone https://github.com/douzichen/TRAE-project.git 并进入目录；**已有副本先 git pull --ff-only origin main，落后就不得开工**（开工强制握手，[ADR-019](../docs/adr/ADR-019-startup-sync-gate.md)；锁定版本豁免见 rules/04-roles-and-dispatch.md），不要断言"机制失效"。
2. 先跑 sh scripts/session_start_check.sh（Windows 在 Git Bash 里跑——显式调用 Git Bash 自带的 bash.exe，勿依赖 PATH 中 bash 的默认解析，可能落到 WSL bash，豆包工作实测 2026-11-20；**若 `sh` 前缀报 exit 126 "cannot execute binary file"，属部分 MSYS2 运行时 stub 故障（P-027），改 `bash scripts/xxx.sh` 直接执行**），把输出整段贴进交付 D-5；再运行 git rev-parse --short HEAD 记录 commit。
3. 依次读完 AGENTS.md、rules/00-core.md、rules/01-user-profile.md、rules/02-intake-and-dod.md，再按 AGENTS.md 路由表读相关 1~2 册（交付任务加读 rules/15-delivery-dod.md），禁止整库通读。
4. 首条回复声明「已读：<文件清单>」或「未确认加载」，并复述金丝雀 CANARY-TRAE-7F3A9C；该串只证明副本内容，不证明宿主加载，真读以 D-1~D-7 产物为准。
5. 按 skills/S-004-rulebase-onboarding.md 做角色改名与能力适配，逐条声明降级（如"降级：无独立复审"）。
6. 交付按 D-1~D-7 逐项自检并附 commit 号；读不到规则时首行写「未确认加载：含规则库」，不得以规则为名下结论。
7. 只读边界：可本地 commit 以便跑门禁（**零改动只读验证无需 commit**——两档划分见 [AGENT-ADAPTER](../docs/AGENT-ADAPTER.md) 降级表，勿为凑门禁制造空提交，WorkBuddy 实测建议 2026-11-20），但禁止 git push、开 PR、上传任何文件到 GitHub；**每个新 clone 先执行 `git config --local credential.helper ""`（空值会重置**含 global 层**的 helper 列表——本机 GCM/缓存 token 同样被阻断，豆包工作 2026-11-20 实测其 global 挂 GCM 仍失败），再跑 `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main`，必须失败才算通过**——新副本没有这条设置时，全局凭据会重新生效；不装 .githooks、不配推送凭据；交付写「未推送」并附 git ls-remote origin 前后快照。
8. 跨项目边界：规则变更唯一入口是主会话 TRAE，你要改规则只能在交付里提建议，不得自行改库上传；自己的新项目仓库自建自管，项目代码与文档都可推入自己的项目仓；上传红线仅指向规则库，项目内容不得推入规则库；规则库更新后重拉时，首条回复报 git rev-parse --short HEAD。重拉以项目内只读干净副本为基，任务片边界才换规，混合体文件逐段合并、禁止整文件覆盖。
```

## 来源与相关分册

- 来源：[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)、[ADR-012](../docs/adr/ADR-012-gate-script-portability.md)、[P-016](../PITFALLS.md)、[P-017](../PITFALLS.md)
- 参见：[rules/12 上下文预算](../rules/12-context-budget.md)、[rules/15 交付反馈清单](../rules/15-delivery-dod.md)、[docs/AGENT-ADAPTER.md](../docs/AGENT-ADAPTER.md)
