#!/bin/sh
# 本地专属规则完整性校验（ADR-035）：扫描 .local-rules/ENTRY-*.md，核对正文存在与 SHA256 是否一致。
#
# 用法：
#   sh scripts/local_rules_check.sh              # 会话启动用：告警模式，恒退 0
#   ENFORCE=1 sh scripts/local_rules_check.sh    # pre-commit 用：任一缺口退 1（仅当本地规则存在时生效）
#
# 说明：正文与入口均不入 git（.git/info/exclude 排除）。哈希只能发现改动，不能恢复正文。
# Windows 用 Git Bash 运行；路径全部相对仓库根，不写死绝对路径。

set -u
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || exit 1
cd "$root" || exit 1

enforce=${ENFORCE:-0}

if [ ! -d .local-rules ]; then
  echo "[LOCAL-RULES] 无本地规则，跳过"
  exit 0
fi

# 取入口表格字段：| 字段 | 值 |
entry_field() {
  awk -F'|' -v k="$1" '
    {
      key=$2; val=$3
      gsub(/^[ \t]+|[ \t]+$/, "", key)
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      if (key == k) { gsub(/`/, "", val); print val; exit }
    }
  ' "$2"
}

sha_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo ""
  fi
}

fail=0
found=0
for entry in .local-rules/ENTRY-*.md; do
  [ -f "$entry" ] || continue
  # 模板不是生效入口（*.template.md 也匹配 ENTRY-*.md），跳过
  case "$entry" in *.template.md) continue ;; esac
  found=1
  body=$(entry_field "正文绝对路径" "$entry")
  want=$(entry_field "正文 SHA256" "$entry")
  body_shown=$body

  # 绝对路径在别的机器上会失效：退回同目录同名文件，保证入口可随工作区迁移
  if [ -z "$body" ] || [ ! -f "$body" ]; then
    body="./.local-rules/${body##*/}"
    body_shown=$body
  fi

  if [ -z "$want" ] || [ ! -f "$body" ]; then
    if [ "$enforce" = "1" ]; then
      echo "[LOCAL-RULES] 失败：$entry 正文缺失或未登记哈希（正文=$body_shown）"
    else
      echo "[LOCAL-RULES] 告警：$entry 正文缺失或未登记哈希（正文=$body_shown）"
    fi
    fail=1
    continue
  fi

  actual=$(sha_of "$body")
  if [ -z "$actual" ]; then
    # fail-closed：没有哈希工具就无法验证，不得默认“通过”
    echo "[LOCAL-RULES] 失败：无可用哈希工具（sha256sum/shasum），无法校验 $entry"
    if [ "$enforce" != "1" ]; then
      echo "[LOCAL-RULES] 告警：以上为告警（告警模式不阻断，ENFORCE=1 时阻断）"
    fi
    fail=1
    continue
  fi

  if [ "$actual" != "$want" ]; then
    if [ "$enforce" = "1" ]; then
      echo "[LOCAL-RULES] 失败：$entry 哈希不一致（登记=${want} 实际=${actual}）→ 正文已改动，须复核后重跑 scripts/local_rules_install.sh"
    else
      echo "[LOCAL-RULES] 告警：$entry 哈希不一致（登记=${want} 实际=${actual}）→ 正文已改动，须复核后重跑 scripts/local_rules_install.sh"
    fi
    fail=1
    continue
  fi

  echo "[LOCAL-RULES] 通过：${entry##*/}（正文 $body_shown）"
done

if [ "$found" -eq 0 ]; then
  echo "[LOCAL-RULES] .local-rules/ 存在但无 ENTRY-*.md，跳过"
  exit 0
fi

if [ "$fail" -ne 0 ]; then
  if [ "$enforce" = "1" ]; then
    echo "[LOCAL-RULES] 本地规则校验未通过（ENFORCE=1）"
    exit 1
  fi
  echo "[LOCAL-RULES] 本地规则校验有告警（告警模式，不阻断；ENFORCE=1 时阻断）"
  exit 0
fi

echo "[LOCAL-RULES] 本地规则校验通过"
exit 0
