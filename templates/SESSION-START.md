# 会话开工令（模板）

> 用法：新会话或派单时，把下方代码块整段粘贴到首条消息。来源：[ADR-011](../docs/adr/ADR-011-no-auto-injection.md)。

```
开工令：
1. 先按顺序读取：`AGENTS.md` → `rules/00-core.md`、`rules/01-user-profile.md`、`rules/02-intake-and-dod.md`；再按 `AGENTS.md` 路由表读与本任务相关的 1~2 册。
2. 首条回复必须声明加载状态：「已读：<文件清单>」或「未确认加载」。
3. 若存在 `docs/handoff/CURRENT.md`：必读，按 `rules/07` 续窗衔接——目标/现状/未决/下一步并入复述的边界清单，并先执行 `git log -1 --format='%h %s' -- docs/handoff/CURRENT.md` 核对新鲜度；不存在则声明「无交接快照，仅依据仓库与 git log 作答」。
4. 交付必须含 D-1~D-7（见 `rules/15-delivery-dod.md`）。
5. 若未读到上述规则，首行写「未确认加载：含规则库」，且不得以规则为名下任何结论。
```
