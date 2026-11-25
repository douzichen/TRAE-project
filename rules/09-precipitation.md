# 经验沉淀：技能固化与工作流

> 归属总纲：[AGENTS.md](../AGENTS.md)｜分册编号：09｜本文件为唯一细则来源

- **任务验收后必须沉淀**：任何一个任务执行正确、经用户认可之后，必须把它的执行步骤固化成一个小 skill（可复用的标准步骤说明，含输入、步骤、判定标准），不能做完就算。
- **skill 再拼成 workflow**：多个 skill 按依赖顺序串起来，形成一张 workflow 工作图（谁先谁后、每步的输入输出、卡在哪一步返回），作为后续同类任务的主线路径。
- **持续迭代**：新任务若与已有 workflow 重合，优先复用并按差异修订，不另起一套；发现步骤缺失或失效，回写更新对应 skill。
- 沉淀产物同样入库、同样走审查，遵守"文档与实现对齐"的要求。

### 沉淀的触发点（不靠人提醒，按条件自动触发）

1. **验收即触发**：任务审查通过时，必须同时产出 skill 或说明复用已有 skill；沉淀是"完成定义（DoD）"的一部分，没沉淀不得标记完成。
2. **重复即触发**：同类操作出现第 2 次，必须抽出 skill；第 3 次仍手工重复，视为违规。
3. **返工即触发**：出现审查退回、改坏回滚、返工时，必须回写对应 skill 或补"坑"条目，失败经验不得白丢。
4. **口径变更即触发**：PRD / FSFSD 变更后，必须检查相关 skill 与 workflow 是否过期，同步更新。

### 落实方式（机制优先于口头提醒）

- **目录即契约**：`skills/` 存单个技能（含适用场景、输入、步骤、验收、来源 commit），`workflows/` 存流程图与节点说明；两者各带 `TEMPLATE.md` 与 `INDEX.md`。
- **交接必填**：每次交接必须写明"本次沉淀了什么 / 复用了哪个 skill 或 workflow / 为什么无需沉淀"，作为固定栏目。
- **新建先查索引**：建新 skill 前先查 `skills/INDEX.md`，同类者优先修订，不另起一套。
- **复用率衡量**：统计任务中引用已有 skill 的比例，复用率过低说明沉淀没生效。
- **检查即脚本**：防复发机制优先做成脚本并挂 git hook（`git config core.hooksPath .githooks`）；现有门禁清单与串联顺序以 `scripts/` 与 `.githooks/pre-commit` 为准（如 `md_check.sh` 校验 INDEX 登记与坑编号连续、`pre-push-check.sh` 做凭据自检、`delivery_report.sh` 生成交付草稿），本册不逐一枚举，避免脚本增减后清单漂移。机器能拦的不再依赖清单。
- **派发必用模板**：派发子 Agent 任务必须使用 `skills/S-001-subagent-dispatch.md`，填齐依据、边界、产出与验收；子 Agent 返回时按模板逐项核对。任务级具体约束只写进提示词，不写入本文件。

## 外部 Agent 读取沉淀的标准动作（2026-11-25，[ADR-033](../docs/adr/ADR-033-precipitation-dispatch-and-mirror.md)）

- **读沉淀四步**：① `git pull --ff-only origin main` 并报出拉取前后 commit——本地无未推送提交时须与 `git ls-remote origin main` 一致，有本地提交时改报 ahead 数（一次会话已按 [04](04-roles-and-dispatch.md) ADR-019 握手 pull 过的，①豁免）；② 按总纲路由表定位分册；③ 按任务检索 [skills/INDEX.md](../skills/INDEX.md)、[workflows/INDEX.md](../workflows/INDEX.md) 的触发词列定位沉淀文件（或 `grep -l "<触发词>" skills/*.md`；无终端无 git 的降级档按已同步的静态 INDEX 检索并在交付中声明版本滞后风险）；④ 已加载哪些沉淀资产并入 [09](09-precipitation.md)「交接必填」栏声明，不单列。
- 外部验证型 Agent 按本节读取，不安装 skills 副本、不写任何镜像；降级申报见 [AGENT-ADAPTER.md](../docs/AGENT-ADAPTER.md)；"先同步最新版再工作"的派发侧要求见 [04](04-roles-and-dispatch.md) 与 S-001。

## 相关分册

- 上级总纲：[AGENTS.md](../AGENTS.md)
- 参见：[10 坑账本](10-lessons.md)
- 参见：[03 技能同步](03-skill-sync.md)（副本同步与外部只读镜像）
