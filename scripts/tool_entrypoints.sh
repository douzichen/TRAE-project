#!/bin/sh
# 生成各 Agent 工具的入口指针文件：只写"规则见 AGENTS.md"，绝不复制正文（防多份正文漂移）
cd "$(git rev-parse --show-toplevel)" || exit 1

gen() {
  f="$1"; name="$2"
  cat > "$f" <<EOF
# ${f}

本项目规则库在 AGENTS.md，本文件为 ${name} 的入口指针，不复制规则正文。

1. 读 AGENTS.md（总纲）；
2. 按「会话启动阅读顺序」读 rules/00、01、02；
3. 按「新规则落到哪一册」路由表只加载相关 1~2 册；
4. 预算与"未读完必须声明"见 rules/12-context-budget.md。

> 由 scripts/tool_entrypoints.sh 生成，请勿手改。
EOF
  echo "[ENTRY] 已生成 $f（$name）"
}

gen CLAUDE.md "Claude Code"
gen GEMINI.md "Gemini CLI"
gen .cursorrules "Cursor"

echo "[ENTRY] 入口指针文件生成完毕（新增工具请在本脚本登记，勿手写副本）"
