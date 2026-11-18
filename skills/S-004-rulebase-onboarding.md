---
- **名称**：规则库接入（rulebase onboarding）
- **编号**：S-004
- **适用场景**：任何 Agent（豆包/千问/DSH/WorkBuddy/Claude Code 等）首次接入本规则库；或换工作区、换会话后确认规则是否真的生效
- **前置输入**：能执行 `git clone` 与读文件的工作区；本次任务的一句话目标
- **步骤**：见下方「执行步骤」，共 8 步，每步带判定
- **判定标准（验收）**：首条回复有加载声明；交付含 D-1~D-7；能复述金丝雀标记
- **常见坑**：不 clone 就断言"机制失效"（P-016）；用摘要冒充已读；只改名不改规则
- **来源**：2026-11-18 三次盲测 + 端到端验证，见 [ADR-011](../docs/adr/ADR-011-no-auto-injection.md)
- **版本**：v1.0

## 为什么必须有这条 skill

- 本宿主**不自动注入**任何项目规则文件：`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`.cursorrules`、`.trae/rules` 三次盲测全部未生效（[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)）。
- 实测有效的组合是：**同源工作区（git clone）+ 开工令（显式要求读取并声明加载状态）**。缺任一环，会话表现为「未确认加载」。
- 金丝雀标记 `CANARY-TRAE-7F3A9C` 用于验证是否真读到：能复述 = 读到；复述不出 = 没读到，不得假装。

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
6. **金丝雀验证**（可选但推荐）：复述 `AGENTS.md` 中的 `CANARY-TRAE-7F3A9C`。判定：复述不出 → 视为未读。
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
1. 确认同源：当前目录须有 AGENTS.md 与 rules/；没有就先 git clone https://github.com/douzichen/TRAE-project.git 并进入目录，不要断言"机制失效"。
2. 运行 git rev-parse --short HEAD，把 commit 写进交付。
3. 依次读完 AGENTS.md、rules/00-core.md、rules/01-user-profile.md、rules/02-intake-and-dod.md，再按 AGENTS.md 路由表读相关 1~2 册（交付任务加读 rules/15-delivery-dod.md），禁止整库通读。
4. 首条回复声明「已读：<文件清单>」或「未确认加载」；能复述金丝雀 CANARY-TRAE-7F3A9C 才算真读。
5. 按 skills/S-004-rulebase-onboarding.md 做角色改名与能力适配，逐条声明降级（如"降级：无独立复审"）。
6. 交付按 D-1~D-7 逐项自检并附 commit 号；读不到规则时首行写「未确认加载：含规则库」，不得以规则为名下结论。
7. 只读边界：可本地 commit 以便跑门禁，但禁止 git push、开 PR、上传任何文件到 GitHub；不装 .githooks、不配推送凭据；交付写「未推送」并附 git ls-remote origin 前后快照。
```

## 来源与相关分册

- 来源：[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)、[ADR-012](../docs/adr/ADR-012-gate-script-portability.md)、[P-016](../PITFALLS.md)、[P-017](../PITFALLS.md)
- 参见：[rules/12 上下文预算](../rules/12-context-budget.md)、[rules/15 交付反馈清单](../rules/15-delivery-dod.md)、[docs/AGENT-ADAPTER.md](../docs/AGENT-ADAPTER.md)
