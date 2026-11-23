# ROLE-INSTANCE-TABLE（角色实例表·项目侧登记模板）

> 来源：[ADR-029](../docs/adr/ADR-029-layered-agent-chains-and-role-relativization.md)｜依据：[rules/04](../rules/04-roles-and-dispatch.md)「层级协作链与角色相对化」
> 用法：**多 Agent 共同参与同一项目时，开工前填写下表并逐段合并**进项目侧 AGENTS.md 项目特定层（禁止整文件覆盖，见 [ADR-018](../docs/adr/ADR-018-clean-copy-repull.md)）。单 Agent 模式（默认两层）无需登记。

| 角色 | 实例（平台/会话名） | 职责 | 读写边界 |
|---|---|---|---|
| 定夺人 | （填：用户） | 业务口径、接受与否 | 不担技术把关 |
| 主导者 | （填：派发＋评审方） | 拆解、派发、评审 | 对规则库只读；项目域写入按 rules/04「写入权」授权 |
| 执行者/本域主导者 | （填：执行＋可再派发方） | 对上交账；对子 Agent 派发＋审查 | 与 rules/04「产出终审归属」同构 |
| 独立反方 | （填：只读审查方） | 对抗审查，按需召唤 | 只读；结论须逐条回应；不设强制关卡 |

- 链式 ≤4 层；超限按「切片交付、逐片验收」拆片，不加层。
- 每层只审下一层交付物，不自审；退回经直接上游重审并附失败清单。
- 实例表登记不替代 [ADR-024](../docs/adr/ADR-024-external-agent-instruction-observation.md) 分档声明。
