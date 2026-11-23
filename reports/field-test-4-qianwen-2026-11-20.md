# 规则库接入实测报告（第四棒 · 千问）

> 验证 Agent：千问工作助理（外部协作验证型，只读）
> 实测日期：2026-11-20
> 仓库：`https://github.com/douzichen/TRAE-project.git`
> 本地副本：`D:/Documents/qwen-agent/3lg9yo4hhw/TRAE-project`
> 记录 commit：**`87d1878`**（完整 `87d18783a8a29b0d19daeac0b84b827631057be8`）
> 提交时间：2026-11-20 12:27:04 +0800
> 运行环境：Windows 11 Pro 10.0.22631；bash 5.3.20（千问内置 MSYS2 运行时）；git 2.55.0.windows.5

---

## 一、加载声明与探针题

### 1.1 加载声明

**已读**：`AGENTS.md`、`rules/00-core.md`、`rules/01-user-profile.md`、`rules/02-intake-and-dod.md`、`docs/AGENT-ADAPTER.md`、`docs/ROLE-SWITCH-CHECK.md`、`skills/S-004-rulebase-onboarding.md`、`AGENTS-GLOBAL.md`（「通用层与项目特定层划分」「跨项目运行模型」两节）、`rules/04-roles-and-dispatch.md`、`rules/15-delivery-dod.md`、`rules/12-context-budget.md`（补读，用于第 5 问与读取完整性声明）、`skills/S-005-absence-delegation-blueprint.md`（仅名称行与「不适用」节，用于效力判定）、`docs/adr/ADR-022`（结论段）。

已加载分册：00 / 01 / 02 / 04 / 12 / 15。

未完整读取（按 rules/12 声明）：`PITFALLS.md`（全文 47KB，仅按需引用 P-016/P-017/P-025/P-026 相关表述）、`docs/adr/` 其余 21 份 ADR（仅取 ADR-022 结论段）、`rules/03/05/06/07/08/09/10/11/13/14`、`workflows/`。受限判断范围：涉及这些分册的具体条款细节不作结论；本报告结论仅覆盖接入链路与只读红线，不覆盖维护流程细则。

### 1.2 金丝雀标记复述

**`CANARY-TRAE-7F3A9C`**

来源：`AGENTS.md:99`（总纲末行「金丝雀标记」）；`scripts/session_start_check.sh` 运行时亦输出同一串。按 ADR-011 与 AGENTS-GLOBAL「金丝雀验证」，此串**只证明我读到了这份副本的内容，不证明宿主自动注入了规则**。

### 1.3 探针题答案

**第 1 题：开工第 0 步应执行仓库里的哪个脚本？**

`scripts/session_start_check.sh`。依据：`rules/02-intake-and-dod.md:22`（新会话第一条命令即执行该脚本，ADR-014）、`skills/S-004` 执行指令第 2 条。退出码含义：1＝缺文件/金丝雀缺失，2＝版本未核对，3＝本地落后远端须先 `git pull --ff-only` 再开工（ADR-019）。

**第 2 题：AGENTS.md 末尾的金丝雀标记是什么？**

`CANARY-TRAE-7F3A9C`。

---

## 二、角色切换自检（ROLE-SWITCH-CHECK 五问，逐条作答）

**问 1：本次任务由谁「撰写」、谁「审查」？两者是否为同一会话/同一 Agent？**

撰写：本会话（千问，单一 Agent 完成 clone、脚本执行、判读与报告成文）。审查：本会话先按 rules/15 D-1~D-7 逐项自检；**独立复审由维护者（用户/TRAE 主会话）承接**。撰写与初步审查确为同一 Agent。

**问 2：若为同一 Agent，是否已开第二个独立会话复审？若不能，是否标注「降级：未独立复审」？**

未开第二个独立会话。理由：本任务性质是「验证型 Agent 自证自己刚跑出的终端事实」，第二会话拿不到我的会话内终端记录，只能重跑一遍，属重复执行而非独立复审，对判读错误无鉴别力；且 rules/04「验证型 Agent 只读」明确外部 Agent 不参与主线维护，复审权在维护者。**标注：降级——未独立复审，复审由维护者承接。**

**问 3：你是否有子 Agent 能力？没有时如何拆分「生产」与「审查」？**

有子 Agent 能力（可派发独立上下文的子任务，但子 Agent 不继承本会话上下文，深度上限 1 层）。本次未启用，理由同问 2。ADR-022 否决项 ③「能力超配由 Agent 自判启用独立复审」已裁定维持现状、观察关闭，故本处理与现行裁定一致。

**问 4：你的交付里是否包含 D-1~D-7（或按 AGENT-ADAPTER 声明的降级项）？**

包含，见本报告第六节，七项齐全，无推延。

**问 5：你是否已按 rules/12 声明「未完整读取」的文件？**

已声明，见 1.1 末段。常驻四件套（AGENTS.md + 00 + 01 + 02）逐份完整读完，无截断。

---

## 三、接入 8 步逐步记录（S-004）

| 步 | 内容 | 结果 | 证据位置 |
| --- | --- | --- | --- |
| 1 | 确认同源（无则 clone） | 直接可执行 | 3.1 |
| 2 | 记录版本 commit | 直接可执行 | 3.2 |
| 3 | 读常驻四件套 | 直接可执行 | 3.3 |
| 4 | 按路由表读相关册 | 直接可执行 | 3.4 |
| 5 | 加载声明 | 直接可执行 | 本报告 1.1 |
| 6 | 金丝雀验证 | 直接可执行 | 本报告 1.2 |
| 7 | 按能力适配、声明降级 | **部分降级**（见 3.7） | 3.7 |
| 8 | D-1~D-7 交付自检 | 直接可执行 | 第六节 |

### 3.1 第 1 步：确认同源（直接可执行）

开工前探测：目标目录为空目录，无 `.git`，故按 S-004 判定「非同源」→ clone。

命令与输出：

```
$ ls -la D:/Documents/qwen-agent/3lg9yo4hhw/TRAE-project
total 0
drwxr-xr-x 1 <user> None 0 Nov 20 12:31 .
drwxr-xr-x 1 <user> None 0 Nov 20 12:31 ..
$ ls -d D:/Documents/qwen-agent/3lg9yo4hhw/TRAE-project/.git
ls: cannot access '.../.git': No such file or directory

$ git clone https://github.com/douzichen/TRAE-project.git .
Cloning into '.'...
---EXIT=0---
```

判定：clone 成功，`AGENTS.md` 与 `rules/` 均在（见 3.2 目录清单）＝同源，进第 2 步。

补充：因本次为首次 clone，`git pull --ff-only origin main` 无对象；clone 即等价于取到远端最新（本地 HEAD 与远端 main 一致，见 3.2）。

### 3.2 第 2 步：记录版本（直接可执行）

```
$ git rev-parse --short HEAD
87d1878
$ git log -1 --date=iso --pretty="%H%n%ad%n%s"
87d18783a8a29b0d19daeac0b84b827631057be8
2026-11-20 12:27:04 +0800
chore(reports): 删除误建临时文件 _tmp_check.md（上轮 shell fallback 分支误产生的 field-test-2 重复副本，非审计资产，提交信息注明）
$ git branch -vv
* main 87d1878 [origin/main] chore(reports): 删除误建临时文件 _tmp_check.md（...）
$ git status --porcelain
（空）
```

开工自检脚本 `scripts/session_start_check.sh` 整段输出（原样保留）：

```
[SESSION] 仓库根：D:/Documents/qwen-agent/3lg9yo4hhw/TRAE-project
[SESSION] 存在：AGENTS.md
[SESSION] 存在：rules/00-core.md
[SESSION] 存在：rules/01-user-profile.md
[SESSION] 存在：rules/02-intake-and-dod.md
[SESSION] 当前分支：main
[SESSION] 本地 HEAD：87d1878
[SESSION] 远端 main：87d1878｜落后 0｜领先 0
[SESSION] hooksPath 未设为 .githooks：本地门禁不会自动运行（验证型 Agent 未装 hook 属合法状态；维护者主会话须先 git config core.hooksPath .githooks）
[SESSION] 交接快照：afa5f6e docs(adr): ADR-022 实测排班三棒收口——接入可行成立、红线全达成；Codex 有条件通过(2缺口记P-026)；否决PowerShell回退/helper通用化/能力超配改条款；降级表禁自建模拟脚本；第三棒报告入库
[SESSION] 交接快照距今 1 个提交（仅供参考：快照按交付更新，不构成失败）
[SESSION] 金丝雀可见：CANARY-TRAE-7F3A9C（首条回复须复述；仅证明副本内容，不证明宿主加载）
[SESSION] 自检通过：可以开工（本次未改工作区）
---EXIT=0---
```

判定：退出码 0＝自检通过；落后 0＝无需 pull（ADR-019 满足），可开工。

**关于脚本调用方式的平台事实（重要，非失败）**：本次按任务要求在 Windows 上**显式使用绝对路径的 bash 解释器**调用脚本，未依赖 PATH 默认解析：

```
调用器：C:/Users/<user>/AppData/Local/Qianwen/User Data/qwen-agent/resources/components/bash/versions/5.3.20.2/usr/bin/bash.exe
调用形式：<上述绝对路径> scripts/session_start_check.sh
```

本机无独立 Git Bash 安装（`C:/Program Files/Git/bin/bash.exe` 与 `usr/bin/bash.exe` 均不存在）。`git` 位于 `/git/cmd/git`，与 bash 同属千问内置 MSYS2 运行时（`cygpath -w /git` → `...components\bash\versions\5.3.20.2\git`）。系统存在 `wsl.exe`，本次**全程未使用**，已通过绝对路径调用规避「PATH 落到 WSL bash」的风险（该风险即 S-004 第 2 条与豆包工作 2026-11-20 实测所指）。

### 3.3 第 3 步：读常驻四件套（直接可执行）

`AGENTS.md`（100 行内，实读 99 行）、`rules/00-core.md`（15 行）、`rules/01-user-profile.md`（18 行）、`rules/02-intake-and-dod.md`（27 行）逐份完整读取，无截断、无跳读。

### 3.4 第 4 步：按路由表读相关册（直接可执行）

按 AGENTS.md 路由表加读：`rules/04`（角色分工与派发 → 只读边界）、`rules/15`（交付 D-1~D-7）。另按任务指定读 `docs/AGENT-ADAPTER.md`（先读第〇节效力分层）、`docs/ROLE-SWITCH-CHECK.md`、`skills/S-004`、`AGENTS-GLOBAL.md` 两节。为回答第 5 问与完整性声明，补读 `rules/12`。**未整库通读**。

### 3.5 第 5 步：声明（直接可执行）

见 1.1。

### 3.6 第 6 步：金丝雀验证（直接可执行）

见 1.2。

### 3.7 第 7 步：按能力适配与降级声明（部分降级）

三条降级，逐条量化缺口与风险承接方：

| # | 降级项 | 缺哪项检查/能力 | 风险由谁承接 |
| --- | --- | --- | --- |
| 1 | git hook 未安装 | 本地 pre-commit / pre-push 全链 11 项门禁不自动运行 | 本 Agent 手工跑零改动档两项（`md_check.sh`、`link_check.sh`）并附输出（见 3.8）；其余 9 项在零改动下无对象，风险＝「手工漏跑」由维护者在入库前复核承接 |
| 2 | 未独立复审 | 无第二独立执行者交叉验证判读 | 由维护者承接（见第二节问 2） |
| 3 | 无定时调度等价任务 | 本次任务不涉及每日复盘等定时项 | 不适用（本次未触发该场景），如后续需要由维护者的调度器承接 |

**未降级项**：git 能力（clone / pull 判定 / rev-parse / ls-remote / config / push --dry-run）全部具备并实际执行；脚本执行能力具备并实际执行；文件读取能力具备。**未使用自建模拟脚本替代任何门禁**（AGENT-ADAPTER 降级表 bash 行、ADR-022 硬要求）。

### 3.8 门禁执行记录（零改动档）

按 AGENT-ADAPTER 降级表：零改动只读验证跑 `md_check.sh` + `link_check.sh`。实际另跑 5 项零副作用校验作加强。

**卡住项（按「平台 / 命令 / 退出码」三栏）**：

| 平台 | 命令 | 退出码 |
| --- | --- | --- |
| Windows 11 + 千问内置 MSYS2 bash 5.3.20 | `bash.exe sh scripts/md_check.sh`（以 `sh` 作为解释器前缀） | **126**，报错 `/usr/bin/sh: /usr/bin/sh: cannot execute binary file` |

同上，`bash.exe sh scripts/link_check.sh` 亦为 126、同报错。

根因推测（**未确认**）：本 MSYS2 运行时的 `sh` 转发程序与该 bash 版本不匹配，`sh` 无法作为解释器被 `exec`；脚本本身 `#!/bin/sh` 头完好。

绕过方式（等价、非模拟）：去掉 `sh` 前缀，用 bash 直接执行脚本文件。全部通过：

```
$ bash.exe scripts/md_check.sh
[P-004] md 完整性校验通过
---EXIT=0---

$ bash.exe scripts/link_check.sh
[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md
---EXIT=0---
```

加强项：

```
$ bash.exe scripts/context_budget.sh
[P-010] AGENTS.md = 99 行
[P-010] rules/00-core.md = 15 行
[P-010] rules/01-user-profile.md = 18 行
[P-010] rules/02-intake-and-dod.md = 27 行
[P-010] 最小必读集合计 159 行（上限 160）
[P-010] 上下文预算校验通过（必读集 159/160｜总纲 99/100｜单册上限 120）
---EXIT=0---

$ bash.exe scripts/threshold_check.sh
[M3] 阈值单一来源校验通过（必读集 160 / 单册 120 / 总纲 100）
---EXIT=0---

$ bash.exe scripts/claims_audit.sh
[M4] 认领表审计通过
---EXIT=0---

$ bash.exe scripts/pitfall_check.sh
[M4] 坑账本字段审计通过（P-026 等共 26 条）
---EXIT=0---

$ bash.exe scripts/skills_index_check.sh
[SKILL-META] 技能元数据校验通过
---EXIT=0---

$ bash.exe scripts/secrets_scan.sh
[SECRET] 无待检查改动
---EXIT=0---

$ bash.exe scripts/policy_guard.sh
[D-7] 无暂存 Markdown 改动，依据核验跳过
---EXIT=0---
```

注：`link_check.sh` 声明「已刷新 docs/BACKLINKS.md」，但随后 `git status --porcelain` 为空，说明刷新为幂等、内容零变化——**零改动状态未被破坏**。

未跑并说明原因：`delivery_report.sh`（依赖提交对象生成 D 草稿，零改动无对象）、`pre-push-check.sh`（会向 `~/.ssh` 恢复密钥与写配置，属推送凭据动作，本 Agent 禁止）、`backup_snapshot.sh`、`metrics_collect.sh`、`tool_entrypoints.sh`（本次任务无对应场景）。

### 3.9 第 8 步：交付自检

见第六节。

---

## 四、只读红线自证

### 4.1 红线条 3：credential helper 置空 + 干跑必须失败

```
$ git config --local credential.helper ""
EXIT=0

$ git config --local --get credential.helper
（空行，值即空串）
EXIT=0

$ git config --get-all credential.helper
manager
EXIT=0

$ git config --show-origin --get-all credential.helper
file:C:/Users/<user>/AppData/Local/Qianwen/User Data/qwen-agent/resources/components/bash/versions/5.3.20.2/git/etc/gitconfig    manager
file:.git/config
```

说明：系统级 gitconfig 确实挂着 `manager`（GCM）；`--local` 置空后，`.git/config` 中为 `helper =`（空值）。`.git/config` 片段：

```
[credential]
	helper = 
```

干跑结果（**必须失败**，已按要求失败）：

```
$ GIT_TERMINAL_PROMPT=0 git push --dry-run origin main
fatal: could not read Username for 'https://github.com': terminal prompts disabled
---EXIT=128---
```

判定：**通过**。失败形态与 ADR-022 否决项 ② 的实证一致——local 空值重置了含 global 层的 helper 列表，GCM 缓存 token 同样被阻断，无凭据可自动取用。

### 4.2 红线条 4：未推送 + 前后 ls-remote 快照

**任务前快照**（clone 完成后、任何门禁执行前）：

```
$ git ls-remote origin
87d18783a8a29b0d19daeac0b84b827631057be8	HEAD
87d18783a8a29b0d19daeac0b84b827631057be8	refs/heads/main
cc0ce9a0800a941c1c5ac477c0e10e19ca667e78	refs/tags/pre-skill-meta
b1c78d611ef548d3c92b2cefe2f1c7622d84f255	refs/tags/pre-skill-meta^{}
---EXIT=0---
```

**任务后快照**：

```
$ git ls-remote origin
87d18783a8a29b0d19daeac0b84b827631057be8	HEAD
87d18783a8a29b0d19daeac0b84b827631057be8	refs/heads/main
cc0ce9a0800a941c1c5ac477c0e10e19ca667e78	refs/tags/pre-skill-meta
b1c78d611ef548d3c92b2cefe2f1c7622d84f255	refs/tags/pre-skill-meta^{}
---EXIT=0---
$ git rev-parse --short HEAD
87d1878
$ git rev-list --left-right --count HEAD...origin/main
0	0
```

判定：前后快照**逐字节一致**（HEAD、main、两个 tag 引用全部未变）；本地领先 0、落后 0。**结论：未推送。**

### 4.3 红线条 1、2：零改动、不装钩子、不配凭据

```
$ git status --porcelain
（空，全程多次复核均为空）
$ git config --get core.hooksPath
（无输出）EXIT=1  → 未设为 .githooks，钩子未启用
$ ls .githooks
pre-commit
pre-push
```

`.githooks` 存在但仅作为仓库自带文件，**未安装、未启用**；未执行 `gh auth login`，未配置 deploy key / token，未改动 `~/.ssh`，全程未执行 `git add` / `git commit` / `git push` / `gh pr`。未认领 `docs/CLAIMS.md`，未参与并行协议。

---

## 五、效力分层自证（按 AGENT-ADAPTER 第〇节）

| 效力类型 | 本仓库位置 | 我的处理 | 本轮实际动作 |
| --- | --- | --- | --- |
| 生效条款 | `AGENTS.md`、`rules/` 各分册 | 遵守 | 按 00/01/02 行事；按路由表加读 04/15；复述与边界确认先做；D-1~D-7 全量给 |
| 决策存档 | `docs/adr/` | 只看裁定状态，被否决项不当机制 | 引 ADR-022 结论段：否决 PowerShell 回退、否决 helper 可跳过、否决「能力超配自判」改条款——本轮**均未按其行事**；ADR-019 落后不得开工＝照做（落后 0 才开工） |
| 评审存档蓝图 | `skills/S-005`（名称行自带「评审存档，供新项目复用」，不适用节写明本库终局裁定不建） | **不按其实施** | 仅确认其「不适用：①本规则库本体——已终局裁定不建（ADR-021）」；**未建立任何缺席委托/代批文件**，未按七字段、未启用任何代批标签 |
| 模板与索引 | `templates/`、各 `INDEX.md` | 只作检索入口 | 用 `skills/INDEX.md`、`workflows/INDEX.md` 定位，未从中取条款 |
| 环境特定条目 | `PITFALLS.md` 沙箱相关条目 | 无对应条件不照搬 | 未在沙箱内跑 `pre-push-check.sh`（其功能是恢复 `~/.ssh` 密钥与写 SSH 配置，本平台无该 .secrets 机制，且属推送凭据动作，按第三节降级表声明缺能力） |

另：`scripts/pre-push-check.sh` 源码显示其会向 `~/.ssh` 写入 `id_ed25519`、`config`（含 ProxyCommand 与代理端口）。这属「自动恢复推送凭据」机制，与 rules/04 对验证型 Agent 的禁止项直接相关，**故本 Agent 不执行该脚本**，不视为漏跑。

---

## 六、D-1~D-7 逐项汇报

### D-1 规则改动的交付分级

**规则库未改动，无全文义务。** 本轮为纯读取验证，`AGENTS.md` 及 `rules/` 全部 16 册零改动（`git status --porcelain` 全程为空可证）。故不进入重级/轻级分级，无「新增段落原文 + 全文」或「改动段落 + 行号」义务。

### D-2 改动清单

**逐文件：本轮未改动任何仓库文件。** `git status --porcelain` 在 clone 后、门禁跑完后、报告成文前三次复核均为空输出。唯一在仓库外的产物是本报告文件（位于 `D:/Documents/qwen-agent/3lg9yo4hhw/`，即仓库父目录，不在版本控制内）。

对 `.git/config` 的写入只有一项：`credential.helper` 置空（红线条 3 强制要求）。此为本机配置，不属被 Git 跟踪的文件，不改变任何文件内容，不影响仓库一致性。

### D-3 对账结果

| 文档 | 是否需改动 | 结论 |
| --- | --- | --- |
| `AGENTS.md` | 否 | 零改动验证，总纲摘要与各分册无冲突需修正；未触发「摘要与分册冲突即以分册为准」条款 |
| `AGENTS-GLOBAL.md` | 否 | 读了两节（通用层/项目层划分、跨项目运行模型），内容与 `rules/04`、`rules/01` 表述一致，无漂移 |
| `README.md` | 否 | 未改动任何命令或目录，无需同步 |
| `PITFALLS.md` | 否 | 本次发现的可沉淀项（`sh` 前缀调用 126）**建议由维护者入账**，我不改文件（详见 7.1 建议 1） |
| `skills/INDEX.md` | 否 | 未增删 skill，索引无需变 |
| `workflows/INDEX.md` | 否 | 未增删 workflow，索引无需变 |
| `docs/BACKLINKS.md` | 否 | `link_check.sh` 幂等刷新后 `git status` 仍为空，内容零变化 |
| `docs/adr/` | 否 | 本次为验证不改规则，不产生新 ADR；如维护者采纳建议 1，则需按重级流程补 ADR/PITFALLS，属维护者动作 |

### D-4 记忆收录说明

**本轮不写入任何记忆条目。** 逐类理由：

- **不写**：本次 clone 路径、commit 号、门禁输出等——属一次性任务细节与可随时重新取证的运行事实，按 rules/04「不写：一次性举例、具体某次任务细节」处理。落点：无。
- **不写**：规则条款内容——条款唯一权威在仓库 `rules/`，写入个人记忆会产生第二份正文，违反 AGENTS-GLOBAL「事实唯一出处表」与对齐红线。落点：无。
- **不写**：用户职业与沟通偏好——`rules/01` 已是唯一权威出处，重复记录会导致漂移。落点：无。
- **不写**：本轮发现的 `sh` 调用问题——属机制性内容，正确落点是 `PITFALLS.md`（维护者写入口），不是我的记忆。落点：无（改以建议形式提交，见 7.1）。

### D-5 验证与同步状态

**校验实际输出**：见 3.8（`md_check` / `link_check` / `context_budget` / `threshold_check` / `claims_audit` / `pitfall_check` / `skills_index_check` / `secrets_scan` / `policy_guard`，共 9 项，全部 EXIT=0），原文已粘贴，非「已通过」式结论。

**同步状态**：本地 `87d1878` = 远端 `main` `87d1878`，领先 0、落后 0（`git rev-list --left-right --count` 输出 `0	0`）。

**推送状态：未推送。** 依据：前后两次 `git ls-remote origin` 快照逐字节一致（见 4.2）；未执行任何 `git push`（仅 `--dry-run` 且失败，EXIT=128）；未开 PR；未上传任何文件到 GitHub。

**平台报错（按三栏）**：Windows / `bash.exe sh scripts/md_check.sh` / 退出码 126（`cannot execute binary file`）——已用 `bash.exe scripts/md_check.sh` 等价方式跑通（EXIT=0），根因推测未确认，见 3.8。

**未跑项及原因**：`pre-push-check.sh`（写 `~/.ssh` 凭据，禁）、`delivery_report.sh`（零改动无提交对象）、`backup_snapshot.sh` / `metrics_collect.sh` / `tool_entrypoints.sh`（无对应场景）。

### D-6 沉淀与待确认

**沉淀建议（提建议，不改库）**：见第七节 3 条，供维护者裁决。

**待确认事项**：3 条建议均待维护者裁定（是否入 PITFALLS / 是否改 S-004 文档表述 / 是否需要给脚本加 `sh` 兼容兜底）。无其他悬置。

### D-7 依据核验

**本次无业务/政策类结论，D-7 不适用。** 依据：本轮结论全部为工程与流程事实（脚本退出码、git 引用快照、文件读取状态），不含任何财税政策判断，不涉及政策名称与条款引用。`scripts/policy_guard.sh` 亦输出「[D-7] 无暂存 Markdown 改动，依据核验跳过」（EXIT=0）。

---

## 七、发现的规则/平台冲突与建议（只提建议，由维护者裁决）

### 7.1 建议 1：`sh <script>` 调用方式在部分 MSYS2 环境失效，建议入坑账本

- **冲突点**：`skills/S-004` 执行指令第 2 条与 `rules/02` 第 22 行均写作「跑 `sh scripts/session_start_check.sh`」。在千问内置 MSYS2 bash 5.3.20 下，以 `sh` 作解释器前缀会以 126 失败（`cannot execute binary file`），但脚本本身无缺陷——直接以 bash 执行即通过。
- **影响面**：只影响「按文档字面照抄命令」的 Windows Agent，会被误判为仓库门禁损坏；实际门禁健康（9 项全绿）。
- **建议降级写法**：文档中把 Windows 分支写成「用 `<bash 绝对路径> scripts/xxx.sh` 直接执行脚本，不要写成 `sh scripts/xxx.sh`」，保留 Linux 下的 `sh` 写法；不改任何脚本逻辑，不改条款含义。
- **不建议**：给脚本加 `sh` 兼容兜底（ADR-022 已否决同类「双实现」思路，维护成本高且必漂移）。我倾向只改文档表述。

### 7.2 建议 2：降级表「独立复审」一行可补一句能力自判的边界

- **冲突点**：`docs/AGENT-ADAPTER.md` 降级表要求「无子 Agent 必须开第二会话独立复审，不得自写自审」；但未说明「有子 Agent 能力但子 Agent 不继承上下文、只读验证场景下复审价值有限」如何处理。ADR-022 否决项 ③ 已裁定「能力超配由 Agent 自判」维持现状，条款与裁定之间存在解释空档。
- **建议**：降级表该行补一句「验证型只读任务中，若第二执行者无法取得第一执行者的会话内证据，可声明『降级：复审由维护者承接』」，不改变「不得自写自审」的实质。
- **风险承接**：我本轮正是按此理解处理（标注降级、复审交维护者），若维护者认为不合规，请直接指出，我调整表述。

### 7.3 建议 3：`session_start_check.sh` 可增打一条「解释器路径」

- **现状**：脚本输出打印仓库根、四个文件存在性、分支、HEAD、远端差异、hooksPath、交接快照、金丝雀，唯独不打印**当前运行它的解释器是谁**。本轮「是否落到 WSL bash」是任务显式风险点，只能靠我自己另跑 `cygpath` 取证。
- **建议**：脚本增一行输出解释器绝对路径（只打印，不改退出码、不加新校验）。属轻级表述外的行为微调，需维护者按重级评估，我不擅自改。

---

## 八、结论

### 8.1 三选一

**② 可行但有降级。**

不做 ①「接入成功」的理由：确有三条降级实际发生（未装 hook 自动门禁、未独立复审、无定时等价任务），按「不得把降级当合规」的要求，应如实归入②，不宜报①。

不做 ③「不可接入」的理由：核心链路**全部实际执行成功**——clone 成功、开工自检退出码 0、版本核对一致、脚本可跑、9 项门禁全绿、凭据阻断生效、干跑按预期失败、前后远端快照一致。无任何阻塞点。

**降级清单（缺口 + 承接方）**：

| # | 缺口 | 影响 | 承接方 |
| --- | --- | --- | --- |
| 1 | 无 hook 自动门禁（11 项不自动跑） | 依赖 Agent 手工跑；本轮手工跑了零改动档 2 项 + 加强 7 项 | 本 Agent 已跑；维护者入库前复核 |
| 2 | 未独立复审 | 判读偏差无第二方交叉验证 | 维护者 |
| 3 | 无定时调度等价任务 | 本次不涉及 | 不适用（如需要由维护者调度器承接） |

### 8.2 证据索引

| 结论 | 证据 |
| --- | --- |
| 仓库同源且为最新 | `git rev-parse --short HEAD` = `87d1878`；`session_start_check.sh` 报「落后 0｜领先 0」，EXIT=0 |
| 规则被真实读到 | 复述 `CANARY-TRAE-7F3A9C`；探针两题答对；能指出 `rules/02:22`、`AGENTS.md:99` 的具体位置 |
| 效力分层已区分 | 第五节表；未按 S-005 建任何委托文件；未把 ADR-022 否决项当机制 |
| 零改动 | 三次 `git status --porcelain` 全空 |
| 未装钩子/未配凭据 | `git config --get core.hooksPath` 无值（EXIT=1）；未跑 `gh auth login`；未动 `~/.ssh` |
| 凭据已阻断 | `helper =`（空），`push --dry-run` EXIT=128，`terminal prompts disabled` |
| 未推送 | 前后 `ls-remote` 逐字节一致；`rev-list --left-right --count` = `0	0` |
| 门禁健康 | 9 项脚本 EXIT=0，输出已粘贴 |

---

## 九、事实与推测分栏（按 rules/01 要求）

**可验证事实部分**（均附可复现命令或文件位置）：

1. 本地副本 HEAD 为 `87d1878`，与远端 `refs/heads/main` 一致，落后 0、领先 0。
2. `scripts/session_start_check.sh` 退出码 0，输出已全文粘贴于 3.2。
3. 金丝雀串为 `CANARY-TRAE-7F3A9C`，位于 `AGENTS.md:99`。
4. 以 `sh` 作解释器前缀调用 `md_check.sh` / `link_check.sh` 均退出码 126，报 `cannot execute binary file`；去掉前缀直接执行均退出码 0。
5. 9 项校验脚本（md/link/context_budget/threshold/claims/pitfall/skills_index/secrets/policy_guard）全部退出码 0，`context_budget.sh` 报必读集 159/160、总纲 99/100。
6. `git config --local credential.helper ""` 后，`.git/config` 含 `helper =`（空值），`show-origin` 显示系统级 gitconfig 仍有 `manager`。
7. `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` 退出码 128，报 `could not read Username`。
8. 任务前后 `git ls-remote origin` 四行输出完全一致。
9. `git status --porcelain` 在 clone 后、门禁后、成文前三次调用均为空。
10. `git config --get core.hooksPath` 无输出、退出码 1，即钩子未启用。
11. 本机无 `C:/Program Files/Git/bin/bash.exe`；本次使用的 bash 绝对路径为千问内置组件路径（`cygpath` 已取证）；`wsl.exe` 存在但全程未调用。
12. `scripts/pre-push-check.sh` 源码第 6~32 行含写 `$HOME/.ssh/id_ed25519`、`$HOME/.ssh/config`（含 ProxyCommand 与代理端口）的逻辑。

**主观推测与猜测部分**（明确未经确认）：

1. 「`sh` 前缀失败」的根因我推测是 MSYS2 运行时中 `sh` 转发程序与该 bash 版本不匹配，**尚未核实**——未去查该运行时的 `sh` 二进制构成，也未在其他 MSYS2 版本上复现。故建议 7.1 只改文档表述、不改脚本，避免基于未确认根因动代码。
2. 我推断「子 Agent 复审在本场景价值有限」，依据是子 Agent 不继承上下文（AGENTS-GLOBAL 实测记录）；但**未实测**本轮派子 Agent 重跑是否真会得到不同结论，属推理判断。
3. 关于本报告未落库：我判断入库应由维护者决定（`reports/` 属审计资产，写入口唯一在主会话），这是我按 rules/04 与 AGENTS-GLOBAL「写入口唯一」做出的判断，不是已确认的规则原文要求。