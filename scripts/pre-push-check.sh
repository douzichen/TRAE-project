#!/bin/sh
# P-001 凭据自检（pre-push 卡点）：推送前确保认证可用，密钥丢失自动从 .secrets 恢复
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
  echo "[P-001] ~/.ssh/config 缺失（SSH over 443 配置丢失），推送将失败"; exit 1
fi
echo "[P-001] 凭据检查通过"
