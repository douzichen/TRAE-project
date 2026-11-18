# 零上下文可用性测试报告（B 组）

> 测试方式：模拟从未参与本项目的工程师，只凭仓库文档走完"新增一条规则并提交"。
> 约束遵守：未修改任何既有文件；未执行 git 写操作/提交；只读 git 查询 2 次（`git status -sb`、`git config --get core.hooksPath` 与 `rev-parse`）。
> 测试时间：2026-11-18。

## 0. 样例规则

为让"该改哪一册"可判定，取样例规则 R：

> **R**：任何改动在提交前必须确认 git hooks 已生效（`core.hooksPath = .githooks`）；hooks 未生效时，校验结果不算数。

选 R 是因为它命中本仓库最核心的机制（提交时校验），能同时暴露路由、分级、交付、校验四段流程的问题。

## 1. 流程复现

### 1.1 启动阅读与声明
- 依据 `AGENTS.md:25-31` 的固定顺序：总纲 → 00 → 01 → 02，再按任务类型读对应分册。本次完整读取 AGENTS/00/01/02/04/06/07/08/09/11/12。
- `rules/12-context-budget.md:31` 要求交付时写明"已加载分册：00/01/02/08…"；`:29` 要求未读全时首行声明。本次完整读取，无声明义务。
- `rules/00-core.md:5` 要求动手前完整读 00，不凭记忆。

### 1.2 复述与边界确认
- `rules/02-intake-and-dod.md:5`：第一动作复述需求；`:6` 列边界并允许写"无明显边界问题，按以下理解执行"；`:7` 边界未获确认前不得动笔；`:9` 用户已明确批准时仍先复述再执行。
- 卡点：无人值守环境（本次 CI）无法获得确认，`:7` 字面上要求停手；`:6` 的自述是否等于确认，文档未定义。

### 1.3 定册（改哪一册）
- 路由表在 `AGENTS.md:6-21`。R 属"提交前的动作/门禁"，最贴近 `AGENTS.md:17` 的"文档一致性、提交推送、版本与 tag" → **`rules/08-alignment-and-versioning.md`**。
- 但 `rules/09-precipitation.md:23` 明确写了"检查即脚本……`git config core.hooksPath .githooks`"，09 也像。
- 依 `AGENTS.md:23`：取最贴近的一册，并在其"相关分册"补链接。判定：写入 08，并在 08 末尾"相关分册"（当前 `08:34-36` 只有 07、11）补 09。
- 结构硬要求：分册首行"归属总纲"、末尾"相关分册"（`AGENTS.md:70`；`scripts/link_check.sh:22-26`）；链接用标准相对路径（`AGENTS.md:71`）；新增分册还须登记索引并被至少一个其他分册引用（`AGENTS.md:72`；`link_check.sh:35-44`）。本次不新建分册。
- 若多条都像且无法归类：`AGENTS.md:23` 要求"记入待确认事项请用户确认"，与 `rules/01-user-profile.md:12`"文档形式一律 Agent 自定、不得抛给用户"直接冲突。

### 1.4 分级（决定要走多重的流程）
- `AGENTS.md:69`：修改或新增任何规则条款一律属"重"，不适用"单份文档修订属轻"的豁免。
- `rules/06-quality.md:7` 把"单份文档修订"列为轻；`:8` 的例外优先，规则条款一律重；`:11` 不确定按重。
- 重级附加产物：影响面表（`06:23`）、独立子 Agent 对抗审查（`06:27`）、ADR（`06:36`）、零上下文接手测试（`06:41`）、三版方案（`06:15`，`:18` 允许理由充分时只给 1 版）。
- 冲突点：`docs/adr/INDEX.md:18`"小改动、措辞修订不写 ADR" vs `AGENTS.md:69`"一律留 ADR"。

### 1.5 回滚
- `rules/11-rollback.md:5`：动手前先备回滚手段。
- `rules/08-alignment-and-versioning.md:18-21` 把 git 提交/revert 当回滚手段，但没写"已提交版本即可满足 11:5"；未提交的编辑没有还原点。

### 1.6 落笔产物（除分册本身）
- ADR：一条一文件放 `docs/adr/`，并在 `docs/adr/INDEX.md` 表格登记（`06:36`；`docs/adr/INDEX.md:7-12`）。
- 影响面表（`06:23`）：改动 → 直接效果 → 二阶 → 三阶 → 风险与缓解。
- 待确认清单（`rules/07-pending-and-handoff.md:5`）。
- 若判定 R 属"通用层"，`AGENTS-GLOBAL.md:17` 的层级表是否要同步，文档未写。

### 1.7 要跑的检查
- pre-commit 实际顺序：`md_check.sh` → `link_check.sh` → `context_budget.sh` → `delivery_report.sh`（`.githooks/pre-commit:4-8`）。
- `08:27` 只写了 md_check + link_check + 交付草稿，漏了 `context_budget.sh`。
- 预算硬指标（`rules/12-context-budget.md:14-18`）：最小必读集 150 行；任一分册 120 行；AGENTS.md 100 行。实测 88+15+20+27 = **150/150**，零余量。
- 链接/结构：`link_check.sh:11-19` 死链、`:22-26` 双向链接、`:29-32` 索引登记、`:35-44` 孤立分册；成功后 `:64-65` 自动重写并 `git add docs/BACKLINKS.md`。
- `md_check.sh:36-38`：skills/workflows 有未提交改动即拦截；`:41-44` 分支领先远端仅提醒。

### 1.8 要交付的 D-1～D-6
依据 `rules/02-intake-and-dod.md:15-20`：

| 项 | 本次应交付内容 |
| --- | --- |
| D-1 | 新增段原文 + 改动后 `rules/08` 全文（`:15` 明确"任一 `rules/` 分册"都算） |
| D-2 | 逐文件清单：`rules/08`、`docs/adr/ADR-005-*.md`、`docs/adr/INDEX.md`、自动生成的 `docs/BACKLINKS.md`（`:16`） |
| D-3 | 逐份对账 AGENTS.md / AGENTS-GLOBAL.md / README.md / PITFALLS.md / skills/INDEX.md / workflows/INDEX.md，写"改了哪节/为何无需改"（`:17`） |
| D-4 | 记忆收录：写什么、不写什么、理由与落点（`:18`；`rules/04:11-14`） |
| D-5 | 粘贴 md_check / link_check / context_budget / pre-push 实际输出 + ahead 0 + 哈希核对（`:19`；`08:31`） |
| D-6 | 沉淀了什么或为何无需沉淀；待确认/待办状态，无则"无悬置"（`:20`） |

- 机械代理 `scripts/delivery_report.sh:12-21` 只对 AGENTS.md 生成全文；改 `rules/08` 时输出"AGENTS.md 未改动，无全文义务"（`:20`），与 `02:15` 冲突。

### 1.9 提交与同步核对
- `08:27-31` 五步：`git add` 本轮改动 → commit（pre-commit 拦截）→ `git push origin main` → `git status -sb` 显示 **ahead 0** → `git rev-parse HEAD` 与 `git ls-remote origin main` 一致 → 把输出贴进 D-5。
- `rules/03:12-15` 的同步核对针对 skills/workflows；本次不改，可在 D-5 声明"不适用"（`:13`）。
- `08:19`"每个功能一个分支 + 一次合并"与 `08:28` 直接 `push origin/main` 冲突，规则改动走哪条未定。
- `08:20` 的"口径版本用 tag"是否适用于规则改动未写。
- `08:29` 的 ahead 0 不要求工作区干净：当前工作区已有 `M AGENTS.md`、`M rules/01`，仍显示 `## main...origin/main`。

### 1.10 收尾
- `rules/09:5`、`:12` 要求验收即沉淀；D-6 允许说明"无需沉淀"（`02:20`），但 09:5 的"必须"没有对应例外表述。
- `rules/12:31` 要求交付中写"已加载分册"。

## 2. 卡点清单

| 编号 | 级别 | 卡点 | 证据 | 改进建议 |
| --- | --- | --- | --- | --- |
| P0-1 | 会做错事 | 最小必读集刚好 150/150，路由到 00/01/02 的任何新增都会触发硬拦截；12 只说"把细则移出常驻集"，没有迁移规范 | `12:14-16`；实测 88+15+20+27=150；`AGENTS:73`；路由表 `AGENTS:11,12` 正指向 02/03 | 在 12 写出"当前用量 x/150"和超限迁移步骤（移到哪册、如何回归校验），pre-commit 输出剩余额度 |
| P1-1 | 需要猜 | ADR 是否必写：`AGENTS:69`"一律留 ADR" vs `docs/adr/INDEX.md:18`"小改动、措辞修订不写 ADR" | 同上 | 明确边界：规则条款变更一律 ADR；纯错字不写；措辞修订若改变可执行含义按规则变更处理 |
| P1-2 | 需要猜 | 无人值守时边界确认死锁；自述"无歧义"是否算确认未定义 | `02:6,7,9` | 增加例外：用户单条指令目标明确且无歧义时，自述边界即视为确认，不再等待 |
| P1-3 | 会做错事 | 交付代理与 D-1 冲突：改 rules 分册时不生成全文，反而提示"无全文义务" | `delivery_report.sh:12-21` vs `02:15` | 代理按 `rules/*.md` 逐个输出新增段 + 全文 |
| P1-4 | 需要猜 | 分支开发与直接推 main 两条路径并存 | `08:19` vs `08:28` | 明确规则改动走分支+PR，或在 08 删除分支条款/写明例外 |
| P1-5 | 需要猜 | "文档形式"归谁决策自相矛盾：归类失败要问用户 vs 不得把文档问题抛给用户；三版方案也要求用户选 | `AGENTS:23`、`06:15` vs `01:12` | 写明：归类与是否新建分册由 Agent 决定并留 ADR，用户只确认业务口径 |
| P1-6 | 会做错事 | D-2/D-5 受工作区脏状态污染：代理取 `git diff --cached` + `git diff`，会把别人的改动算成本轮；ahead 0 也不代表工作区干净 | `delivery_report.sh:7`；`08:29`；实测 `M AGENTS.md`、`M rules/01` | D-2 只按 staged 文件生成；流程开头强制"确认工作区干净或仅暂存本轮文件" |
| P1-7 | 会做错事 | D-3 要求对账，但 README 本身已失配：规则清单缺 12、脚本清单缺 context_budget、docs 标"待建" | `README.md:11-22,53-58,79`；`08:7`"先纠正再交付" | 先修 README；或在 08 明确"新增条款不触发 README 清单核对"的判据 |
| P2-1 | 不够顺手 | 11 要求备回滚，08 把 git 当回滚，两者未打通 | `11:5` vs `08:18-21` | 在 11 写明"已提交版本 + revert 即满足本条" |
| P2-2 | 不够顺手 | 通用层清单是否随新规则更新未定义 | `AGENTS-GLOBAL.md:17` | 增加一句：判定为通用层的条款需同步该表 |
| P2-3 | 不够顺手 | pre-commit 组成描述不全 | `08:27` vs `.githooks/pre-commit:4-8` | 08:27 补齐 context_budget.sh 与 delivery_report.sh |
| P2-4 | 不够顺手 | link_check 会静默重写并暂存 BACKLINKS，交付清单会多出文件 | `link_check.sh:64-65` | 在 08/README 写明该副作用及"必须随本轮提交" |
| P2-5 | 不够顺手 | 规则版本 tag 与提交信息格式未定义 | `08:20` | 给出规则库的 tag 规则与 commit 前缀 |
| P2-6 | 不够顺手 | 09"必须沉淀"与 D-6"可说明无需沉淀"口径不一 | `09:5,12` vs `02:20` | 在 09 增加"一次性条款修订可复用既有 skill 并在 D-6 说明" |
| P2-7 | 不够顺手 | 全流程依赖 hooks，却没有"确认 hooks 已启用"的步骤 | `09:23`；实测 `core.hooksPath=.githooks` | 在 08 第一步加 `git config --get core.hooksPath` 自检 |

## 3. 结论

能力较弱的 Agent 最可能这样走偏（按后果排序）：

1. **判成"轻"级**：只看 `06:7`"单份文档修订属轻"，漏掉 `06:8` 例外与 `AGENTS:69`，于是跳过对抗审查、ADR、影响面表。后果：重演 P-008 式的条款互斥，规则入库后才在下次会话炸出来。
2. **塞进 02 或 00**：凭"提交前行为"直觉写进常驻册，撞上 150/150 预算，为过闸删除或压缩既有条款。后果：规则静默丢失，且无 ADR 可追溯——这是最坏结果。
3. **信任交付代理**：看到"AGENTS.md 未改动，无全文义务"就不贴全文，直接违反 `02:15` 的 D-1。
4. **只 commit 不 push**（或只看 `git status` 不看 ahead 0），把"本地已提交"当"已交付"，导致其他环境读到旧规则（P-005 复发）。
5. **跳过 D-3**：README 继续缺第 12 册，后续 Agent 根本不知道有预算册，形成"读不完也不声明"的连锁偏差。

一句话：文档把"该做什么"写得相当完整，但**预算零余量**与**工具和规则打架**这两处，会让弱 Agent 做出"看起来完成了、实际破坏了规则库"的动作。

## 附：实测证据

- `wc -l`：AGENTS.md 88、00 15、01 20、02 27（合计 150）、08 37。
- `git config --get core.hooksPath` → `.githooks`（hooks 已启用）。
- `git status -sb` → `## main...origin/main`；`M AGENTS.md`；`M rules/01-user-profile.md`；未跟踪 `.cursorrules`、`CLAUDE.md`、`GEMINI.md`、`scripts/tool_entrypoints.sh`。
- `git rev-parse HEAD` 与 `git rev-parse origin/main` → 均为 `78120d4`。
