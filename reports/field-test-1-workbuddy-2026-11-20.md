# 规则库接入验证实测报告（第一棒）

- **实测身份**：WorkBuddy，外部协作验证 Agent（非维护者）
- **实测日期**：2026-11-20（Asia/Shanghai）
- **目标仓库**：https://github.com/douzichen/TRAE-project.git
- **实测 commit**：`4035b87`（`git rev-parse --short HEAD`）
- **实测平台**：Windows + Git Bash（git 2.55.0.windows.3）
- **总判定**：**② 可行但有降级**（接入 8 步全部走通，存在 2 项能力降级，详见第六节）

---

## 一、边界声明（本次做什么 / 不做什么）

**做**：完整走一遍 S-004 规则库接入流程；跑会话自检与只读门禁；实测推送资格并自证失败；按 D-1~D-7 交付报告。

**不做（红线，全部遵守）**：
1. 不改任何规则文件、不做本地 commit；不认领 `docs/CLAIMS.md`；不参与并行协议。
2. 不装 `.githooks`；不配 deploy key / token / `gh auth login`。
3. 不 `git push`、不开 PR、不上传任何文件到 GitHub。
4. 唯一写动作是 `git config --local credential.helper ""`（改本地 `.git/config`，非仓库跟踪文件），开工前已声明。
5. 报告落盘在仓库**外**的工作区目录，不进 `TRAE-project` 工作树。

---

## 二、加载状态声明与探针题

**已读文件清单**（按指定顺序，逐份读完）：
1. `AGENTS.md`
2. `rules/00-core.md`
3. `rules/01-user-profile.md`
4. `rules/02-intake-and-dod.md`
5. `docs/AGENT-ADAPTER.md`（先读第〇节「效力分层」）
6. `skills/S-004-rulebase-onboarding.md`
7. `AGENTS-GLOBAL.md`（只读「通用层与项目特定层划分」「跨项目运行模型」两节）
8. 按 AGENTS.md 路由表加读：`rules/04-roles-and-dispatch.md`、`rules/15-delivery-dod.md`
9. 补读：`docs/ROLE-SWITCH-CHECK.md`（AGENT-ADAPTER.md 顶部声明的开工前置条件，5 问已作答，见第八节）

**金丝雀标记（复述）**：`CANARY-TRAE-7F3A9C`
效力说明：按 S-004 与 ADR-011，该串只证明**读到了仓库副本**，不证明宿主自动注入了规则。实际加载以 D-1~D-7 产物为准。

**探针题答案**：
- **题 1**：开工第 0 步应执行的脚本是 `sh scripts/session_start_check.sh`（Windows 用 Git Bash）。
- **题 2**：AGENTS.md 末尾金丝雀标记是 `CANARY-TRAE-7F3A9C`。

**效力分层注意（已按第〇节执行）**：
- `skills/S-005` 视为「评审存档蓝图」，本库已终局裁定不建缺席委托机制，**未按机制行事**。
- `docs/adr/` 中被否决/裁定不建的项，**未当作机制执行**。
- `PITFALLS.md` 中 P-001 等环境特定条目按「环境特定条目」处理，未照搬。

---

## 三、第 0 步执行记录

### 3.1 定位与更新仓库

发现一处残留目录 `~/.trae-cn/worktrees/TRAE-project`（空目录、非 git 仓库），按指令执行 clone：

```text
$ git clone https://github.com/douzichen/TRAE-project.git
Cloning into 'TRAE-project'...
（clone exit=0）

$ git pull --ff-only origin main
From https://github.com/douzichen/TRAE-project
 * branch            main       -> FETCH_HEAD
Already up to date.
（pull exit=0）
```
未落后，符合开工条件。

### 3.2 会话自检脚本（整段输出）

```text
$ sh scripts/session_start_check.sh
[SESSION] 仓库根：C:/Users/ITLT-088/WorkBuddy/spaces/2026_11_18_17-31-37/TRAE-project
[SESSION] 存在：AGENTS.md
[SESSION] 存在：rules/00-core.md
[SESSION] 存在：rules/01-user-profile.md
[SESSION] 存在：rules/02-intake-and-dod.md
[SESSION] 当前分支：main
[SESSION] 本地 HEAD：4035b87
[SESSION] 远端 main：4035b87｜落后 0｜领先 0
[SESSION] hooksPath 未设为 .githooks：本地门禁不会自动运行（验证型 Agent 未装 hook 属合法状态；维护者主会话须先 git config core.hooksPath .githooks）
[SESSION] 交接快照：4035b87 docs(adapter): AGENT-ADAPTER 新增第〇节「效力分层」——外部 Agent 先分清生效条款/决策存档/评审存档蓝图/模板索引/环境条目，防把存档当机制（两路子 Agent 检索证据+主审裁定，轻级仅表述不改条款含义）；CURRENT 实测排班行同步
[SESSION] 交接快照距今 0 个提交（仅供参考：快照按交付更新，不构成失败）
[SESSION] 金丝雀可见：CANARY-TRAE-7F3A9C（首条回复须复述；仅证明副本内容，不证明宿主加载）
[SESSION] 自检通过：可以开工（本次未改工作区）
（exit=0）
```

### 3.3 commit 记录

```text
$ git rev-parse --short HEAD
4035b87
```

---

## 四、接入 8 步逐条记录（S-004「执行步骤」）

| 步骤 | 状态 | 判定依据 |
| --- | --- | --- |
| 1 确认同源 | 直接可执行 | `AGENTS.md` 与 `rules/` 均在；先 clone 再核验两样齐备 |
| 2 记录版本 | 直接可执行 | 见 3.3，commit=`4035b87` |
| 3 读常驻四件套 | 直接可执行 | 00/01/02 逐份读完，无截断 |
| 4 路由加读 1~2 册 | 直接可执行 | 加读 `rules/04`、`rules/15`；未整库通读 |
| 5 加载声明 | 直接可执行 | 见第二节「已读文件清单」 |
| 6 金丝雀验证 | 直接可执行 | 复述 `CANARY-TRAE-7F3A9C`，见第二节 |
| 7 能力适配与降级 | **部分降级** | 2 项降级，见第六节 |
| 8 交付自检 | 直接可执行 | 按 D-1~D-7 逐项对照，见第七节 |

### 4.1 直接可执行步骤的命令与输出

```text
# 步骤1：同源核验
$ ls -d AGENTS.md rules/
AGENTS.md  rules/

# 步骤2：记录版本（见 3.3）
$ git rev-parse --short HEAD
4035b87

# 步骤3/4：按序读取，逐份读完（工具 Read 逐份返回全文，无截断）

# 步骤6：金丝雀
$ grep -o 'CANARY-TRAE-7F3A9C' AGENTS.md
CANARY-TRAE-7F3A9C
```

### 4.2 卡住步骤（三栏）

**本次无步骤卡住。** 唯一非零退出是推送资格演练，属**设计内预期失败**，按三栏记录如下：

| 平台 | 命令 | 退出码 |
| --- | --- | --- |
| Windows / Git Bash | `git config --local credential.helper ""` 后 `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` | `128` |

输出：`fatal: could not read Username for 'https://github.com': terminal prompts disabled` —— 失败即通过。

### 4.3 无对应能力步骤（按 AGENT-ADAPTER 降级表逐条声明）

| 本仓库机制 | 本次状态 | 降级做法（实际执行） | 缺哪项检查 | 风险由谁承接 |
| --- | --- | --- | --- | --- |
| git hook（`.githooks/`） | 未装（红线禁止） | 零改动只读验证：跑 `md_check.sh` + `link_check.sh`，均通过 | 未跑 pre-commit 全链 11 项与 `pre-push-check.sh` 凭据检查 | 维护者：本次零改动、无提交对象，全链无对象可检 |
| 子 Agent 派发 / 第二执行者 | 本次单会话，未开独立复审会话 | 标注「降级：未独立复审」，报告即单会话自审产物 | 缺第二执行者独立复审 | 维护者裁决承接 |
| 定时调度器 | 本次任务不涉及 | 不适用 | 无 | — |
| bash 脚本 | 有 Git Bash | 直接执行，无降级 | 无 | — |
| ADR / 分册拆分 | 平台支持多文件 | 直接读取多文件，无降级 | 无 | — |

**不得把降级当合规**：上述 2 项降级均为真实缺口，未假装执行，特此声明。

---

## 五、推送资格实测（红线 3）

```text
$ git config --local credential.helper ""
（exit=0；本地 helper 列表已清空）

$ git config --local --get credential.helper
（返回空）

$ GIT_TERMINAL_PROMPT=0 git push --dry-run origin main
fatal: could not read Username for 'https://github.com': terminal prompts disabled
（exit=128）—— 按规则「必须失败才算通过」：通过
```

**未推送**：全程无 `git push`（仅 `--dry-run` 且失败）、无 PR、无上传。

### 任务前后远程快照（`git ls-remote origin`）

**任务前**：
```text
4035b87c1647895166966fb4baa12ecb82ab1dba	HEAD
4035b87c1647895166966fb4baa12ecb82ab1dba	refs/heads/main
cc0ce9a0800a941c1c5ac477c0e10e19ca667e78	refs/tags/pre-skill-meta
b1c78d611ef548d3c92b2cefe2f1c7622d84f255	refs/tags/pre-skill-meta^{}
```

**任务后**：
```text
4035b87c1647895166966fb4baa12ecb82ab1dba	HEAD
4035b87c1647895166966fb4baa12ecb82ab1dba	refs/heads/main
cc0ce9a0800a941c1c5ac477c0e10e19ca667e78	refs/tags/pre-skill-meta
b1c78d611ef548d3c92b2cefe2f1c7622d84f255	refs/tags/pre-skill-meta^{}
```

前后逐字节一致 → 远端未被改动。工作树核验：`git status --short` 输出为空；`git status -sb` 为 `## main...origin/main`（领先 0、落后 0）。

---

## 六、结论三选一

**选中：② 可行但有降级。**

**证据**：
1. 接入 8 步全部走通：clone/pull → 记录 commit → 读四件套 → 路由加读 → 加载声明 → 金丝雀 → 适配 → D-1~D-7 自检。
2. 金丝雀 `CANARY-TRAE-7F3A9C` 复述成功（证明读到副本）。
3. 只读门禁 `md_check.sh`（`[P-004] md 完整性校验通过`，exit=0）、`link_check.sh`（`[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md`，exit=0）均通过；刷新后 `git status --short` 仍为空，未产生实际文件改动。
4. 推送资格自证失败（exit=128），前后 `ls-remote` 一致，「未推送」有机器证据。
5. **降级清单**（真实缺口，非合规替代）：
   - 降级 1：未装 hook → 仅跑 `md_check` + `link_check`，pre-commit 全链 11 项与 `pre-push-check` 未跑（零改动无提交对象）。
   - 降级 2：单会话自审 → 未开第二独立会话复审，缺独立复审。
6. **能力边界诚实声明**：本实测证明的是「同源 clone + 显式开工令」能读出规则并复述金丝雀；**不能证明宿主自动注入**——这与 ADR-011 的结论一致，不构成接入失败，但不应被夸大为「规则已自动生效」。

未选 ① 的原因：存在 2 项明确降级。未选 ③ 的原因：无阻塞点，8 步全部执行到位。

---

## 七、D-1~D-7 逐项汇报（rules/15）

**D-1 规则改动交付分级**：**规则库未改动，无全文义务。** 本次 `AGENTS.md` 与任一 `rules/` 分册均未改动；唯一写动作 `git config --local credential.helper ""` 改的是本地 `.git/config`（非规则文件、非工作树跟踪文件）。

**D-2 改动清单**：
- `TRAE-project` 仓库内：**零文件改动、零 commit**（`git status --short` 为空，`git status -sb` 领先/落后均 0）。
- 仓库外：新增本报告 1 份（`../规则库接入验证实测报告_2026-11-20.md`），不进规则库工作树。
- 本地 git 配置：`credential.helper` 置空（已声明，非仓库文件）。

**D-3 对账结果**：本次为只读实测，未改动任何文档，故无影响面。逐份核对：`AGENTS.md`、`AGENTS-GLOBAL.md`、`README.md`、`PITFALLS.md`、`skills/INDEX.md`、`workflows/INDEX.md` 均**未改动**；`docs/BACKLINKS.md` 经 `link_check.sh` 刷新后内容与原提交一致，未产生 diff。无文档/实现不一致项。

**D-4 记忆收录说明**：本次**不写入**规则库记忆。理由：只读验证任务，不产生机制性规则；不认领 `docs/CLAIMS.md`；不触发并发协议。落点：无。

**D-5 验证与同步状态**：
| 校验 | 命令 | 输出 | 退出码 |
| --- | --- | --- | --- |
| 会话自检 | `sh scripts/session_start_check.sh` | 见 3.2 整段；`自检通过：可以开工` | 0 |
| md 完整性 | `sh scripts/md_check.sh` | `[P-004] md 完整性校验通过` | 0 |
| 链接与结构 | `sh scripts/link_check.sh` | `[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md` | 0 |
| 推送资格 | `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` | `fatal: could not read Username ... terminal prompts disabled` | 128（预期失败＝通过） |
| 工作树 | `git status --short` | 空 | 0 |
| 同步 | `git status -sb` | `## main...origin/main`（ahead 0 / behind 0） | 0 |

同步状态：本地与远端同为 `4035b87`，ahead 0；**未推送**，前后 `ls-remote` 见第五节。

**D-6 沉淀与待确认**：本次为只读验证，**不沉淀** skill/workflow（无新增机制，且红线禁止改库）。待确认（交由维护者裁决，见第八节）：3 条规则平台适配建议。

**D-7 依据核验**：**本次无业务/政策类结论，D-7 不适用。** 全部结论为仓库接入流程的可验证事实，不涉及财税口径或法规条款。

---

## 八、角色切换自检 5 问（AGENT-ADAPTER 开工前置）

1. **谁撰写、谁审查？是否同一会话？** 本次产物由 WorkBuddy 单会话撰写并自审，撰写与审查为同一会话。
2. **是否开第二个独立复审会话？** 未开；按降级口径标注「降级：未独立复审」，并在第六节降级清单中声明缺口与风险承接方。
3. **是否有子 Agent 能力？如何拆分生产与审查？** 平台具备派发能力，但本次任务边界为只读实测、无文件改动，未派发独立复审；生产/审查未物理隔离，以 D-1~D-7 逐项自检替代，此为已声明降级。
4. **交付是否含 D-1~D-7？** 含，见第七节逐项。
5. **是否按 rules/12 声明未完整读取的文件？** 本次按指定清单读取，均完整读取、无截断；未整库通读，未读文件不在本次判定范围内，无需声明「未完整读取」。

---

## 九、规则与平台冲突 —— 仅提建议，不改规则

以下均为建议，本次**未改任何规则文件**：

1. **P-001「长期记忆物理载体只有 /workspace 与 GitHub 远端」与平台冲突。** 该条属 AGENT-ADAPTER 第〇节定义的「环境特定条目」，依赖 TRAE 沙箱；WorkBuddy 的工作区路径为 `C:/Users/.../spaces/...`，无 `/workspace`。**建议**：外部 Agent 统一按效力分层把 P-001 标为「环境特定、不适用」，不照搬。本次已如此处理。
2. **S-004「可本地 commit 以便跑门禁」与「零改动只读验证」存在口径张力。** 本次零改动，`md_check`/`link_check` 在零提交状态下亦通过，故未 commit。**建议**：在 S-004 或 AGENT-ADAPTER 降级表补一句——零改动场景无需为跑门禁而 commit，与现有「零改动只读验证档」口径统一，避免外部 Agent 为凑门禁制造无意义提交。
3. **规则假设「外部 Agent 无子 Agent 能力」，本平台具备派发能力，属能力超配。** **建议**：把相关表述由「无子 Agent」调整为「是否启用独立复审由 Agent 声明并记录」，避免能力超配时被误判为违规，也避免能力不足时漏声明。

---

## 可验证事实部分

以下为本报告明确给出、可通过仓库命令复核的标准与结果，无篡改：
- 指定开工脚本为 `sh scripts/session_start_check.sh`，实测整段输出见 3.2，退出码 0。
- 金丝雀标记为 `CANARY-TRAE-7F3A9C`，见于 `AGENTS.md` 第 99 行，实测复述成功。
- 探针题答案：题 1 = `scripts/session_start_check.sh`；题 2 = `CANARY-TRAE-7F3A9C`。
- 实测 commit `4035b87`；任务前后 `git ls-remote origin` 输出逐字节一致。
- `git config --local credential.helper ""` + `GIT_TERMINAL_PROMPT=0 git push --dry-run origin main` 实测退出码 128、失败即通过。
- `md_check.sh`、`link_check.sh` 实测退出码均 0；`git status --short` 实测为空。
- 接入 8 步与 D-1~D-7 的逐项记录，均基于本次实际执行的命令与输出。

## 主观推测部分

无。（本报告未纳入任何未经实测验证的推断；第六节关于「金丝雀不能证明宿主自动注入」为依据 ADR-011 原文的效力判定，非推测。）
