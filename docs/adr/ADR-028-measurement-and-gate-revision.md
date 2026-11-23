# ADR-028：度量与门禁修订——METRICS 移出工作区、closure_check 非阻断、pre-push 复核与 PowerShell 最小层

- **日期**：2026-11-23
- **状态**：已接受（2026-11-23）
- **关联**：[PITFALLS](../../PITFALLS.md) P-041~P-043、[rules/10](../../rules/10-lessons.md)（坑账本与避坑机制）、[rules/06](../../rules/06-quality.md)（重/轻分级）、[ADR-021](ADR-021-universal-hardening-eight-dispositions.md)（度量采集）、[ADR-012](ADR-012-gate-script-portability.md)（脚本可移植性）

## 范围声明（先读，防误读）

1. 本 ADR 只调整**度量采集的位置**与**复核门禁的阻断边界**，不改业务红线、不改 11 门禁的清单与序号。
2. `closure_check.sh` 为**非阻断**工具，**不计入门禁序号**；"11 门禁"口径保持不变。
3. 本文所列脚本属本轮修订的落地目标；是否上线以文件存在与自测输出为准，交付时须贴命令输出，禁止凭 ADR 文本宣称已生效。
4. 本 ADR 属重级（改变门禁行为与审计资产写入方式），按 [rules/06](../../rules/06-quality.md) 走对抗审查与 D-1~D-7。

## 背景与证据

- 2026-11-23 账本闭合复盘中暴露三类计量缺陷：状态码通配符误判（P-041）、体积与合计口径混用（P-042）、以正则筛候选替代全量重建（P-043）。
- 度量采集现状：每次提交由钩子向 `docs/METRICS.md` 追加一行。实测三种钩子挂载方式（pre-commit、commit-msg、post-commit+amend）**均在工作区留下脏改动**；其中 post-commit + amend 组合触发递归 **242 次**。根因是钩子写入被 Git 跟踪的审计资产，写入即构成新的工作区变更。
- 复核现状：11 门禁全部依赖暂存区（`git diff --cached`），无法在推送区间上复核；此外本环境**无 CI 服务可用**——账号无创建流水线的 push 权限，门禁脚本依赖暂存区语义，且 CI 属事后发现，无法阻止已推送内容。
- 跨平台现状：Windows 侧存在 PowerShell 计数脚本，其状态码解析出现过通配符误判（P-041），与 sh 侧口径存在漂移风险。

## 决策

### 1. METRICS 自动追加移出工作区

- 钩子不再直接修改 `docs/METRICS.md`。改为提交后写 `.git/metrics.log`（Git 管理目录内，天然不被跟踪、不产生脏树）。
- 新增 `metrics_collect.sh --flush`：由人工在交付或复盘时执行，把 `.git/metrics.log` 中的事件**一次性并入** `docs/METRICS.md`，并入动作走正常提交流程。
- **禁止**任何钩子直接改审计资产（`docs/METRICS.md` 等）；审计资产只能由显式命令改写并随提交入库。
- 依据：三种钩子挂载实测均留脏树；post-commit + amend 递归 242 次，说明"钩子内写被跟踪文件"这一路径不可通过参数调优收敛。

### 2. 新增 `closure_check.sh`（非阻断）

- 用途：闭合计算的双算校验——`入库 + 忽略 = 总数` 与 `总数 = 基数 − 消失件`，两式必须同时成立；同时内置状态码与体积口径的负样例自测。
- 行为：**无参数时直接跳过**（exit 0）；默认模式只打印结果与告警；**仅 `--strict` 才在失配时 exit 1**。
- 内置正负样例自测：至少含一条 ` M` 负样例（防 P-041 通配符误判）与一条"以 `.prev` 结尾"负样例（防 P-043 模式筛漏项）。
- **不接入 pre-commit 阻断点**，**不计入门禁序号**——避免出现"11 门禁"变成"12 门禁"的口径漂移。

### 3. pre-push 复核增强（最小阻断面）

- 推送前在**推送区间**（远端..本地）上复核，仅阻断两类：
  1. **secrets**：对推送区间内新增/修改内容做凭据扫描；
  2. **BACKLINKS 新鲜度**：`git diff --exit-code docs/BACKLINKS.md`，不一致即阻断（说明反向索引未刷新）。
- 其余检查一律**告警不阻断**，避免推送路径被大量误报卡死。
- **不引入 CI**：无 push 权限创建流水线、门禁依赖暂存区语义、CI 属事后发现，三条均构成否决理由。

### 4. PowerShell 最小层（唯一规范在 sh）

- Windows 侧只维护两个脚本：`closure_check.ps1` 与 `triage_untracked.ps1`。
- **sh 为唯一规范**；PowerShell 版仅做等价实现，并用**同组 fixtures 对拍**（同一输入，两侧输出必须逐字节一致，含负样例）。
- **不移植** `md_check`、`secrets_scan`、`paths_check`：三者的实现依赖 POSIX 工具链与暂存区语义，移植成本高于收益，且易产生第二套"看似等价"的判定。

## 替代方案（否决项）

| 否决项 | 否决理由 | 复活条件 |
| --- | --- | --- |
| 引入 CI 做门禁 | 无创建流水线的 push 权限；门禁脚本依赖暂存区；CI 事后发现拦不住已推送内容 | 获得流水线权限且门禁改为仓库态可判定 |
| 钩子继续直接追加 `docs/METRICS.md` | 实测三种挂载均留脏树，post-commit + amend 递归 242 次 | 出现不产生工作区变更的写入方式并有实测证据 |
| 用 amend 修正脏树 | 递归 242 次，不可控 | 不复活 |
| `closure_check` 接入 pre-commit 阻断 | 计数口径仍在演进，阻断会卡住正常提交，并使门禁序号口径漂移 | 连续两个复盘周期零误报后重新评估 |
| PowerShell 全量移植 sh 门禁 | 双实现漂移风险高，且 POSIX 依赖难等价 | 所有 fixtures 对拍通过且维护成本可接受 |
| 用正则筛候选做计数闭合 | P-043 已证假阴性（58 错成 57） | 不复活：闭合一律全量枚举重建 |

## 后果

- **正面**：提交不再因度量写入留脏树；计数闭合有独立工具与负样例；推送前能拦住凭据与反向索引过期；跨平台只保留最小等价层，减少漂移。
- **代价**：METRICS 不再实时更新，需人工 `--flush`；`closure_check` 不在提交路径上，依赖执行时主动调用；PS 层覆盖面小，Windows 侧无法跑全量门禁。
- **影响面**：

| 改动 | 直接效果 | 二阶影响 | 三阶影响 | 风险与缓解 |
| --- | --- | --- | --- | --- |
| METRICS 写入迁至 `.git/metrics.log` | 工作区不再因度量产生脏改动 | `docs/METRICS.md` 变为按需并入 | 台账时间粒度由"每次提交"变为"每次 flush" | 忘记 flush 导致事件堆积 → 交付清单固定检查项 |
| `metrics_collect.sh --flush` | 人工/交付时并入 | 并入即一次正常提交 | 审计链仍完整 | 重复并入 → 按事件行去重 |
| `closure_check.sh`（非阻断） | 双算可机械复核 | 默认跳过，不干扰日常提交 | 门禁序号口径不变 | 误报 → 只 `--strict` 返回 1 |
| pre-push 仅阻 secrets/BACKLINKS | 推送路径阻断面最小 | 其余问题降为告警 | 推送仍可能带非致命问题 | 漏放 → 下次评审复查 |
| PS 最小层（2 脚本） | Windows 侧能跑闭合与未跟踪归类 | fixtures 对拍保证等价 | 其余门禁仅 sh 可用 | 覆盖不足 → 明确声明平台限制 |

- **残余风险**：
  1. `--flush` 依赖人工触发，漏做会使 `docs/METRICS.md` 滞后；缓解为交付清单固定检查。
  2. `closure_check.sh` 非阻断，可能被跳过；缓解为复盘流程固定执行并留输出。
  3. 推送区间 secrets 扫描只能覆盖新增内容，历史泄漏不在范围。
  4. PS 层仅 2 个脚本，Windows 侧**不构成完整门禁**，如实声明，不当作等价合规。

## 回滚

1. 删除新增脚本：`scripts/closure_check.sh`、`closure_check.ps1`、`triage_untracked.ps1` 及其 fixtures。
2. 还原 `scripts/metrics_collect.sh` 至改动前版本（恢复钩子直接追加 `docs/METRICS.md`）。
3. 还原 pre-push 钩子至改动前版本（撤销区间 secrets 与 BACKLINKS 新鲜度阻断）。
4. 保留 `.git/metrics.log` 内已有事件，按需手工并入，不删除审计事件。
5. 在本 ADR 状态栏标记 **superseded**，并注明取代它的新 ADR；本文件不删除（审计资产只增不减）。

## 落地清单

- `scripts/closure_check.sh`（非阻断、`--strict`、内置 ` M` 与 `.prev` 负样例）。
- `scripts/metrics_collect.sh` 增加 `--flush`；post-commit 改写 `.git/metrics.log`。
- pre-push：仅阻断推送区间 secrets 与 `docs/BACKLINKS.md` 新鲜度。
- `closure_check.ps1`、`triage_untracked.ps1` 与同组 fixtures 对拍。
- [PITFALLS](../../PITFALLS.md) P-041、P-042、P-043 与本 ADR 互链。
