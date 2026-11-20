#!/bin/sh
# P-001 凭据自检（pre-push 卡点）：推送前确保认证可用，密钥与 SSH 配置丢失自动从 .secrets 恢复
# 升级记录：2026-11-18 第二次复发（沙箱重启连 config 一起丢失），按"复发即升级"由检测升级为自动重建
set -e
cd "$(git rev-parse --show-toplevel)"
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
