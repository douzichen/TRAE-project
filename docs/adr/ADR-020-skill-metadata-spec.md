# ADR-020：技能元数据化采用四栏规格＋机械校验，不做自动触发

- **状态**：已接受（2026-11-19 用户批准"甲+乙"方案）
- **关联**：[ADR-011](ADR-011-no-auto-injection.md)（本宿主无自动注入）、[ADR-012](ADR-012-gate-script-portability.md)（门禁可移植）、[skills/INDEX.md](../../skills/INDEX.md)、[scripts/skills_index_check.sh](../../scripts/skills_index_check.sh)、[rules/09](../../rules/09-precipitation.md)。

## 背景

- 用户提出：能否把规则库部分内容做成 Anthropic 式 skill，以便 Agent 自动触发。
- 经三名独立子 Agent 核查：仓库内**没有任何宿主"按 description 自动加载技能文件"的成功证据**——ADR-011 三次盲测失败、P-016 证实 `AGENTS.md` 不被自动注入、`skills/` 下无合法 YAML frontmatter、无任何装载路径约定。
- 同期实测发现机械漏洞：漏登记 `skills/INDEX.md` 会被 `md_check.sh` 拦截（exit 1），但删掉头部字段"判定标准（验收）"仍通过（exit 0）——**字段完整性无任何拦截**。

## 决策

1. `skills/S-001~S-004` 头部统一为四栏元数据：**触发词／不适用／完成判据／单一来源**。
2. `skills/INDEX.md` 增加"触发词"列。
3. 新增 `scripts/skills_index_check.sh`：默认告警模式，`SKILL_META_ENFORCE=1` 时阻断；已挂入 `.githooks/pre-commit` 的 [M6]。**已于 2026-11-19 转为阻断模式**——第二平台验证通过并留痕：Windows 11 / git-bash（`uname -s` = `MINGW64_NT-10.0-22631`），默认模式 A=0、`SKILL_META_ENFORCE=1` 模式 B=0，HEAD `51a9ec3`，仓库 `D:\TRAE-project`（满足 P-017/ADR-012 的转阻断前置）。注：此前一次验证误在 WSL2（`uname -o`=GNU/Linux）中执行，因与第一平台同源而不算数，已改在真 git-bash 复跑。
4. 元数据只写"何时用、不能用在哪、怎么算做完、依据在哪"，**不复述规则条款与阈值数字**（防双真相源）。

## 候选与否决项

| 方案 | 内容 | 判定 |
| --- | --- | --- |
| A | 四栏元数据＋机械校验 | **采纳**——成本为零（skills 不计入 160 行必读集预算）、可机械拦截字段删除、不宣称不存在的能力 |
| B | 全量技能化（YAML frontmatter＋S-000 路由 skill＋`skills/S-00x/SKILL.md` 目录制） | **否决**——无任何自动触发证据；目录制会绕过 `md_check.sh` 的 `skills/S-*.md` glob 使 INDEX 登记校验失效；S-000 会与 `AGENTS.md` 路由表形成两份真相源，且 `AGENTS.md` 已 99/100 行无余量 |
| C | 什么都不改 | **否决**——字段删除无拦截的漏洞已被实测证实 |

## 什么条件下应推翻本决策

1. 出现可验证的宿主技能自动加载能力（须有实测证据：不读任何文件即可按 description 命中）→ 重估 frontmatter 与目录制，须新 ADR。
2. `skills` 条目增长到 INDEX 手工维护不可靠 → 改为脚本生成 INDEX，须新 ADR。

## 相关

- [rules/09](../../rules/09-precipitation.md)
- [skills/INDEX.md](../../skills/INDEX.md)
