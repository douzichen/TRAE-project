# 规则库接入验证实测报告（第二棒）

- **实测身份**：豆包工作（DoubaoWork），外部协作验证 Agent（非维护者）
- **实测日期**：2026-11-20（Asia/Shanghai）
- **目标仓库**：https://github.com/douzichen/TRAE-project.git
- **实测 commit**：`b9b36fe`（`git rev-parse --short HEAD`）
- **实测平台**：Windows 11（主机名 ITLT-088）＋ Git Bash `E:\Git\bin\bash.exe`；git 2.56.0.windows.4
- **总判定**：**② 可行但有降级**（接入 8 步全部走通，存在 2 项能力降级 + 3 条待裁决建议，详见第六、九节）

---

## 一、边界声明（本次做什么 / 不做什么）

**做**：完整走一遍 S-004 规则库接入流程；跑会话自检与只读门禁；实测推送资格并自证失败；按 D-1~D-7 交付报告；作答角色切换 5 问与探针题。

**不做（红线，全部遵守）**：
1. 不改任何规则文件、不做本地 commit；不认领 `docs/CLAIMS.md`；不参与并行协议。
2. 不装 `.githooks`；不配 deploy key / token / `gh auth login`。
3. 不 `git push`、不开 PR、不上传任何文件到 GitHub。
4. 唯一对本地 git 配置的写动作是规定动作 `git config --local credential.helper ""`（改本地 `.git/config`，非仓库跟踪文件、非工作树）。
5. 报告落盘在会话隔离工作区，不进 `TRAE-project` 工作树。

---

## 二、加载状态声明与探针题

**已读文件清单**（按指定顺序，逐份读完，无截断）：
1. `AGENTS.md`
2. `rules/00-core.md`
3. `rules/01-user-profile.md`
4. `rules/02-intake-and-dod.md`
5. `docs/AGENT-ADAPTER.md`（先读第〇节「效力分层」）
6. `docs/ROLE-SWITCH-CHECK.md`
7. `skills/S-004-rulebase-onboarding.md`
8. `AGENTS-GLOBAL.md`（只读「通用层与项目特定层划分」「跨项目运行模型」两节）
9. 按 AGENTS.md 路由表加读：`rules/04-roles-and-dispatch.md`、`rules/15-delivery-dod.md`
10. 补读：`rules/12-context-budget.md`（完整性声明依据）、`skills/S-005-absence-delegation-blueprint.md`、`docs/adr/INDEX.md`（效力分层核对）

**未加载分册**（本轮不属任务必需，不作其条款依据）：03、05、06、07、08、09、10、11、13、14。

**金丝雀标记（复述）**：`CANARY-TRAE-7F3A9C`
效力说明：按 S-004 与 ADR-011，该串只证明**读到了仓库副本**，不证明宿主自动注入了规则；实际加载以 D-1~D-7 产物为准。

**探针题答案**：
- **题 1**：开工第 0 步应执行仓库里的哪个脚本？
  答：`sh scripts/session_start_check.sh`（会话启动自检脚本；Windows 在 Git Bash 里跑）。
- **题 2**：AGENTS.md 末尾的金丝雀标记是什么？
  答：`CANARY-TRAE-7F3A9C`。

**效力分层注意（已按第〇节执行）**：
- `skills/S-005` 视为「评审存档蓝图」：名称行与「不适用」节均写明本库终局裁定不建缺席委托机制（ADR-021 条款一），**未按生效机制行事**。
- `docs/adr/` 中被否决/裁定不建的项，未当作机制执行；ADR-004/005 标注「部分被取代」，以取代链后版本为准。
- `PITFALLS.md` 中依赖特定沙箱的环境特定条目（如 P-001）按「环境特定条目」处理，不照搬。

---

## 三、第 0 步执行记录

### 3.1 定位与更新仓库

本地已有同源副本 `D:\TRAE-project`，工作区干净；开工前本地 HEAD 为 `51a9ec3`，落后远端。按开工强制握手先快进：

```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean

$ git pull --ff-only origin main
From https://github.com/douzichen/TRAE-project
 * branch            main       -> FETCH_HEAD
   51a9ec3..b9b36fe  main       -> origin/main
Updating 51a9ec3..b9b36fe
Fast-forward
（30 files changed, 660 insertions(+), 90 deletions(-)）
（pull exit=0）
```

快进后本地与远端同为 `b9b36fe`，符合「落后不得开工」条件。

### 3.2 会话自检脚本（整段输出，Git Bash）

```text
$ sh scripts/session_start_check.sh
[SESSION] 仓库根：D:/TRAE-project
[SESSION] 存在：AGENTS.md
[SESSION] 存在：rules/00-core.md
[SESSION] 存在：rules/01-user-profile.md
[SESSION] 存在：rules/02-intake-and-dod.md
[SESSION] 当前分支：main
[SESSION] 本地 HEAD：b9b36fe
[SESSION] 远端 main：b9b36fe｜落后 0｜领先 0
[SESSION] hooksPath 未设为 .githooks：本地门禁不会自动运行（验证型 Agent 未装 hook 属合法状态；维护者主会话须先 git config core.hooksPath .githooks）
[SESSION] 交接快照：b9b36fe docs(reports): 第一棒 WorkBuddy 实测通过入库——接入8步走通(结论②可行但有降级2项)；3条建议裁决：S-004零改动免commit澄清采纳(轻级v1.1)、P-001环境特定无需改、能力超配不采纳(复发即升级)；CURRENT第一棒收口
[SESSION] 交接快照距今 0 个提交（仅供参考：快照按交付更新，不构成失败）
[SESSION] 金丝雀可见：CANARY-TRAE-7F3A9C（首条回复须复述；仅证明副本内容，不证明宿主加载）
[SESSION] 自检通过：可以开工（本次未改工作区）
（exit=0）
```

退出码单独复核：`EXIT_CODE=0`。

### 3.3 commit 记录

```text
$ git rev-parse --short HEAD
b9b36fe
```

---

## 四、接入 8 步逐条记录（S-004「执行步骤」）

| 步骤 | 状态 | 判定依据 |
| --- | --- | --- |
| 1 确认同源 | 直接可执行 | `AGENTS.md` 与 `rules/` 均在；已有副本先 `git pull --ff-only` 快进至最新 |
| 2 记录版本 | 直接可执行 | 见 3.3，commit=`b9b36fe` |
| 3 读常驻四件套 | 直接可执行 | AGENTS/00/01/02 逐份读完，无截断 |
| 4 路由加读 1~2 册 | 直接可执行 | 加读 `rules/04`、`rules/15`；另补 12/ADAPTER/ROLE-SWITCH/S-004/GLOBAL 两节；未整库通读 |
| 5 加载声明 | 直接可执行 | 见第二节「已读文件清单」 |
| 6 金丝雀验证 | 直接可执行 | 复述 `CANARY-TRAE-7F3A9C`，见第二节 |
| 7 能力适配与降级 | **部分降级** | 2 项降级，见第六节 |
| 8 交付自检 | 直接可执行 | 按 D-1~D-7 逐项对照，见第七节 |

### 4.1 直接可执行步骤的命令与输出

```text
# 步骤1：同源核验
$ Test-Path AGENTS.md; Test-Path rules/
True
True

# 步骤2：记录版本
$ git rev-parse --short HEAD
b9b36fe

# 步骤3/4：按序读取，Read 工具逐份返回全文，无截断

# 步骤6：金丝雀（自检脚本内 grep 命中）
[SESSION] 金丝雀可见：CANARY-TRAE-7F3A9C
```

### 4.2 卡住步骤（三栏）

**本次无执行卡住的步骤。** 唯一非零退出是推送资格演练，属**设计内预期失败**，按三栏记录：

| 平台 | 命令 | 退出码 |
| --- | --- | --- |
| Windows / Git Bash（git 2.56.0.windows.4） | `git config --local credential.helper ""` 后 `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` | `128` |

输出：`fatal: could not read Username for 'https://github.com': terminal prompts disabled` —— 失败即通过。

### 4.3 无对应能力步骤（按 AGENT-ADAPTER 降级表逐条声明）

| 本仓库机制 | 本次状态 | 降级做法（实际执行） | 缺哪项检查 | 风险由谁承接 |
| --- | --- | --- | --- | --- |
| git hook（`.githooks/`） | 未装（红线禁止；自检脚本已告警 hooksPath 非 .githooks） | 零改动只读验证档：跑 `md_check.sh` + `link_check.sh`，均退出 0 | 未跑 pre-commit 全链其余项：`secrets_scan`、`context_budget`、`threshold_check`、`paths_check`、`claims_audit`、`pitfall_check`、`skills_index_check`、`stale_terms_check`、`policy_guard`；未跑 `pre-push-check.sh` 凭据检查（以 dry-run push 失败自证替代） | 维护者：本次零改动、无提交对象，全链无对象可检；正式维护提交须在装好 hook 的主会话环境跑全链 |
| 子 Agent 派发 / 第二执行者 | 本次单会话，未派发独立复审 | 标注「降级：未独立复审」，报告即单会话自审产物 | 缺第二执行者独立复审（撰写与审查未物理隔离） | 维护者主会话复核本报告承接 |
| 定时调度器 | 本次任务不涉及 | 不适用，未建等价任务 | 无 | — |
| bash 脚本 | 有 Git Bash（`E:\Git\bin\bash.exe`） | 直接执行 `.sh` 脚本，无终端降级 | 无 | — |
| ADR / 分册拆分 | 平台支持多文件 | 直接读取多文件，无降级 | 无 | — |

**不得把降级当合规**：上述 2 项降级均为真实缺口，未假装执行，特此声明。

---

## 五、推送资格实测（红线 3）

### 5.1 凭据配置处置

```text
# 原值采集（读取，未改 global）
$ git config --local --get credential.helper
（空，local 原本未配）
$ git config --global --get credential.helper
!"C:/Users/ITLT-088/.workbuddy/binaries/PortableGit/versions/1.2.0/mingw64/bin/git-credential-manager.exe"

# 规定动作：清空 local helper
$ git config --local credential.helper ""
$ git config --local --get-all credential.helper
（空，即已重置）
```

### 5.2 dry-run push 自证失败

```text
$ GIT_TERMINAL_PROMPT=0 git push --dry-run origin main
fatal: could not read Username for 'https://github.com': terminal prompts disabled
（exit=128）—— 按规则「必须失败才算通过」：通过
```

### 5.3 任务前后远程快照（`git ls-remote origin`）

**任务前**：
```text
b9b36fe431a099b21b1ee1544afd714bd6d8465d	HEAD
b9b36fe431a099b21b1ee1544afd714bd6d8465d	refs/heads/main
cc0ce9a0800a941c1c5ac477c0e10e19ca667e78	refs/tags/pre-skill-meta
b1c78d611ef548d3c92b2cefe2f1c7622d84f255	refs/tags/pre-skill-meta^{}
```

**任务后**：
```text
b9b36fe431a099b21b1ee1544afd714bd6d8465d	HEAD
b9b36fe431a099b21b1ee1544afd714bd6d8465d	refs/heads/main
cc0ce9a0800a941c1c5ac477c0e10e19ca667e78	refs/tags/pre-skill-meta
b1c78d611ef548d3c92b2cefe2f1c7622d84f255	refs/tags/pre-skill-meta^{}
```

前后逐字节一致 → 远端未被改动。领先/落后核对：`HEAD..origin/main` = 0，`origin/main..HEAD` = 0；`git status --porcelain` 为空。**未推送**：全程无真实 `git push`、无 PR、无上传。

---

## 六、结论三选一

**选中：② 可行但有降级。**

**证据**：
1. 接入 8 步全部走通：同源核验 → 记录 commit → 读四件套 → 路由加读 → 加载声明 → 金丝雀 → 适配降级 → D-1~D-7 自检。
2. 金丝雀 `CANARY-TRAE-7F3A9C` 复述成功（证明读到副本）。
3. 只读门禁实测：`md_check.sh` 退出 0；`link_check.sh` 退出 0（副作用见 6.1）。
4. 推送资格自证失败（exit 128），前后 `ls-remote` 一致，「未推送」有机器证据。
5. **降级清单**（真实缺口，非合规替代）：
   - 降级 1：未装 hook → 仅跑 `md_check` + `link_check`，pre-commit 全链其余项与 `pre-push-check` 未跑（零改动无提交对象）。
   - 降级 2：单会话自审 → 未开第二独立会话复审，缺独立复审。
6. **能力边界诚实声明**：本实测证明的是「同源 clone + 显式开工令」能读出规则并复述金丝雀；**不能证明宿主自动注入**——与 ADR-011 结论一致，不构成接入失败，但不应被夸大为「规则已自动生效」。

未选 ① 的原因：存在 2 项明确降级。未选 ③ 的原因：无阻塞点，8 步全部执行到位。

### 6.1 实测中出现的脚本副作用（已撤销）

`link_check.sh` 运行时输出「已刷新 docs/BACKLINKS.md」，并将反向索引按字母序重排后**加入暂存区**（26 行增删，条目集合不变，仅排序差异）。该副作用与「零改动只读」红线冲突；已用 `git restore --staged` + `git restore` 撤销，最终 `git status --porcelain` 为空。此点与第一棒记录（「未产生 diff」）不一致，列入第九节建议 A。

---

## 七、D-1~D-7 逐项汇报（rules/15）

**D-1 规则改动交付分级**：**规则库未改动，无全文义务。** 本次 `AGENTS.md` 与任一 `rules/` 分册均未改动；唯一写动作 `git config --local credential.helper ""` 改的是本地 `.git/config`（非规则文件、非工作树跟踪文件）。

**D-2 改动清单**：
- `TRAE-project` 工作树内：**零文件改动、零 commit**（`git status --porcelain` 为空，ahead 0 / behind 0）。
- 会话隔离工作区：新增本报告 1 份，不进规则库工作树。
- 本地 git 配置：`credential.helper` 置空（已在 5.1 声明，非仓库文件）。
- 已撤销的临时改动：`docs/BACKLINKS.md` 经 `link_check.sh` 重排产生的暂存 diff，已 restore 回 HEAD 版本。

**D-3 对账结果**：本次为只读实测，未改动任何文档，无影响面。逐份核对：`AGENTS.md`、`AGENTS-GLOBAL.md`、`README.md`、`PITFALLS.md`、`skills/INDEX.md`、`workflows/INDEX.md` 均**未改动**（两份 INDEX 实测存在）；`docs/BACKLINKS.md` 的脚本重排副作用已撤销，与 HEAD 一致。无文档/实现不一致项。

**D-4 记忆收录说明**：本次**不写入**规则库长期记忆。理由：只读验证任务，不产生机制性、跨会话复用的规则；不认领 `docs/CLAIMS.md`；不触发并发协议。落点：无。第九节三条建议仅交维护者裁决，不擅自入库。

**D-5 验证与同步状态**：

| 校验 | 命令 | 输出 | 退出码 |
| --- | --- | --- | --- |
| 会话自检 | `sh scripts/session_start_check.sh` | 见 3.2 整段；`自检通过：可以开工` | 0 |
| md 完整性 | `sh scripts/md_check.sh` | `[P-004] md 完整性校验通过` | 0 |
| 链接与结构 | `sh scripts/link_check.sh` | `[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md` | 0（副作用已撤销，见 6.1） |
| 推送资格 | `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` | `fatal: could not read Username ... terminal prompts disabled` | 128（预期失败＝通过） |
| 工作树 | `git status --porcelain` | 空 | 0 |
| 同步 | `git rev-list --count HEAD..origin/main` / 反向 | 0 / 0 | 0 |

同步状态：本地与远端同为 `b9b36fe`，ahead 0；**未推送**，前后 `ls-remote` 见 5.3。

**D-6 沉淀与待确认**：本次为只读验证，**不沉淀** skill/workflow（无新增机制，且红线禁止改库）。待确认：第九节 3 条规则平台适配建议，由维护者裁决；本次无悬置待办。

**D-7 依据核验**：**本次无业务/政策类结论，D-7 不适用。** 全部结论为仓库接入流程的可验证事实，不涉及财税口径或法规条款。

---

## 八、角色切换自检 5 问（AGENT-ADAPTER 开工前置）

1. **谁撰写、谁审查？是否同一会话/同一 Agent？** 本次产物由豆包工作单一 Agent 撰写；未指定独立审查人，撰写与审查为同一会话、同一 Agent。
2. **若为同一 Agent，是否已开第二个独立会话做复审？若不能，是否标注降级？** 未开第二独立会话；按降级口径标注「降级：未独立复审」，缺口与风险承接方见 4.3、第六节。
3. **是否有子 Agent 能力？没有时如何拆分生产与审查？** 本轮未派发子 Agent；生产与审查未物理隔离，以 D-1~D-7 逐项自检替代，此为已声明降级。独立复审缺口由维护者主会话承接。
4. **交付是否包含 D-1~D-7（或按 AGENT-ADAPTER 声明的降级项）？** 含，见第七节逐项；降级项在 4.3 逐条标注。
5. **是否按 rules/12 声明「未完整读取」的文件？** 指定清单内文件均完整读取、无截断；未整库通读；未加载分册清单见第二节，本轮不作其条款依据，无需声明「未完整读取」。

---

## 九、规则与平台冲突 —— 仅提建议，不改规则

以下均为建议，本次**未改任何规则文件**，由维护者裁决：

1. **`link_check.sh` 在只读验证档会重写并暂存 `BACKLINKS.md`，与「零改动只读」红线有轻微副作用冲突。** 实测：脚本把索引条目按字母序重排后 `git add` 进暂存区，条目集合不变；第一棒记录为「未产生 diff」，与本次现象不一致。**建议**：①给 `link_check.sh` 增加只读/`--check` 模式（只校验不写盘、不暂存）；或②在 S-004/ADAPTER 降级表注明「只读验证跑完 link_check 须 `git restore` 撤销索引副作用」；并请维护者核对该排序在不同平台是否稳定。
2. **`git config --local credential.helper ""` 只重置 local 层，不阻断 global 层 helper。** 实测本机 global 配置挂有 WorkBuddy 自带 `git-credential-manager.exe`；本次 dry-run 仍以 128 失败（GCM 未提供可用缓存凭据），但若 global helper 缓存了有效 GitHub token，local 空值未必能阻断，推送资格自证可能被绕过。**建议**：验证型 Agent 的 dry-run 步骤补充临时隔离 global 配置（如 `GIT_CONFIG_GLOBAL=/dev/null` 或命令行 `-c credential.helper=`），使自证不依赖 global 凭据状态；是否写入 S-004 由维护者裁决。
3. **Windows 默认 `bash` 解析到 WSL bash（`C:\Windows\system32\bash.exe`），而非 Git Bash。** 任务书指定 Git Bash 正确；若外部 Agent 直接敲 `sh xxx.sh`，在不同机器可能落到 WSL bash，导致路径/sed 行为差异。**建议**：S-004 的 Windows 条目显式写明调用 Git Bash 可执行文件（如 `<Git 安装目录>\bin\bash.exe`），不要依赖 `bash` 在 PATH 中的默认解析。

**第一棒已提、本次不重复的事项**：P-001 环境特定条目（裁决无需改）；零改动免 commit 口径（S-004 v1.1 已采纳落地）；能力超配表述（裁决不采纳，复发即升级）。

---

## 可验证事实部分

- 指定开工脚本为 `sh scripts/session_start_check.sh`，实测整段输出见 3.2，退出码 0。
- 金丝雀标记 `CANARY-TRAE-7F3A9C`，见于 `AGENTS.md` 末尾，实测复述成功。
- 探针题：题 1 = `scripts/session_start_check.sh`；题 2 = `CANARY-TRAE-7F3A9C`。
- 实测 commit `b9b36fe`（开工前本地 `51a9ec3`，已快进）；任务前后 `git ls-remote origin` 输出逐字节一致。
- `git config --local credential.helper ""` + `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` 实测退出码 128、失败即通过。
- `md_check.sh` 退出 0；`link_check.sh` 退出 0，其 `BACKLINKS.md` 重排副作用已 restore，最终 `git status --porcelain` 为空。
- 接入 8 步与 D-1~D-7 逐项记录，均基于本次实际执行的命令与输出。

## 主观推测部分

- 第九节建议 A 中「排序在不同平台不稳定」为待核对推测，未在多平台复测，标注「未确认」。
- 建议 B 中「global helper 缓存有效 token 时可能绕过 local 空值」为机制推断，本次实测未触发该路径，标注「未确认」。
- 「金丝雀不能证明宿主自动注入」为依据 ADR-011 原文的效力判定，非推测。
