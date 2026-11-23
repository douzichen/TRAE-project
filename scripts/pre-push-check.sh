#!/bin/sh
# pre-push 卡点：
#   1) [P-001] 凭据自检与密钥自动恢复（推送前确保认证可用）
#   2) 推送区间密钥扫描（阻断：只扫本次要推送的新增行，零误报）
#   3) BACKLINKS 新鲜度（阻断：由 link_check.sh 重新生成后与 HEAD 比对）
#   4) 工作区脏提醒（非阻断：未提交改动不会被推送，仅提示）
#
# 升级记录：
#   2026-11-18 第二次复发（沙箱重启连 config 一起丢失），按"复发即升级"由检测升级为自动重建。
#   2026-11-23 增加推送区间密钥扫描与 BACKLINKS 新鲜度阻断项；stdin 无 refs 时回退 origin/main..HEAD。
#
# stdin：git 通过 stdin 传 `<local ref> <local sha> <remote ref> <remote sha>`；无 stdin 时自动回退，不报错。

cd "$(git rev-parse --show-toplevel)" || exit 1
gitdir=$(git rev-parse --git-dir 2>/dev/null) || gitdir=".git"
fail=0
zero=0000000000000000000000000000000000000000

# ---------------- 1) 凭据自检与自动恢复（原逻辑保留） ----------------
mkdir -p "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  if [ -f .secrets/id_ed25519 ]; then
    cp .secrets/id_ed25519 "$HOME/.ssh/id_ed25519"
    cp .secrets/id_ed25519.pub "$HOME/.ssh/id_ed25519.pub"
    chmod 600 "$HOME/.ssh/id_ed25519"
    echo "-> 已从 .secrets/ 恢复密钥"
  else
    echo "[P-001] 密钥丢失且无本地备份：需重新生成并更新仓库 Deploy key"; exit 1
  fi
fi
if [ ! -f "$HOME/.ssh/config" ]; then
  printf 'Host github.com\n  HostName ssh.github.com\n  Port 443\n  User git\n  StrictHostKeyChecking accept-new\n  BatchMode yes\n  ProxyCommand nc -X connect -x 127.0.0.1:18080 %%h %%p\n' > "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  echo "-> 已自动重建 ~/.ssh/config（SSH over 443 + 代理）"
fi
# 第二 deploy key（ADR-021 ④：github-backup 镜像远端）——密钥恢复 + 主机块补齐（P-024：恢复一律走本脚本，禁 GIT_SSH_COMMAND 覆盖）
if [ ! -f "$HOME/.ssh/id_ed25519_backup" ] && [ -f .secrets/id_ed25519_backup ]; then
  cp .secrets/id_ed25519_backup "$HOME/.ssh/id_ed25519_backup"
  cp .secrets/id_ed25519_backup.pub "$HOME/.ssh/id_ed25519_backup.pub"
  chmod 600 "$HOME/.ssh/id_ed25519_backup"
  echo "-> 已从 .secrets/ 恢复第二密钥（github-backup）"
fi
if ! grep -q "Host github-backup" "$HOME/.ssh/config" 2>/dev/null; then
  printf '\nHost github-backup\n  HostName ssh.github.com\n  Port 443\n  User git\n  IdentityFile %s/.ssh/id_ed25519_backup\n  StrictHostKeyChecking accept-new\n  BatchMode yes\n  ProxyCommand nc -X connect -x 127.0.0.1:18080 %%h %%p\n' "$HOME" >> "$HOME/.ssh/config"
  echo "-> 已追加 github-backup 主机块"
fi
echo "[P-001] 凭据检查通过"

# ---------------- 2) 推送区间密钥扫描（阻断） ----------------
# 只扫新增行（`^+` 且非 `+++`），复用 secrets_scan.sh 的高精度凭据正则，避免误报。
patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}'

scan_range() {
  s_from=$1
  s_to=$2
  [ "$s_from" = "$s_to" ] && return 0
  list="$gitdir/prepush-diff-files.tmp"
  git diff --name-only -z "$s_from".."$s_to" 2>/dev/null | tr '\0' '\n' > "$list" || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in .secrets/*|*.jpg|*.jpeg|*.png|*.zip|*.pdf) continue ;; esac
    if git diff "$s_from".."$s_to" -- "$f" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' | grep -qEI -e "$patterns"; then
      echo "[PRE-PUSH][SECRET] 推送区间内疑似凭据：$f（$s_from..$s_to）"
      fail=1
    fi
  done < "$list"
  rm -f "$list" 2>/dev/null || true
}

ranges="$gitdir/prepush-ranges.tmp"
: > "$ranges" || ranges=""
scanned=0
if [ ! -t 0 ]; then
  while read -r local_ref local_sha remote_ref remote_sha; do
    [ -n "$local_sha" ] || continue
    case "$local_sha" in "$zero") continue ;; esac
    base=""
    if [ -n "$remote_sha" ] && [ "$remote_sha" != "$zero" ] && git cat-file -e "$remote_sha^{commit}" 2>/dev/null; then
      base=$(git merge-base "$remote_sha" "$local_sha" 2>/dev/null || echo "$remote_sha")
    else
      # 新分支/远端无此对象：以 origin/main 的合并基为下界
      base=$(git merge-base origin/main "$local_sha" 2>/dev/null || true)
      [ -n "$base" ] || base=$(git rev-parse "$local_sha^" 2>/dev/null || true)
    fi
    if [ -n "$base" ]; then
      printf '%s %s\n' "$base" "$local_sha" >> "$ranges"
      scanned=1
    fi
  done
fi
# 无 stdin（手工执行/非 push 场景）时回退：origin/main..HEAD
if [ "$scanned" -eq 0 ] && git rev-parse --verify -q origin/main >/dev/null 2>&1; then
  printf 'origin/main HEAD\n' > "$ranges"
  scanned=1
fi
if [ "$scanned" -eq 1 ]; then
  while read -r r_from r_to; do
    [ -n "$r_from" ] && [ -n "$r_to" ] && scan_range "$r_from" "$r_to"
  done < "$ranges"
  echo "[PRE-PUSH] 推送区间密钥扫描完成（$scanned 个区间入参，命中即阻断）"
else
  echo "[PRE-PUSH][WARN] 未取得可扫描的推送区间（无 stdin 且无 origin/main），跳过区间密钥扫描"
fi
rm -f "$ranges" 2>/dev/null || true

# ---------------- 3) BACKLINKS 新鲜度（阻断） ----------------
# 重新生成反向索引后与 HEAD 比对：不一致说明索引未随规则改动刷新，推送出去会指向旧结构。
# link_check.sh 内部会 git add 该文件，故此处先备份、比对后复原工作区与索引，避免污染用户待提交内容。
# 零误报保护：若链接源（rules/docs/skills/workflows 等）存在未提交改动，重新生成结果会混入未推送内容，
#   此时无法以 HEAD 为准判定，降级为告警并跳过（不阻断）。docs/METRICS.md 与 BACKLINKS.md 本身不影响链接图，不计入。
link_src_dirty=$(git status --porcelain 2>/dev/null \
  | grep -E '^.. (rules/|docs/|skills/|workflows/|schedules/|AGENTS\.md|AGENTS-GLOBAL\.md|README\.md|PITFALLS\.md)' \
  | grep -vE ' docs/(METRICS|BACKLINKS)\.md$')
if [ -f docs/BACKLINKS.md ]; then
  if [ -n "$link_src_dirty" ]; then
    echo "[PRE-PUSH][WARN] 链接源有未提交改动，BACKLINKS 以 HEAD 为准无法判定，跳过新鲜度检查（不阻断）"
  else
    bk="$gitdir/backlinks-prepush.bak"
    hb="$gitdir/backlinks-prepush.head"
    lc="$gitdir/link-check-prepush.out"
    cp docs/BACKLINKS.md "$bk" 2>/dev/null || bk=""
    if sh scripts/link_check.sh > "$lc" 2>&1; then
      if git show HEAD:docs/BACKLINKS.md > "$hb" 2>/dev/null; then
        if cmp -s docs/BACKLINKS.md "$hb"; then
          echo "[PRE-PUSH] BACKLINKS 新鲜度检查通过"
        else
          echo "[PRE-PUSH] BACKLINKS 不新鲜：docs/BACKLINKS.md 重新生成后与 HEAD 不一致，请提交刷新后的索引再推送"
          fail=1
        fi
      else
        echo "[PRE-PUSH][WARN] HEAD 中无 docs/BACKLINKS.md，跳过新鲜度比对"
      fi
    else
      echo "[PRE-PUSH] link_check.sh 失败（死链或双向结构问题），阻断推送："
      sed -n '1,20p' "$lc"
      fail=1
    fi
    # 复原：工作区回到检查前内容，索引回到 HEAD，避免 link_check 的 git add 副作用
    [ -n "$bk" ] && [ -f "$bk" ] && cp "$bk" docs/BACKLINKS.md 2>/dev/null
    git reset -q -- docs/BACKLINKS.md 2>/dev/null || true
    rm -f "$bk" "$hb" "$lc" 2>/dev/null || true
  fi
else
  echo "[PRE-PUSH][WARN] 缺 docs/BACKLINKS.md，跳过新鲜度检查"
fi

# ---------------- 4) 工作区脏提醒（非阻断） ----------------
dirty=$(git status --porcelain 2>/dev/null)
if [ -n "$dirty" ]; then
  echo "[PRE-PUSH][WARN] 工作区存在未提交改动（不会被本次推送带走）："
  printf '%s\n' "$dirty" | sed -n '1,10p'
  if [ -n "$(git status --porcelain -- docs/METRICS.md 2>/dev/null)" ]; then
    echo "[PRE-PUSH][WARN] docs/METRICS.md 有未入账/未提交改动：先跑 sh scripts/metrics_collect.sh --flush 再提交"
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "[PRE-PUSH] 存在阻断项，已拒绝推送"
  exit 1
fi
echo "[PRE-PUSH] 推送前检查通过"
exit 0
