#!/bin/sh
# 新窗口开工自检（只读工作区，不 pull、不改任何文件）
# 依据：ADR-014（自检脚本）、ADR-019（开工强制握手）；坑账本 P-016（无自动注入）、P-018（副本落后被当权威）
# 用法：新会话第一条命令 `sh scripts/session_start_check.sh`，把输出整段贴进交付 D-5
# 退出码：0=可开工；1=需处理（缺文件/金丝雀缺失）；2=无法核对远端（网络或凭据）；3=版本落后（开工强制握手：先 git pull --ff-only origin main 再开工）
# 说明：fetch 只更新 .git 内的远端引用，不改工作区；本脚本不自动 pull。

root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$root" ]; then
  echo "[SESSION] 失败：当前目录不在 git 仓库内（$(pwd)）"
  echo "[SESSION] 处理：先 clone 同源仓库再重跑；不要在空目录或旧副本上宣布“规则不存在”（P-018）"
  exit 1
fi
cd "$root" || exit 1
echo "[SESSION] 仓库根：$root"
state=0

# 1) 必读文件存在性（15 不属启动必读，见 rules/12）
for f in AGENTS.md rules/00-core.md rules/01-user-profile.md rules/02-intake-and-dod.md; do
  if [ -f "$f" ]; then
    echo "[SESSION] 存在：$f"
  else
    echo "[SESSION] 缺失：$f"
    state=1
  fi
done

# 2) 分支与工作区状态（影响 pull --ff-only 能否成功）
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
echo "[SESSION] 当前分支：$branch"
if [ "$branch" != "main" ]; then
  echo "[SESSION] 提示：不在 main 上；规则以 main 为权威，先确认是否读错分支"
fi
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "[SESSION] 工作区有未提交改动：pull --ff-only 可能失败，先确认这些改动的归属"
fi

# 3) 版本核对：用 FETCH_HEAD 而不依赖本地 origin/main 引用（无 refspec 时不会更新）
head_short=$(git rev-parse --short HEAD 2>/dev/null)
echo "[SESSION] 本地 HEAD：$head_short"
if GIT_TERMINAL_PROMPT=0 git fetch --quiet origin main 2>/dev/null; then
  remote_short=$(git rev-parse --short FETCH_HEAD 2>/dev/null)
  behind=$(git rev-list --count HEAD..FETCH_HEAD 2>/dev/null)
  ahead=$(git rev-list --count FETCH_HEAD..HEAD 2>/dev/null)
  echo "[SESSION] 远端 main：$remote_short｜落后 $behind｜领先 $ahead"
  if [ "$behind" != "0" ]; then
    # 落后即早退给出唯一动作；拉取后重跑本脚本补全交接快照与金丝雀检查
    echo "[SESSION] 本地落后远端 $behind 个提交：先 git pull --ff-only origin main 再开工（开工强制握手，ADR-019）"
    echo "[SESSION] 用户要求锁定版本时，在交付声明「落后 $behind、按用户指令锁定」"
    exit 3
  fi
  if [ "$ahead" != "0" ]; then
    echo "[SESSION] 结论：本地领先远端，属分叉；ff-only 不适用，先确认这些提交是否应推送"
  fi
else
  echo "[SESSION] 无法核对远端（网络或凭据失败）：不得宣称“已是最新”"
  echo "[SESSION] 处理：检查网络/凭据后重跑；离线时在交付里声明“未核对远端版本”"
  state=2
fi

# 4) 交接快照
if [ -f docs/handoff/CURRENT.md ]; then
  last=$(git log -1 --format='%h %s' -- docs/handoff/CURRENT.md 2>/dev/null)
  if [ -z "$last" ]; then
    echo "[SESSION] 交接快照存在但未入库（untracked）：可能过期，先确认是否本机临时产物"
  else
    last_full=$(git log -1 --format='%H' -- docs/handoff/CURRENT.md 2>/dev/null)
    n_since=$(git rev-list --count "$last_full..HEAD" 2>/dev/null)
    echo "[SESSION] 交接快照：$last"
    echo "[SESSION] 交接快照距今 ${n_since} 个提交（仅供参考：快照按交付更新，不构成失败）"
  fi
else
  echo "[SESSION] 无交接快照：交付中声明“无交接快照，仅依据仓库与 git log 作答”"
fi

# 5) 金丝雀（只证明副本内容，不证明宿主已加载规则，见 ADR-011）
if grep -q 'CANARY-TRAE-7F3A9C' AGENTS.md 2>/dev/null; then
  echo "[SESSION] 金丝雀可见：CANARY-TRAE-7F3A9C（首条回复须复述；仅证明副本内容，不证明宿主加载）"
else
  echo "[SESSION] 金丝雀缺失：副本可能被改或过旧，首行写「未确认加载：含规则库」"
  state=1
fi

case "$state" in
  0) echo "[SESSION] 自检通过：可以开工（本次未改工作区）" ;;
  1) echo "[SESSION] 自检未通过：按上面每条的“处理/结论”修正后重跑" ;;
  2) echo "[SESSION] 自检不完整：版本未核对，交付须声明" ;;
esac
exit "$state"
