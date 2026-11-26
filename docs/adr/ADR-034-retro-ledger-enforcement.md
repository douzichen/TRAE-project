# ADR-034：复盘台账强制——覆盖锚＋ENFORCE 阻断、状态/证据机检、fact_digest 强制粘贴

- 日期：2026-11-26
- 状态：已接受（主会话依用户 2026-11-26'落库'裁决）
- 关联：[P-034](../../PITFALLS.md)、[P-047](../../PITFALLS.md)、[ADR-025](ADR-025-mechanical-root-cause-elimination.md)、[ADR-033](ADR-033-precipitation-dispatch-and-mirror.md)、[schedules/daily-retro.md](../../schedules/daily-retro.md)

## 背景

2026-11-26 三日（11-22～24）复盘合规审计，逐日判定：11-22 部分合规、11-23 部分合规、11-24 不合规（台账失真）。证据：

1. **台账失真**：11-24 复盘报告建议记账 3 条（P-045～P-047），[RETRO-LOG](../handoff/RETRO-LOG.md) 却记"无新增坑（末条仍 P-044）"；三条全部未落库，P-045/P-046 编号后被 11-25 条目复用，P-034 正文自述撞号在先——台账与报告无机械对账。
2. **retro_pending_check 告警模式失效**：上线后 14 笔提交未覆盖台账，恒退 0 仍判"通过"——与 P-019/P-034 同族（布置≠完成），人工纪律两次失效后第三次仍靠同一机制。
3. **pitfall_check 三词 grep 放行**：只验「根因」「状态」「证据」三词存在，字段可为空壳——状态无枚举（出现"已修复/已落条款/机制已定"等账本模板未定义值）、证据无实质载体（无文件引用、无命令输出）。
4. **报告数字手算漂移**（P-036）：`fact_digest.sh` 上线但未强制粘贴，报告正文可不附 [FACT] 输出即落库。

## 候选方案

| 方案 | 内容 | 结论 | 理由 |
| --- | --- | --- | --- |
| A（采纳） | 覆盖锚＋ENFORCE 阻断＋状态枚举/证据实质校验＋fact_digest 强制粘贴 | 采纳 | 机械可执行、判定定义式（有锚、sha 可验即合规），无人工环节 |
| B（否决） | 维持告警＋人工纪律 | 否决 | P-019/P-034 两度复发证明无效；本轮 14 笔提交未覆盖仍"通过"是第三次实证 |
| C（否决） | 新建复盘总索引/独立建议台账 | 否决 | 撞 ADR-030 单一来源与 ADR-033 反双轨；同一信息两处维护必漂移 |
| D（否决） | 引入 CI | 否决 | ADR-028 已否决；本地 pre-commit 即可承载，不引入外部依赖 |

## 决策

1. **`scripts/retro_pending_check.sh` 升级**：① 覆盖锚——2026-11-26 起的 RETRO 行必须以 `（覆盖至 <sha7>）` 结尾（全角括号），sha 为 7～40 位十六进制且 `git cat-file -e` 通过；② strict 模式——`ENFORCE=1` 时存在任一缺口（回看窗口内日期无 RETRO 行；≥2026-11-26 行缺覆盖锚或 sha 无效）退出码 1，默认恒退 0 告警（保持 session_start_check 兼容）；③ 判定依据改暂存区内容优先。
2. **`scripts/pitfall_check.sh` 升级**：状态枚举校验（规范词 已落实|待落实|已升级|已闭环|已记录|部分落实 之一开头，祖传词双轨见决策 9）＋证据分级校验（强证据：反引号代码片段 / file:line 引用 / 无（待落实）任一，ENFORCE 下必须；裸文件名弱证据仅告警）；判定依据暂存区内容优先；ENFORCE=1 阻断、默认告警。
3. **schedules「执行后验证」增主会话落库核对条款**：主会话落库时必须先跑 `sh scripts/fact_digest.sh` 并把 [FACT] 完整输出附入落库记录或 D-5；派发会话报告无 [FACT] 输出本身不判无效，但主会话落库前须以本机 fact_digest 输出核对报告数字，报告中未出现在 [FACT] 输出的数字不得引用。
4. **台账与账本补录**：RETRO-LOG 头部增格式说明、追加 11-24 更正／11-25 补跑／11-26 当日三行（均带覆盖锚）；P-034 增升级记录、新增 P-047。
5. **祖传豁免**：2026-11-26 之前的 RETRO 行不带覆盖锚属合法（不追溯）；只约束新增行。
6. **暂存区判定原因**：判定依据为 `git show :docs/handoff/RETRO-LOG.md`（失败回退工作区文件）——"补 RETRO 行的提交"在该提交自己的 pre-commit 时点上，新增行只存在于暂存区，工作区/HEAD 版本均无该行；不读暂存区则该提交必然被自身门禁阻断，机制自举失败。
7. **schedules 任务内容（L21）不动**：主会话落库核对属主会话落库审查契约（派发会话无落库动作），写在「执行后验证」节即可；改 L21 须同步调度器实例，存在 P-019 式同步风险——故本条款明确"调度器 message 未改动、无需同步"。
8. **接线**：pre-commit 中两脚本调用均改 `ENFORCE=1`（照 skills_index_check 的 SKILL_META_ENFORCE 风格）；retro_pending_check 由"无 `|| exit 1` 的纯告警行"改为 `|| exit 1` 阻断行。
9. **状态值双轨**：状态值校验采"规范词＋祖传词"双轨，存量 9 条不改写（审计资产只增不减），新增条目须用规范词。

## 否决项及原因

- **B（维持告警＋人工纪律）**：P-019/P-034 两度复发证明"提醒型"机制无效，本轮 14 笔提交未覆盖仍"通过"为第三次实证。
- **C（新建复盘总索引/独立建议台账）**：与 RETRO-LOG、PITFALLS 重复登记，违反 ADR-030 单一来源；同构 ADR-033 否决的"双轨索引"模式。
- **D（引入 CI）**：ADR-028 已否决；pre-commit 本地门禁已覆盖本仓库运行形态，CI 引入外部依赖与双源判定。

## 什么条件下应推翻本决策

1. ENFORCE 两次误伤合法提交（如外部场景、紧急修复）→ 降回告警＋改按日阻断，须新 ADR。
2. 覆盖锚格式在实践频繁漏填 → 改"最近 RETRO 日期＋git log 区间"判定；若祖先校验仍挡不住"当天先记行后裸奔"，改按"锚 sha ≥ 当日最后提交"判定。
3. 状态枚举覆盖不了未来合法状态 → 经 ADR 扩枚举，不得删枚举。
4. fact_digest 输出过长贴全文挤占上下文预算 → 改贴指定行（日期/HEAD/PITFALLS 三行）。

## 对抗审查与零上下文测试（2026-11-26）

独立反方"有条件通过"，提出 7 条，主审逐条裁决处置：

1. ①覆盖锚语义（锚后同日提交不受覆盖，存在"记行后裸奔"空间）→ 处置：sha 校验追加祖先校验（`git merge-base --is-ancestor`，不在当前提交历史中即报缺口）；脚本头部注语义边界——覆盖锚＝复盘报告生成时审阅的仓库 HEAD，落库提交本身及其后的同日提交属次日复盘内容（限明限制，见推翻条件②）。
2. ②两套真相（retro 读暂存区、pitfall 读工作区，提交窗口内判定不一致）→ 处置：pitfall_check 同改暂存区内容优先，与 retro 同模式，输出注明判定依据。
3. ③审计史改写（状态归一化曾改写 9 条存量状态值）→ 处置：全部回退为原值；枚举改"规范词＋祖传词"双轨，祖传词仅存量豁免、新条目禁用（决策 9）。
4. ④证据形式化（反引号/文件名可空壳满足，真伪不可机判）→ 处置：强/弱分级——强证据（反引号、file:line、无（待落实））ENFORCE 下必须；弱证据（裸文件名）仅告警并建议升级为 file:line 或命令输出；语义真伪仍属文本审查，如实降级。
5. ⑤「执行后验证」条款矛盾（原"报告第一段必须粘贴否则无效"与派发沙箱无法跑本机 fact_digest 冲突）→ 处置：条款改写为主会话落库契约——主会话落库前必跑 fact_digest 并附 [FACT] 输出，派发报告无 [FACT] 不判无效，数字以本机输出核对（决策 3）。
6. ⑥临时文件竞态（固定名 tmp 并行运行互相覆盖）→ 处置：两脚本临时文件均改 `$$` 后缀＋trap 清理。
7. ⑦清晨误伤窗口（00:00 复盘未落库前 ENFORCE 提交即被挡）→ 处置：列为已知限制——当日补跑属合法路径（先补行再提交）；误伤复发按 rules/10 升级。

零上下文测试：新会话仅凭常驻件走链路 [AGENTS.md:48](../../AGENTS.md)（红线 8：坑必须落成防复发机制、每日复盘→[rules/10](../../rules/10-lessons.md)/[rules/06](../../rules/06-quality.md)）→ [rules/06:51](../../rules/06-quality.md)（每日定时复盘条款，任务真源指向 schedules）→ [schedules/daily-retro.md:52](../../schedules/daily-retro.md)（主会话落库核对条款）→ [RETRO-LOG 头部格式行](../handoff/RETRO-LOG.md)（覆盖锚格式说明），可定位"复盘→落库→锚校验"全链路，无卡点；结论：通过。

## 相关链接

- 决策前身：[ADR-025 复盘机械化处置](ADR-025-mechanical-root-cause-elimination.md)（告警版上线依据）、[ADR-028 度量与门禁修订](ADR-028-measurement-and-gate-revision.md)（D 方案否决先例）
- 单一来源与反双轨：[ADR-030 版本标识与外部草案](ADR-030-version-identity-and-external-drafts.md)、[ADR-033 沉淀分发与镜像](ADR-033-precipitation-dispatch-and-mirror.md)
- 坑账本：[PITFALLS.md](../../PITFALLS.md)（P-019/P-034/P-036/P-047）
- 落点文件：[schedules/daily-retro.md](../../schedules/daily-retro.md)「执行后验证」、[scripts/retro_pending_check.sh](../../scripts/retro_pending_check.sh)、[scripts/pitfall_check.sh](../../scripts/pitfall_check.sh)、[scripts/fact_digest.sh](../../scripts/fact_digest.sh)、[docs/handoff/RETRO-LOG.md](../handoff/RETRO-LOG.md)
