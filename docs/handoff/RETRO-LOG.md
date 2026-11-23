# 复盘落库台账（RETRO-LOG）

> 用途：`scripts/retro_pending_check.sh` 的判定依据；每落库一次复盘（或合并补跑），追加一行 `RETRO <YYYY-MM-DD> <摘要>`。
> 规则：只追加、不改历史行；日期写**被复盘的那一天**，不是补跑日。细则见 [ADR-025](../adr/ADR-025-mechanical-root-cause-elimination.md)。

RETRO 2026-11-16 不适用：当日零提交；每日复盘定时任务 2026-11-18 才建立（1ead0ae），无报告可补
RETRO 2026-11-17 不适用：当日仅 4 笔建库提交；复盘机制尚未建立，无复盘产物可补
RETRO 2026-11-18 历史补录（reports/retro-2026-11-18.md）
RETRO 2026-11-19 P-019 补跑（历史补录，据 PITFALLS 记录；用户上传 11.19每日复盘.txt）
RETRO 2026-11-20 历史补录（用户上传 11.20每日复盘.txt）
RETRO 2026-11-21 合并补跑 P-034~P-037（审查见 reports/R4，2026-11-23 落库）
RETRO 2026-11-22 合并补跑 P-034~P-037（同上）
RETRO 2026-11-23 合并补跑 P-034~P-037（同上）
