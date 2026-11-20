# ADR-022：外部 Agent 实测排班三棒收口——接入可行，红线全达成

- **状态**：已接受（2026-11-20）
- **背景**：ADR-021 八项处置后唯一遗留未决"外部 Agent 实测排班"。采用串行排班（WorkBuddy→豆包工作→Codex），统一提示词（单一来源：S-004 接入流程 + AGENT-ADAPTER 第〇节效力分层 + 只读红线）与统一验收表 A1~A9，逐棒裁决并将暴露问题修入库后再发下一棒。
- **裁定**：
  1. **接入可行性成立**：三棒核心红线全部达成——金丝雀复述、探针题、效力分层执行（S-005 按存档对待、P-001 按环境特定处理）、`push --dry-run` exit 128 阻断、`ls-remote` 前后一致未推送、D-1~D-7 交付。未发现"不可接入"级阻塞。
  2. **三棒判定**：第一棒 WorkBuddy 通过；第二棒豆包工作通过（贡献 P-025 真缺陷）；第三棒 Codex **有条件通过**——2 项缺口记 P-026（本地落后 1 未察觉：本地 `b9b36fe` vs 远端 `901fbc6`，其 ls-remote 输出与本地 HEAD 两证据并存却未对比；fetch 被拒后用陈旧内部 ref 声明"降级等效"实为降级失真）。核心验证证据不受缺口影响。
  3. **实测驱动的规则演进（全部落库）**：AGENT-ADAPTER 新增第〇节"效力分层"（防存档蓝图/否决项被当机制，三棒实证生效）；S-004 v1.2（零改动免 commit、Git Bash 显式路径、helper 空值重置含 global 层）；P-025（门禁排序固定 `LC_ALL=C`）；P-026（版本核对唯一权威=ls-remote 对比本地 HEAD，内部 ref 不得作"已同步"结论）；降级表 bash 行补"不得自建模拟脚本替代"。
  4. **否决项**（复活条件见下）：①session_start_check.sh 加 PowerShell 回退——双实现维护成本高且必然漂移（P-005 同类），合法替代已存在（降级表"逐项手工对照清单"档，模拟脚本属超授权实现偏移）；②credential.helper 清空改为可跳过——豆工作实测证明 local 空值已阻断 global GCM（缓存 token），无绕过实证；③"能力超配由 Agent 自判启用独立复审"改条款——两棒实证（豆包工作、Codex 均有能力自判未启用且无实害）支持维持现状，观察关闭。
- **影响面**：规则库对外部 Agent 开放接入的可行性由推测转为三平台实证；后续新平台 Agent 接入按本 ADR 的提示词模板＋验收表执行，无需重新排班论证。
- **复活条件**：新平台 Agent 接入出现"不可接入"级阻塞；降级失真/模拟超授权模式复发；存档蓝图误读复发——任一复发即按"复发即升级"重审。
- **证据**：`reports/field-test-1-workbuddy-2026-11-20.md`、`reports/field-test-2-doubaowork-2026-11-20.md`、`reports/field-test-3-codex-2026-11-20.md`；裁决与演进落库提交 `4035b87`、`b9b36fe`、`901fbc6` 及本 ADR 提交。
- **关联**：[ADR-021](ADR-021-universal-hardening-eight-dispositions.md)（八项处置与实测排班渊源）、[ADR-019](ADR-019-startup-sync-gate.md)（落后不得开工——P-026 缺口依据）、[S-004](../../skills/S-004-rulebase-onboarding.md)、[AGENT-ADAPTER](../AGENT-ADAPTER.md)、PITFALLS P-025/P-026。
