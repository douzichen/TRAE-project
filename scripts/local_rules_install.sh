#!/bin/sh
# 本地专属规则安装脚本（幂等、可移植；Windows 用 Git Bash 运行）
#
# 用途：把一份本地专属规则正文登记为入口（ENTRY-<ID>.md）：
#   ① 计算正文 SHA256；② 确保 .local-rules/ 存在；③ 由入口模板回填“正文绝对路径 + SHA256”生成入口；
#   ④ 确保 .git/info/exclude 含一行 `.local-rules/`；⑤ 校验入口登记的哈希与实际正文一致；⑥ 打印后续手动步骤。
#
# 为何不入 git：本地规则只在本机生效，正文与入口都留在工作区，用 .git/info/exclude 排除，
#   永不 git add/commit——一旦进对象库，一次误推即随仓库外泄。
# 注意：git clean -fdx 会删除 .local-rules/；沙箱重建、换机、new clone 亦不带本目录，届时重跑本脚本即可重建（见 ADR-035）。
# 依据：docs/adr/ADR-035-local-only-rules.md
#
# 用法：sh scripts/local_rules_install.sh --body <正文文件> --id IRON-0002 [--entry-template <模板>]

set -u
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || exit 1
cd "$root" || exit 1

usage() {
  echo "用法：sh scripts/local_rules_install.sh --body <正文文件> --id <ID> [--entry-template <模板>]"
  echo "  例：sh scripts/local_rules_install.sh --body .local-rules/IRON-0002-per-feature-test-items.md --id IRON-0002 --entry-template .local-rules/ENTRY-IRON-0002.template.md"
}

body=""
id=""
template=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --body) [ "$#" -ge 2 ] || { usage; exit 2; }; body=$2; shift 2 ;;
    --id) [ "$#" -ge 2 ] || { usage; exit 2; }; id=$2; shift 2 ;;
    --entry-template) [ "$#" -ge 2 ] || { usage; exit 2; }; template=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[LOCAL-RULES] 未知参数：$1"; usage; exit 2 ;;
  esac
done

[ -n "$body" ] && [ -n "$id" ] || { usage; exit 2; }
[ -f "$body" ] || { echo "[LOCAL-RULES] 失败：正文不存在：$body"; exit 1; }
[ -n "$template" ] || template=".local-rules/ENTRY-$id.template.md"
[ -f "$template" ] || { echo "[LOCAL-RULES] 失败：入口模板不存在：$template"; exit 1; }

# 正文绝对路径：相对路径以仓库根为基准，并消掉 `./`、`..` 与多余分隔符（不依赖 realpath）
case "$body" in
  /*) body_abs=$body ;;
  *)
    body_dir=$(CDPATH= cd -- "$(dirname -- "$body")" 2>/dev/null && pwd) \
      || { echo "[LOCAL-RULES] 失败：无法解析正文目录：$body"; exit 1; }
    body_abs="$body_dir/$(basename -- "$body")"
    ;;
esac

# ① SHA256：sha256sum 或 shasum -a 256，二选一可用
if command -v sha256sum >/dev/null 2>&1; then
  body_sha=$(sha256sum "$body" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  body_sha=$(shasum -a 256 "$body" | awk '{print $1}')
else
  echo "[LOCAL-RULES] 失败：找不到 sha256sum 或 shasum，无法计算哈希"; exit 1
fi
[ -n "$body_sha" ] || { echo "[LOCAL-RULES] 失败：哈希计算为空"; exit 1; }

# ② 目录
mkdir -p .local-rules || { echo "[LOCAL-RULES] 失败：无法创建 .local-rules/"; exit 1; }

# ③ 由模板回填生成入口（覆盖写，内容由正文决定，重复执行结果相同）
dir_abs=$(CDPATH= cd -- "$(dirname -- "$body_abs")" && pwd) || { echo "[LOCAL-RULES] 失败：无法定位正文目录"; exit 1; }
entry=".local-rules/ENTRY-$id.md"
awk -v p="$dir_abs" -v h="$body_sha" '
{
  gsub(/<本机 \.local-rules 绝对路径>/, p)
  gsub(/<安装时由脚本回填>/, h)
  print
}' "$template" > "$entry" || { echo "[LOCAL-RULES] 失败：无法写入 $entry"; exit 1; }

# ④ .git/info/exclude 幂等追加 `.local-rules/`
gitdir=$(git rev-parse --git-dir 2>/dev/null) || gitdir=".git"
exclude="$gitdir/info/exclude"
mkdir -p "$gitdir/info" 2>/dev/null || true
if [ -f "$exclude" ] && grep -qxF '.local-rules/' "$exclude"; then
  exclude_action="已存在，未重复追加"
else
  printf '.local-rules/\n' >> "$exclude" || { echo "[LOCAL-RULES] 失败：无法写入 $exclude"; exit 1; }
  exclude_action="已追加"
fi

# ⑤ 校验：入口登记的哈希与正文实际哈希一致
entry_sha=$(grep -E '正文 SHA256' "$entry" | grep -oE '[0-9a-f]{64}' | head -n 1)
if [ "$entry_sha" != "$body_sha" ]; then
  echo "[LOCAL-RULES] 失败：入口登记哈希与正文不一致（entry=${entry_sha:-空} body=$body_sha）"; exit 1
fi
entry_path=$(grep -E '正文绝对路径' "$entry" | grep -oE '/[^`|]*\.md' | head -n 1)
if [ "$entry_path" != "$body_abs" ]; then
  echo "[LOCAL-RULES] 失败：入口登记路径与正文不一致（entry=${entry_path:-空} body=$body_abs）"; exit 1
fi

# ⑥ 结果与手动步骤
echo "[LOCAL-RULES] 正文：$body_abs"
echo "[LOCAL-RULES] SHA256：$body_sha"
echo "[LOCAL-RULES] 入口模板：$template"
echo "[LOCAL-RULES] 已生成入口：$entry（路径与哈希已回填）"
echo "[LOCAL-RULES] .git/info/exclude：.local-rules/ $exclude_action"
echo "[LOCAL-RULES] 校验：入口登记哈希与正文一致"
echo "[LOCAL-RULES] 完成。后续手动步骤："
echo "  1) 会话启动后确认 sh scripts/local_rules_check.sh 输出通过"
echo "  2) 不要 git add .local-rules/；若已误 add，用 git rm --cached 撤销"
echo "  3) 其他机器安装：复制正文与模板后重跑本脚本（脚本会重新回填本机绝对路径与哈希）"
echo "  4) git clean -fdx 会删除 .local-rules/；沙箱重建/换机/new clone 同样丢失，届时重跑本脚本重建"
