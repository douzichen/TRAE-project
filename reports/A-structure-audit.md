# A 路审计报告：结构与一致性（只读审计）

- 审计对象：`/workspace` 规则库（AGENTS.md、rules/00~12、PITFALLS.md、docs/adr、skills、workflows、schedules、scripts、.githooks）
- 审计方式：逐文件通读 + 摘要/细则对照 + 证物逐条核对 + 门禁脚本实跑
- 审计日期：2026-11-18
- 审计约束遵守情况：未改动任何既有文件；未执行 git 提交/推送/分支等操作（仅脚本自身内部调用 git）。**注意**：`link_check.sh` 自身会重写并 `git add docs/BACKLINKS.md`（见 P1-10），因此运行它会带来文件写入与暂存副作用，这不是审计方的修改。

## 一、门禁脚本实跑输出（原样记录）

```
$ sh scripts/md_check.sh
[P-004] md 完整性校验通过
exit=0

$ sh scripts/link_check.sh
[LINK] 链接与结构校验通过，已刷新 docs/BACKLINKS.md
exit=0

$ sh scripts/context_budget.sh
[P-010] 最小必读集合计 150 行（上限 150）
[P-010] 上下文预算校验通过
exit=0
```

三个脚本均通过，但"通过"不等于规则自洽：上表 150/150 已无任何余量；且脚本覆盖范围小于规则声称的范围（见 P1-1、P1-2）。

## 二、P0（会导致规则被误执行或互相冲突）

### P0-1 红线 #1"读完规则库"与 12"禁止整库加载"直接互斥
- 证据：`AGENTS.md:37`（红线 1："动手前先读完规则库，不凭记忆办事"）对照 `rules/12-context-budget.md:25`（"**禁止**'为了保险把 `rules/` 全读一遍'"）与 `rules/12-context-budget.md:24`（"只读与本任务相关的 1~2 册"）。
- 问题：同一份铁律体系给出两条相反的加载指令，且两条都被标为硬性要求；按红线 1 执行会违反预算，按 12 执行会被判"跳读/未读完"。
- 为什么有害：执行者只能二选一，任一选择都可被后续审查判为违规；规则从"约束"退化为"事后追责工具"。

### P0-2 分册索引要求"12 每次会话开始必读"，但预算口径的最小必读集不含 12
- 证据：`AGENTS.md:65`（12 的"何时必读"＝"每次会话开始、规则库增长时"）；`AGENTS.md:25-31`（固定阅读顺序只有 AGENTS→00→01→02）；`rules/12-context-budget.md:22-24`（常驻仅 AGENTS.md，固定仅 00/01/02）；`scripts/context_budget.sh:8`（core_set 仅 4 个文件）。
- 问题：若照索引每次会话读 12，实际必读量为 150+44=194 行，直接越过 150 行上限；若照预算不读 12，则违反索引"何时必读"。当前 150/150 的"通过"正是建立在"不读 12"之上。
- 为什么有害：预算校验的绿灯本身依赖违反索引；任何人想给 12 增加内容都会立刻触发矛盾。

### P0-3 每日复盘的定时任务 message 只要求读 AGENTS.md 与 PITFALLS，跳过固定必读 00/01/02
- 证据：`schedules/daily-retro.md:21`（message 第 1 步："先完整读 /workspace/AGENTS.md 与 /workspace/PITFALLS.md"）对照 `AGENTS.md:25-31`（"会话启动阅读顺序（固定，不得跳读）"：AGENTS→00→01→02）；且 `schedules/daily-retro.md:18` 要求"与调度器 message 必须逐字一致"、`AGENTS.md:77` 规定该文件是真源。
- 问题：自动复盘这一高频执行通道，被真源文件自身指定为"只读总纲+账本"，明确跳过了用户背景（01）、复述与 DoD（02）；而 06 又要求它按 D-1~D-6 汇报。
- 为什么有害：定时任务每天都会以"合规"姿态违反总纲的固定阅读顺序，且因为是真源文件，无法用"调度器副本过期"解释；这正是 P-008 类型的"自动任务无法满足规则"复发。

### P0-4 `delivery_report.sh` 的 D-1 只覆盖 AGENTS.md，与 D-1 已扩至 rules 分册冲突
- 证据：`rules/02-intake-and-dod.md:15`（D-1：改动 "AGENTS.md **或任一 `rules/` 分册**" 必须给新增段+全文）；`rules/02-intake-and-dod.md:21`（声称该脚本"每次提交自动生成 D-1（含全文）"）；`scripts/delivery_report.sh:13`（仅 `grep -qx 'AGENTS.md'`）、`:20`（否则输出"AGENTS.md 未改动，无全文义务"）。
- 问题：改 rules 分册时，脚本会输出"无全文义务"，与 D-1 的强制要求相反；P-009 声称"② D-1 范围扩到任一 rules 分册"，但机械代理没有同步扩大。
- 为什么有害：这是"机器生成草稿—人工照抄"链路，脚本的否定结论会直接诱导执行者漏交全文，且脚本输出本身会成为"已按 DoD 执行"的伪证。

## 三、P1（可维护性问题）

### P1-1 宣称"总纲超 100 行即拦截"，但没有任何脚本检查这一项
- 证据：`AGENTS.md:73`（"本总纲超 100 行即拦截"）；`rules/12-context-budget.md:18`（总纲 100 行、超限处置）；`docs/adr/ADR-003...:25`；而 `scripts/context_budget.sh:18-22` 只遍历 `rules/[0-9][0-9]-*.md`，全文无 AGENTS.md 行数判断。
- 问题：三条文件宣称的机器硬指标在实现中缺失；当前 AGENTS.md 88 行，一旦涨到 101 行不会有人拦。
- 为什么有害：虚假的保障比没有保障更危险——审查者会误以为该维度已被覆盖。

### P1-2 门禁输出引用 P-010，但坑账本没有 P-010
- 证据：`scripts/context_budget.sh:11,15,21,24` 均以 `[P-010]` 报错；`PITFALLS.md` 只到 `P-009`（第 102 行止），且 `scripts/md_check.sh:19-27` 强制编号"从 P-001 连续递增"。
- 问题：预算机制这一整类防复发规则在账本中没有宿主条目，输出编号悬空。
- 为什么有害：门禁报错指向账本查无此条，复盘者无法按编号追溯根因；也说明该机制的"记账闭环"没做。

### P1-3 README 目录索引漏登记：rules/12、context_budget.sh、ADR-002~004
- 证据：`README.md:10-22` 的 rules 树列到 11 即结束，无 `12-context-budget.md`；`README.md:53-57` 的 scripts 清单无 `context_budget.sh`（也无 `tool_entrypoints.sh`）；`README.md:46-49` 的 `docs/adr/` 只列 ADR-001，实际有 4 条（`docs/adr/` 目录）。
- 问题：README 是"东西该放哪"的入口文件（`README.md:72`），也是 S-001 派发模板要求子 Agent 必读的文件（`skills/S-001-subagent-dispatch.md:14`）。
- 为什么有害：接手者按 README 找不到预算分册与预算门禁，P0-2 的预算规则更容易被整册忽略；D-3 对账若照 README 核对也会漏项。

### P1-4 跨 Agent 适配文档的红线条数与门禁清单均过期
- 证据：`docs/AGENT-ADAPTER.md:46`（"全部红线共 10 条"）对照 `AGENTS.md:35-47` 实际 11 条；`docs/AGENT-ADAPTER.md:38`（"完整门禁三件套：md_check + link_check + delivery_report"）对照 `.githooks/pre-commit` 实际还强制跑 `context_budget.sh`。
- 问题：外部 Agent 按适配文档执行，会少守一条红线、少跑一项阻断门禁。
- 为什么有害：这是本仓库对"豆包/千问/DSH/WorkBuddy"的唯一适配口径，错误会被各环境复制扩散。

### P1-5 04 要求"以统一词表为准"，但全库不存在任何词表
- 证据：`rules/04-roles-and-dispatch.md:39`（"科目、字段、状态值等以统一词表为准，同义不同名一律打回"）；全仓库检索"词表"仅此一处，无对应文件、无生成脚本、无索引登记。
- 问题：条款指向一个不存在的资产，且"打回"动作没有可依凭的判定物。
- 为什么有害：这是不可执行的硬约束，审查者要么忽略它，要么以个人记忆当词表，回到"凭记忆办事"。

### P1-6 待确认事项清单被多处引用，但从未规定落盘位置
- 证据：`rules/07-pending-and-handoff.md:5-7`（要求"汇总一份清单并持续维护"，字段齐全，但未规定文件/章节/命名）；`rules/03-skill-sync.md:15`、`rules/10-lessons.md:8` 都要求"登记进待确认事项清单"。
- 问题：清单没有唯一落点，无法核查"是否登记"，也无法跨会话延续；07 自己又强调"不能散落在对话里"。
- 为什么有害：同步失败、待落实坑这些必须闭环的事项，最终仍会随会话消失；"已登记"可被口头声称。

### P1-7 PITFALLS 多条"已落实"条目的机制描述与当前文件不符
- 证据：
  - `PITFALLS.md:59`（P-004 声称校验"（新增时）入口路径存在"）；`scripts/md_check.sh:7-52` 实无此项，检查 7（`:46-52`）实际是"关键分册存在 + 总纲含路径字符串"。
  - `PITFALLS.md:78`（P-006 声称"AGENTS.md 顶部新增「用户背景」章节"）、`PITFALLS.md:88`（P-007 声称 AGENTS.md 有「指令接收与边界确认」章节）、`PITFALLS.md:50`（P-003 声称 AGENTS.md 有「记忆收录的显式说明」章节）；当前 AGENTS.md 无这三个章节，对应内容分别在 `rules/01-user-profile.md:5-13`、`rules/02-intake-and-dod.md:5-10`、`rules/04-roles-and-dispatch.md:9-17`；`scripts/md_check.sh:50-52` 只能匹配 `rules/01-user-profile.md` 这一路径字符串，不能校验"章节不得被删"。
  - `PITFALLS.md:38`（P-002 机制仍写 `scripts/agents_diff.sh`）；该文件已不存在（`scripts/` 目录）。
- 问题：账本是审计证物，其"防复发机制"栏的落点必须可复查；上述条目指向的章节/脚本已迁移或删除，却仍标"已落实/已升级"。
- 为什么有害：复盘与审查会按账本去核对一个不存在的机制，得出"已防住"的错误结论；"章节固化"类防线实际只剩路径字符串匹配，删掉整节内容也不会被拦。

### P1-8 同一任务的 ID 在 06 与 schedules 双写，且真源声明相互覆盖
- 证据：`rules/06-quality.md:46`（含任务 ID `._LP-ABG40ZAUH`、时间、内容摘要）对照 `schedules/daily-retro.md:12`（同 ID，声明"唯一事实源"）；`schedules/daily-retro.md:28` 反过来要求改 ID 时"同步更新 rules/06"。
- 问题：AGENTS.md:77 说真源是 schedules，但 06 保留了一份可独立漂移的副本；两处都写"以我为准"。
- 为什么有害：ID 或授权范围一变，两处不同步就会出现"两个真源"，P-005 型的多环境分叉会在仓库内部重演。

### P1-9 09 的"复用率过低"没有阈值与统计口径，条款不可判定
- 证据：`rules/09-precipitation.md:22`（"统计任务中引用已有 skill 的比例，复用率过低说明沉淀没生效"）。
- 问题：没有指标定义、统计周期、阈值，也没有任何采集方式（无脚本、无记录字段）。
- 为什么有害：无法验证的条款只能靠感觉执行，与 04:35"禁止'实现良好'这类无法验证的表述"自相矛盾。

### P1-10 `link_check.sh` 名为校验，实为写入：会改写并暂存 BACKLINKS，且有扫描盲区
- 证据：`scripts/link_check.sh:64-65`（重写 `docs/BACKLINKS.md` 并 `git add`）；`scripts/link_check.sh:16`（凡以 BACKLINKS.md 结尾的链接一律跳过死链检查）；`scripts/link_check.sh:8` 的扫描范围不含 `prompts/`、`reports/`、根目录入口文件。
- 问题：一个 pre-commit 阶段的"校验"脚本会修改工作区并操作暂存区，使"只读校验"不成立，也可能把 BACKLINKS 的变更静默并入任意提交；同时它自己生成的索引不受死链检查、`prompts/QUESTION-BANK.md`（`rules/06-quality.md:50` 引用）不在扫描内。
- 为什么有害：审计与门禁的可信度依赖"校验不改状态"；有副作用的校验难以复现，也会让"是否改过文件"无法用 diff 自证。

### P1-11 01 的"业务以用户判断为准"与 05 的"合规不由用户裁量"未在 01 互链，表面互斥
- 证据：`rules/01-user-profile.md:5`（"财税业务口径、税法适用、账务处理以用户的专业判断为准"）对照 `rules/05-requirement-review.md:10`（"'合规'结论不由用户裁量"）。
- 问题：优先级只在 05 单边声明，01 作为"每次会话必读"的分册没有指向 05；只读 01 的执行者会得到"用户说了算"的结论。
- 为什么有害：01 是固定必读、05 是按需读，最容易只读到前者；这正是"摘要/单册被当成全部"的失败模式。

## 四、P2（措辞与体验）

- **P2-1** `rules/03-skill-sync.md:7` 要求"安装副本与镜像的字节数、修改时间须一致"，同文件 `:13` 又说"不做重复比对"。同一册内对同一动作给出"须做/不做"两种口径，建议明确"用户原话为外部环境条款，本仓库以 md_check 为对应物"的边界句放在条款紧邻处。
- **P2-2** `rules/08-alignment-and-versioning.md:27` 的提交五步只写 "md_check + link_check + 生成草稿"，漏了实际阻断的 `context_budget.sh`（`.githooks/pre-commit:4`），失败时执行者会不知道是哪道门禁。
- **P2-3** `rules/06-quality.md:42`"让规则库变难用的新增属负收益"、`:16`"重大决策"均无可判定标准（"难用"无指标、"重大"未映射到 06:7-11 的轻/中/重）。
- **P2-4** `rules/09-precipitation.md:5`（"经用户认可之后"必须沉淀）与 `:12`（"任务审查通过时"触发）触发主体不一致（用户 vs 主 Agent 审查）；且 `rules/09-precipitation.md:5` 的"任何一个任务"与 `:12` 的"验收即触发"可能造成每个任务都被要求出新 skill。
- **P2-5** `rules/07-pending-and-handoff.md:5`（"开始任何实质工作之前"先汇总清单）与 `rules/02-intake-and-dod.md:5`（"第一动作是复述需求"）未规定先后，执行者可能先列清单再复述或反之。
- **P2-6** `rules/06-quality.md:49` 的降级动作是"检查昨日是否已复盘"，`schedules/daily-retro.md:33` 的降级动作是"每日首次会话执行同一份任务内容"；一个偏检查、一个偏执行，降级时行为不一致。
- **P2-7** `rules/01-user-profile.md:14` 引用"TRAE 官方《补充职业背景信息到系统配置》"，无链接、无版本、无落点，无法核查。
- **P2-8** `PITFALLS.md:70`（P-005）状态写"已闭环"，不在 `rules/10-lessons.md:7` 定义的"已落实/待落实/已升级"三值内；`md_check.sh` 也不校验状态枚举，状态字段实际处于自由文本状态。
- **P2-9** `AGENTS-GLOBAL.md:24` 的新项目装门禁步骤只要求跑 `md_check.sh`，与 pre-commit 实际四道门禁不一致（同类问题见 P1-4）。
- **P2-10** 预算零余量：`scripts/context_budget.sh` 输出"最小必读集合计 150 行（上限 150）"，判据是 `-gt 150`（`:16`），当前恰好卡线；任何一行新增都会阻断提交，应主动下调或调整拆分（属维护体验问题，但与 P0-2 叠加后会放大）。

## 五、证物逐条核对（PITFALLS"已落实/已升级"条目）

| 条目 | 声称机制 | 核对结果 |
| --- | --- | --- |
| P-001 | pre-push 自动恢复密钥与 `~/.ssh/config`（443+代理 18080） | **属实**：`scripts/pre-push-check.sh:7-21` 完整实现，`.git/config:6` 已设 `hooksPath=.githooks` |
| P-002 | 曾用 `agents_diff.sh`，现由 `delivery_report.sh` 生成 D-1 全文 | **部分属实**：脚本存在且挂 pre-commit，但 D-1 只覆盖 AGENTS.md（见 P0-4）；旧脚本已删除，机制栏仍引用（见 P1-7） |
| P-003 | AGENTS.md 内「记忆收录的显式说明」章节 | **落点已失真**：章节现在 `rules/04-roles-and-dispatch.md:9-17`（见 P1-7） |
| P-004 | md_check 四项校验含"（新增时）入口路径存在" | **部分不实**：`scripts/md_check.sh` 无入口路径检查（见 P1-7） |
| P-005 | S-001 第一节加"开工前先同步最新版本" | **属实**：`skills/S-001-subagent-dispatch.md:15` |
| P-006 | AGENTS.md 顶部「用户背景」章节 + md_check 检查 7 防误删 | **落点不符**：章节在 `rules/01-user-profile.md`；检查 7 只匹配路径字符串（见 P1-7） |
| P-007 | AGENTS.md「指令接收与边界确认」章节 + 检查 7 | **落点不符**：章节在 `rules/02-intake-and-dod.md`；检查 7 不校验章节内容（见 P1-7） |
| P-008 | ADR-002 修正三处冲突，含定时任务授权边界 | **属实**：`docs/adr/ADR-002...:21-23`、`rules/06-quality.md:12` |
| P-009 | 路由表、D-1 扩围、08 五步、红线 #7 改挂 06、06 例外、link_check 孤立分册、BACKLINKS 重生成 | **基本属实**：`AGENTS.md:6-23/43/69`、`rules/08:25-31`、`rules/06:8`、`scripts/link_check.sh:34-44,64`；但 D-1 的机械落地未跟上（P0-4） |

## 六、明确"未发现"的类别

- **分册索引指向错误**：未发现。`AGENTS.md:51-65` 的 13 条索引与 `rules/` 实际文件名逐一对应，路由表 12 条指向亦无错册。
- **06 与 08 的实质矛盾**：未发现。两者分工（决策方法 vs 对齐/版本）清晰，仅有 08 门禁列举不全（P2-2）与"影响面表/对账表"表述重叠，不构成冲突。
- **02 与 06 的实质矛盾**：未发现。轻/重分级与 DoD 可并存；"规则条款一律属重"的例外已覆盖 02 的"单份文档修订属轻"。
- **孤立分册/死链**：未发现。`link_check.sh` 实跑通过，BACKLINKS 覆盖 12 册且每册至少被一册引用。
- **skills/workflows 索引漏登记**：未发现。`skills/INDEX.md` 与唯一 skill 一致，`workflows/` 为空且索引注明"暂无"。

## 七、修复优先级建议（不在本次执行范围）

1. 先解 P0-1/P0-2：给红线 1 加"按 12 的加载策略"限定，并把 12 从"每次会话必读"改为"涉及预算/规则膨胀时读"，同时明确最小必读集口径。
2. P0-3：改写 `schedules/daily-retro.md` 的 message 阅读清单，纳入 00/01/02 与 12 的完整性声明。
3. P0-4/P1-1/P1-2：把 `delivery_report.sh` 的 D-1 扩到 rules 分册；给 `context_budget.sh` 加 AGENTS.md 100 行检查；在 PITFALLS 补 P-010 或改输出编号。
4. P1-3/P1-4/P1-7：同步 README、AGENT-ADAPTER 与 PITFALLS 的落点，使"索引—正文—证物"三方一致。
