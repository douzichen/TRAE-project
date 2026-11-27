# ADR-035：本地专属规则机制（.local-rules 不入 git）与本地决策 L 系列编号

> 注（2026-11-27，ADR-037）：IRON-0002 已升格为 rules/16；本 ADR 的外置机制保留，仅用于确实不宜上传的内容。

- 日期：2026-11-26
- 状态：已接受（2026-11-26，用户要求"本地规则不上传 GitHub 且不被覆盖"）
- 关联：[ADR-017](ADR-017-cross-project-operating-model.md)、[ADR-030](ADR-030-version-identity-and-external-drafts.md)、[ADR-033](ADR-033-precipitation-dispatch-and-mirror.md)、[ADR-034](ADR-034-retro-ledger-enforcement.md)

## 背景

1. 用户要求新增"逐功能点测试项"规则（IRON-0002），但明确禁止上传 GitHub，且要求 pull/reset --hard 不得覆盖。
2. 外部机器把"本地专属规则"机制登记为 ADR-033，与本仓 [ADR-033](ADR-033-precipitation-dispatch-and-mirror.md)（沉淀分发与只读镜像）撞号；本地决策占用 ADR 全局编号后，索引无法唯一定位。
3. "本地 commit 不 push"会让仓库永久 ahead；本仓配双远端（origin + github-backup），一次误推即外泄，且与 [ADR-017](ADR-017-cross-project-operating-model.md) 的"规则唯一通道"冲突。
4. `.gitignore` 本身被跟踪，写进去等于把"仅本机"的排除也推给所有人；须区分"正常流程不入库"与"强制手段可绕过"两种状态，不得写成绝对保证。

## 候选方案

| 方案 | 内容 | 结论 | 理由 |
| --- | --- | --- | --- |
| A（采纳） | 正文与入口同放工作区 `.local-rules/`，`.git/info/exclude` 排除，pre-push 闸门防误推 | 采纳 | 正常流程不产生 git 对象（exclude 默认跳过 add）；误 add 有第二道闸门；可机检 |
| B（否决） | 本地 commit 不 push | 否决 | 永久 ahead；一次误推即外泄；与 ADR-017 单一真源冲突 |
| C（否决） | `.gitignore` 跟踪式排除 | 否决 | 排除规则随仓库分发，无法只在本机生效；`clean -fdx` 会删；ADR-033 已否决同类双轨 |
| D（否决） | skip-worktree / assume-unchanged | 否决 | reset/checkout 可清除；上游更新照常流入，等于假隔离 |

## 决策

1. **落点一**：正文 `.local-rules/IRON-0002-per-feature-test-items.md` 与入口 `.local-rules/ENTRY-IRON-0002.md` 同放工作区，仅用反引号写路径，不写 wiki/相对链接。
2. **落点二**：入口模板 `ENTRY-IRON-0002.template.md` 以占位符保存，安装脚本回填本机绝对路径与 SHA256；换机只需复制正文与模板后重跑。
3. **落点三**：`scripts/local_rules_install.sh` 幂等——路径归一（消 `./`，含空格/中文路径可用）、算哈希、建目录、回填入口、exclude 不存在才追加、回读校验；不写死 `/workspace`。
4. **落点四**：`scripts/local_rules_check.sh` 扫描入口，正文缺失/哈希不符/无哈希工具均判失败（fail-closed）；`ENFORCE=1` 退 1，默认退 0 告警。
5. **落点五**：`.githooks/pre-push` 追加闸门——待推送区间或 `git ls-files` 出现 `.local-rules/` 即拒绝推送。
6. **落点六**：`scripts/session_start_check.sh` 在既有检查后调用校验脚本并打印结果，非阻断。
7. **落点七**：本地决策使用 L-001 起独立系列，不占 ADR 全局号；外部机器的"ADR-033（本地规则）"应改名 L-001。
8. **落点八**：正常流程**不 git add/commit** `.local-rules/`；exclude 为第一道防线，pre-push 为第二道。
9. **L 系列载体**：`.local-rules/L-INDEX.md`（编号｜标题｜对应 ADR/规则｜建立日期｜状态），L-001 机制启用、L-002 IRON-0002。
10. **闸门定位**：pre-push 只防误操作，**不防** `--no-verify` 或改 `core.hooksPath` 的有意绕过；该风险与全部门禁同源。

## 机制边界（机检事实）

- `.git/info/exclude` 不被跟踪，排除只在本机成立；`pull`/`reset --hard` 不删除被排除的未跟踪文件，`git clean -fd` 亦不会，只有 `git clean -fdx` 会。
- 强制手段可绕过：`git add -f` 能入索引，`--no-verify` 能跳钩子；闸门只保证"误操作不会推上去"。
- 哈希能发现"正文被改动/入口与正文不匹配"，不能恢复正文；恢复＝以当前正文重跑安装脚本。沙箱重建、换机、new clone 均不带 `.local-rules/`。

## 外部机器对账步骤（可执行）

1. 在外部机器把本地 ADR-033(IRON) 改名登记为 L-001（文件移到其本地规则目录，不占 ADR 全局号）。
2. 导出其 5 个未推送提交的 diff 存档（`git format-patch origin/main..HEAD -o <备份目录>`）。
3. `git fetch origin && git reset --hard origin/main` 丢弃未推送提交（先完成第 2 步备份）。
4. 在该机如需恢复历史本地规则再跑 `scripts/local_rules_install.sh`（回填本机路径与哈希）；IRON-0002 已退役，不再安装。
5. 把原 5 个提交的能力按本仓 ADR-035 与 `docs/adr/ADR-036-nightly-full-review.md` 重新落，不直接 merge，避免与全局 ADR-033/034/035/036 撞号。

## 残余风险

- `git clean -fdx` 会删除 `.local-rules/`；沙箱重建/换机/new clone 均无本目录，须重跑安装脚本。
- 哈希只能发现改动，不能恢复正文；入口被删同样需重跑安装脚本。
- 强制手段（`git add -f`、`--no-verify`、改 hooksPath）可绕过两道防线，机制仅覆盖误操作。

## 什么条件下应推翻本决策

1. 未来需要多机自动分发该规则 → 改为加密仓库或私有包，须新 ADR（L 系列不能承载分发）。
2. pre-push 闸门误伤正常推送 ≥2 次 → 降级为告警＋改由 exclude 单防线，并记入坑账本。
3. 本地规则超过 10 条、会话启动校验拖慢 >2 秒 → 改为按需校验（仅本次任务相关规则）。
4. 强制绕过成为常态（连续两次发现 `add -f`/`--no-verify` 路径实推）→ 改加密仓库并重审闸门位置。
5. `.local-rules` 因 `clean -fdx` 或沙箱重建丢失两次 → 改为独立本地裸仓（bare repo）托管，另立 ADR。

## 相关链接

- 前身与先例：[ADR-017 跨项目运行模型](ADR-017-cross-project-operating-model.md)、[ADR-030 版本标识与外部草案](ADR-030-version-identity-and-external-drafts.md)、[ADR-033 沉淀分发与镜像](ADR-033-precipitation-dispatch-and-mirror.md)、[ADR-034 复盘台账强制](ADR-034-retro-ledger-enforcement.md)
- 衔接分册：[rules/03 技能同步](../../rules/03-skill-sync.md)、[rules/06 问题与决策质量](../../rules/06-quality.md)
- 落点文件：[scripts/local_rules_install.sh](../../scripts/local_rules_install.sh)、[scripts/local_rules_check.sh](../../scripts/local_rules_check.sh)、[.git/info/exclude](../../.git/info/exclude)
- 不入库载体：`.local-rules/IRON-0002-per-feature-test-items.md`、`.local-rules/ENTRY-IRON-0002.md`、`.local-rules/L-INDEX.md`（仅本机可见）
