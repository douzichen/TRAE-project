# ADR-033：沉淀的分发与读取——扩既有索引补契约（乙），飞书知识库只读镜像机制化（丙）

- 日期：2026-11-25
- 状态：已接受（主会话依用户 2026-11-25 确认裁决）
- 关联：[rules/09](../../rules/09-precipitation.md)（读取契约落点）、[rules/03](../../rules/03-skill-sync.md)（镜像条款落点）、[rules/04](../../rules/04-roles-and-dispatch.md)（派发引用补链）、[P-045](../../PITFALLS.md)、[docs/AGENT-ADAPTER.md](../AGENT-ADAPTER.md)、[ADR-017](ADR-017-cross-project-operating-model.md)、[ADR-030](ADR-030-version-identity-and-external-drafts.md)、[ADR-031](ADR-031-tool-path-judgement.md)、[ADR-032](ADR-032-customer-data-landing.md)

## 背景

沉淀资产（skills/、workflows/）要求跨设备、跨 Agent 可读可取用。2026-11-25 调研证据：

1. `grep -n "S-001" rules/04-roles-and-dispatch.md` 零命中——rules/04 派发条款不引用 S-001 派发模板，按 04 干活的 Agent 无模板入口（模板只出现在 rules/09 与 skills/INDEX）。
2. [docs/AGENT-ADAPTER.md](../AGENT-ADAPTER.md)「必读顺序」六项无任何 INDEX 入口：外部 Agent 读完常驻件后不知道 skills/INDEX、workflows/INDEX 的存在，无法按任务检索沉淀。
3. workflows/INDEX.md 无触发词列，按任务检索 workflow 无抓手。
4. skills/INDEX.md 无适用角色字段：外部验证型 Agent 无法一眼判断哪些 skill 允许自己用、哪些是存档蓝图。
5. 飞书知识库发布仅有 [P-045](../../PITFALLS.md) 的事故记录（同一发布任务工具路径不稳、身份错配漂移到浏览器模拟），无任何机制条款——谁可发布、如何留痕、镜像与仓库不一致以谁为准均无规定。

用户业务事实：会在**无终端设备**上经飞书翻阅沉淀内容。纯"git pull 后读仓库"路径覆盖不了该场景，需要一条只读镜像通道与读取契约互补。

## 候选方案

| 方案 | 内容 | 结论 | 理由 |
| --- | --- | --- | --- |
| 甲（否决） | 新建 docs/PRECIPITATION-INDEX.md 统一总索引 | 否决 | 与 skills/INDEX、workflows/INDEX 重复登记，同一信息两处维护必漂移；同构 ADR-030 否决的"外部草案与仓库双轨"模式 |
| 乙（采纳） | 扩既有索引＋读取契约＋修断链：skills/INDEX 加「适用角色」「镜像」两列、workflows/INDEX 加「触发词」列、rules/09 补读取四步、rules/04 补 S-001 引用 | 采纳 | 单一登记不双轨，检索入口仍在各 INDEX；改动面小且每处可挂机械校验 |
| 丙（采纳） | 飞书知识库只读镜像机制化 | 采纳 | 条件成立：用户确认存在无终端设备的阅读需求；镜像定位为用户本人在飞书的阅读版，仓库仍是唯一权威副本（ADR-017），镜像不承载条款效力 |
| 丁（否决） | 只改提示词不落规则 | 否决 | 会话记忆会丢（P-003 同构），不落条款等于把复发留给记忆，无门禁与复盘抓手 |

## 决策

1. **rules/09 新节「外部 Agent 读取沉淀的标准动作」**：读沉淀四步——① `git pull --ff-only origin main` 并报出拉取前后 commit（对验 `git ls-remote origin main`）；② 按总纲路由表定位分册；③ 按 skills/INDEX、workflows/INDEX 触发词列（或 `grep -l "<触发词>" skills/*.md`）定位沉淀文件；④ 交付中声明"已加载哪些沉淀资产"。外部验证型 Agent 不安装 skills 副本、不写任何镜像。
2. **rules/03 新节「外部只读镜像」**：镜像定位＝用户本人在飞书的阅读版，仓库唯一权威、唯一可编辑（ADR-017），镜像不参与 md_check 等门禁对账；镜像首行必写"源 commit ＋ 生成时间"；发布由主会话经用户本人 lark-cli 执行、先填 TOOL-PATH-CARD（ADR-031）、写后回读；发布当天在 skills/INDEX「镜像」列登记；外部 Agent 禁写镜像；不一致以仓库为准，按过期镜像执行出错按 rules/10 升级。
3. **rules/04 补引用**：「工具与执行路径判定」节后补一行——派发子 Agent 必用 S-001，读沉淀资产的同步动作按 rules/09 标准动作执行。
4. **S-004 补同步行**：正文首条 bullet 前加"读本 skill 前先 git pull --ff-only origin main 并报出 commit；沉淀资产一律以仓库最新版为准"。
5. **skills/INDEX 加「适用角色」「镜像」两列**（表头上方附列义说明，逐行补值）；**workflows/INDEX 加「触发词」列**（W-001 填入）。
6. **skills_index_check.sh**：照「触发词」列同款写法增「适用角色」列非空校验，告警级不阻断。
7. **md_check.sh 7b**：增 rules/09「读取沉淀的标准动作」、rules/03「外部只读镜像」两条存在性锚点（防整节被删，只查存在性不查语义）。
8. **AGENT-ADAPTER 只加 1 行指针**：必读顺序节补一条指向 rules/09 标准动作，细则在 09 册；接口文档 129/130 贴顶不超。

## 否决项及原因

- **甲（统一总索引）**：与两个既有 INDEX 重复登记，同一信息两处维护必漂移；同构 ADR-030 否决的"外部草案与仓库双轨"模式。
- **丁（只改提示词）**：提示词随会话消失，会话记忆会丢；不落条款则无机械校验与复盘抓手（P-003 同构）。

## 什么条件下应推翻本决策

1. 五个外部 Agent 实测均稳定 pull、且用户不再用无终端设备阅读 → 镜像机制（丙）下线，只保留乙的索引扩展与读取契约，另立 ADR。
2. 镜像发生一次"按过期镜像执行出错"且复发 → 镜像下线或补机械校验（如镜像首行源 commit 与仓库 HEAD 对验），须新 ADR。
3. INDEX 加列后实测发现率无提升（外部 Agent 仍定位不到触发词/角色入口）→ 撤销加列，回退纯表述修订，另立 ADR。
4. AGENT-ADAPTER 去重完成后仍无法容纳指针（130 行贴顶）→ 标准动作并入 S-004/S-001，接口文档只留一行链接，另立 ADR。

## 对抗审查与零上下文测试（2026-11-25）

独立反方（非修改者）提出 8 条，逐条处置：

1. "镜像"同词三义稀释 03 册 → 已在 03 同步条加限定"仅指 git 副本"。
2. 四步对本地有提交/无终端档不可执行 → 步①改"无本地提交才要求一致、有则报 ahead 数、已握手豁免"，步③增无终端静态检索降级。
3. 步④声明义务与交接必填重复 → 并入 09 交接必填栏。
4. 校验假绿（外部无 hook 告警级、角色列任意串过检、锚点只锚标题）→ md_check 7a 补 03/09 存在性、7b 改锚正文短语；角色列改白名单（告警级）。
5. 镜像台账悬置且列义矛盾 → 列义增"已发布未留痕"态；rules/07 登记补登事项，到期 2026-12-31。
6. 03×14 依据不实（14 全文无 S-004 引用）→ 依据改引 AGENT-ADAPTER 快速接入链路。
7. S-004 版本列漏更 → bump v1.4 并补来源。
8. AGENT-ADAPTER 129/130 贴顶 → 既有挂起事项（去重后并入快速接入行），下轮增量前先处理。

零上下文测试：新验证型 Agent 仅凭 AGENT-ADAPTER 与 AGENTS.md，经 :32 指针→rules/09 四步→skills/INDEX 正确答出 S-001 编号/角色/触发词与禁止事项（不装副本、不写镜像、不推送），全程无卡点；结论：通过。

## 相关

- 上级总纲：[AGENTS.md](../../AGENTS.md)
- 落点条款：[rules/09 外部 Agent 读取沉淀的标准动作](../../rules/09-precipitation.md)、[rules/03 外部只读镜像](../../rules/03-skill-sync.md)、[rules/04 角色分工与派发](../../rules/04-roles-and-dispatch.md)
- 参见：[ADR-017 跨项目运行模型](ADR-017-cross-project-operating-model.md)、[ADR-030 版本标识与外部草案](ADR-030-version-identity-and-external-drafts.md)、[ADR-031 工具路径判定](ADR-031-tool-path-judgement.md)、[ADR-032 客户数据入库判定](ADR-032-customer-data-landing.md)、[P-045](../../PITFALLS.md)、[docs/AGENT-ADAPTER.md](../AGENT-ADAPTER.md)
