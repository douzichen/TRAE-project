# ADR-021：通用化加固——八项缺口处置

- **日期**：2026-11-20
- **状态**：已接受（部分：④ 中第二远端待用户粘 deploy key；条款一终局裁定**不建**，蓝图存档 [S-005](../../skills/S-005-absence-delegation-blueprint.md)，见下）。2026-11-20 经对抗审查裁定。
- **关联**：[P-021](../../PITFALLS.md)、[P-022](../../PITFALLS.md)；[ADR-012](ADR-012-gate-script-portability.md)（可移植写法）、[ADR-014](ADR-014-session-start-selfcheck.md)（开工自检）、[ADR-016](ADR-016-stale-terms-gate.md)（口径漂移）、[ADR-019](ADR-019-startup-sync-gate.md)（强制握手）；[rules/06](../../rules/06-quality.md)（复盘节奏）。

## 背景

- 2026-11-20 行业痛点分析裁定 8 项处置，其中"外部 Agent 排班"一项保留未决，其余 7 项的文件部分随本 ADR 落地。
- 同日 P-022 暴露推送链路单点：沙箱每日重建导致 SSH 密钥与出口端口均不可依赖，"能推送"是环境变量不是常量。
- 通用版约束：所有机制必须是仓库资产（脚本/模板/文件），不绑定特定沙箱、不绑定特定宿主，任何 Agent clone 后即可用；脚本一律按 ADR-012 可移植写法（禁 mktemp、绝对路径 rm、sed -i、readlink -f）。

## 决策（四部分）

### ① 度量机制（非阻断）

- 新增 `scripts/metrics_collect.sh`：每次 commit 自动向 `docs/METRICS.md` 追加一行提交事件，格式 `| 日期 | 提交信息首行截 40 字 | 11 门禁 | - |`。滞后一行语义：提交 N 的钩子记录提交 N−1 的事件（读 HEAD，不读 COMMIT_EDITMSG——pre-commit 阶段其内容陈旧，见 [P-023](../../PITFALLS.md)）。
- 挂载在 `.githooks/pre-commit` 末尾（`delivery_report.sh` 之后）：**非阻断度量，不计入门禁序号**；脚本身处 pre-commit，任何失败只打警告、结尾恒 exit 0，不得阻断提交；只做 `>>` 追加防递归。
- 新增 `docs/METRICS.md` 记三类指标：提交事件（脚本自动记）、拦截事件（提交被门禁拦截时，修复提交须补记一行）、坑复发（在对应 P 条目加"复发 N 次"，METRICS 记日期索引）。

### ② hooksPath 自检与探针题

- `scripts/session_start_check.sh` 在版本核对段后增 hooksPath 检查：`git config core.hooksPath` 非 `.githooks` 时打印警告——本地门禁不会自动运行；**只告警、不改退出码**，验证型 Agent 未装 hook 属合法状态，维护者主会话须先配置。
- `skills/S-001-subagent-dispatch.md`（v1.2）派单模板增"探针题（读入验证）"：指令末尾附一道答案取自规则库的探针题（例：开工令第 0 步执行哪个脚本？金丝雀串是什么？），子 Agent 首条回复答错即视为未读规则，打回重读。

### ③ 规则体检步

- `schedules/daily-retro.md` 复盘步骤末尾增第 7 步：每周日"规则体检"——扫一遍 rules/ 16 册与 ADR 索引，产出"过时/冗余/建议退役"候选清单（**只列不改**，附 file:line 依据），报用户裁决；非周日跳过。

### ④ 灾备三件套

- 新增 `scripts/backup_snapshot.sh`：在仓库父目录生成 `TRAE-project-backup-<日期>-<short-HEAD>.tar.gz` 全量快照（含 .git），重大交付后跑一次；快照不入库。
- 恢复演练步骤：clone GitHub → 核对 HEAD 与快照 short-HEAD 一致 → 跑 `scripts/session_start_check.sh` → 报告结果。
- 第二远端（灾备镜像，方案已定 2026-11-20）：GitHub 私有空仓 `douzichen/TRAE-project-backup`，与主远端同平台；凭据用**第二把 deploy key**（GitHub deploy key 单仓绑定，主库的 `deploy-key.pub` 不能复用，新钥公钥落库档案 `deploy-key-2.pub`，沿用仓库公钥档案惯例）。配置五步（在有凭据的环境执行一次，如用户本机 Git Bash）：①`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_backup -N ""`；②公钥添加到镜像仓 Settings→Deploy keys（勾写权限）；③`~/.ssh/config` 加 `Host github-backup`→`HostName github.com`＋`User git`＋`IdentityFile ~/.ssh/id_ed25519_backup`；④`git remote set-url --add origin git@github-backup:douzichen/TRAE-project-backup.git`（此后单次 `git push origin main` 逐 URL 双推，任一失败按 URL 分别报错、不互相阻断）；⑤推一次并核对两库 HEAD 一致。恢复演练以镜像库为主源。可推翻条件：GitHub 单点故障实际影响同步时，评估异平台（如 Gitee）镜像。
- 用户已建空私有仓（2026-11-20，`https://github.com/douzichen/TRAE-project-backup.git`）。会话侧已完成：第二密钥生成（`.secrets/id_ed25519_backup`，公钥档案 `deploy-key-2.pub`）、origin 双 URL（`set-url --add`）、pre-push-check.sh 扩展双密钥恢复＋github-backup 主机块、**主远端推送实证恢复（ahead 0，P-024 更正晨间误判）**。用户剩余唯一动作：把 `deploy-key-2.pub` 内容粘到镜像仓 Settings→Deploy keys→Add deploy key（勾选 **Allow write access**）——完成后单次 push 双推自动生效。配置完成前，本地快照（`backup_snapshot.sh`）为兜底。

## 对抗审查裁定（2026-11-20，独立 Red Team）

### 条款一（拟增 rules/07 用户缺席委托）：**否决，待重构**

否决理由：①轻/重定级由被授权主会话自判自批，缺席期"复审者"即代批者本人，[rules/06](../../rules/06-quality.md)"疑则按重"防线空转，复制"自写自审"坑；②"书面授权"无要件，口述一句即可被引作书面，范围/期限/撤回无强制字段；③与 rules/07"不得替用户默认确认"直接互斥，ADR 未提同步修改；④超期清退与"滥用即废止"均无认定者与时点，触发永远滞后。

重构要件（满足后须重新对抗审查）：定级须**独立子 Agent 签字复核**、存疑一律冻结等用户；授权须落成**仓库内文件**（范围/期限/撤回方式三字段必填），聊天原话仅作线索；先消解与 07 册内既有条款的互斥；代批 ADR 强制打"缺席代批"标签，用户回场首轮逐条复核；认定者与时点须可判定。

### 条款一终局裁定（2026-11-20，用户授权重构后两路子 Agent 正反重审）：**不建**

用户授权重构后，主 Agent 派两路子 Agent：甲（设计）按上述五要件产出完整重构蓝图（主审核验：合格——要件全覆盖、冲突已消解、可移植），乙（反方 Red Team）专攻"重构后仍会坏"。主审交叉裁决：**不建常设委托机制**，四条理由——①**需求零实证**：全库史无缺席损失事件，P-019 已由"冻结+补跑"化解，用户日均回场下冻结成本仅数小时；②**成本落在最强红线**：消解互斥须改 [rules/04](../../rules/04-roles-and-dispatch.md)"写入口唯一、按用户批准流程"并联动三册＋矩阵 3 格＋新门禁，为推演需求在安全根基上开洞属负收益；③**残留风险不可机械消除**：签字真实性、越权执行、范围语义越界只能靠回场复核事后发现，代批是终局决定；④**合法替代已存在**：计划性缺席按 [rules/02](../../rules/02-intake-and-dod.md)"预先授权例外"预先批准范围，未计划缺席冻结待确认（[rules/07](../../rules/07-pending-and-handoff.md) 本裁定已显式化）。

蓝图不弃用：完整设计（七字段授权文件 schema、UTC 双写机械判期、字段/期限双门禁、三册联动消解清单、对撞检查方法论、回滚六步、复活附加条件——范围排除项须含优先级变更、复核角色预指定、验证型与定时任务显式排除）已通用化沉淀为 [S-005](../../skills/S-005-absence-delegation-blueprint.md) 供新项目复用。**复活条件**：出现 1 次真实缺席损失实证，或用户预告连续多日缺席且需缺席期 P0 处置——满足后按 S-005 蓝图重构并重新对抗审查。本裁定的唯一落库条款：[rules/07](../../rules/07-pending-and-handoff.md) 新增"用户缺席期冻结"一行。

### 条款二（拟增 rules/13 ADR 合卷）：**修订后采纳**

修订点：①计数挂机械门禁（md_check 达 50 条未分卷即拦截），不靠人眼；②摘要强制"状态＋取代去向＋原文行号"三字段、与原文同提交更新；③凡被引用的 ADR 一律视同当前卷展开细读，摘要仅作索引，禁止凭摘要下结论（消解与 rules/12"禁用摘要代替细则"的冲突）；④可推翻条件改为可数阈值。条款已按修订版落入 [rules/13](../../rules/13-concurrency-and-lifecycle.md)「ADR 合卷」节。

## 否决项与可推翻条件

| 项 | 可推翻条件 |
| --- | --- |
| 度量机制 | 造成提交变慢超过 2s 即撤（回退 pre-commit 挂载行即可，账本保留） |
| 用户缺席委托条款 | 终局裁定不建（2026-11-20 正反重审）；复活条件＝1 次真实缺席损失实证，或用户预告连续多日缺席需 P0 处置，届时按 [S-005](../../skills/S-005-absence-delegation-blueprint.md) 蓝图重构并重审 |
| hooksPath 自检 | 告警被证实干扰只读 Agent 正常开工即降级为维护者文档说明 |
| 规则体检步 | 连续 4 周产出零候选即降频为每月一次 |
| ADR 合卷条款 | 可数阈值：摘要与原文行号不符累计 3 处，或出现 1 次"凭摘要下结论"被证实，即撤回分卷改为全量展开 |

## 相关

- `scripts/metrics_collect.sh`、`scripts/backup_snapshot.sh`、`scripts/session_start_check.sh`
- `docs/METRICS.md`、`schedules/daily-retro.md`、`skills/S-001-subagent-dispatch.md`、`.githooks/pre-commit`
