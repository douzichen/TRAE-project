# 会话开工令（模板）

> 用法：新会话或派单时，把下方代码块整段粘贴到首条消息。来源：[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)、[ADR-014](../docs/adr/ADR-014-session-start-selfcheck.md)。

```
开工令：
0. 同源与版本：先执行 `sh scripts/session_start_check.sh`，把输出整段贴进交付 D-5。
   - 若报「不在 git 仓库内」或脚本不存在：副本过旧或未 clone，先 clone / `git pull --ff-only origin main` 再重来，不得在旧副本上下"文件不存在"的结论（P-018）。
   - 退出码 1：按脚本每条的"处理/结论"修正后重跑；退出码 2：远端未核对，交付须声明。
   - 平台：POSIX 用 `sh`；Windows 在 Git Bash 中执行（PowerShell 无 `sh`，报 CommandNotFound 时按此处理，不得判定门禁失败）。
   - 落后须先 pull 再开工；锁定版本按用户指令声明豁免（[ADR-019](../docs/adr/ADR-019-startup-sync-gate.md)）。
1. 先按顺序读取：`AGENTS.md` → `rules/00-core.md`、`rules/01-user-profile.md`、`rules/02-intake-and-dod.md`；再按 `AGENTS.md` 路由表读与本任务相关的 1~2 册（交付类任务必读 `rules/15-delivery-dod.md`）。
2. 记录版本：`git rev-parse --short HEAD` 写进交付 D-5；跨 Agent 使用时另报本副本与 `origin/main` 的差值。
3. 首条回复必须声明加载状态：「已读：<文件清单>」或「未确认加载」，并复述金丝雀串 `CANARY-TRAE-7F3A9C`；该串只能证明副本内容，不证明宿主已加载。
4. 若存在 `docs/handoff/CURRENT.md`：必读，按 `rules/07` 续窗衔接——目标/现状/未决/下一步并入复述的边界清单，并先执行 `git log -1 --format='%h %s' -- docs/handoff/CURRENT.md` 核对新鲜度；不存在则声明「无交接快照，仅依据仓库与 git log 作答」。
5. 交付必须含 D-1~D-7（见 `rules/15-delivery-dod.md`）。
6. 若未读到上述规则，首行写「未确认加载：含规则库」，且不得以规则为名下任何结论。
7. 跨 Agent（豆包/千问/DSH/WorkBuddy 等）另须按 `skills/S-004-rulebase-onboarding.md` 声明角色改名与能力降级项；禁止用 `--no-verify` 绕过门禁。
```
