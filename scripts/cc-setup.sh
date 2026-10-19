#!/usr/bin/env bash
# Claude Agent (https://claudeagent.com.cn) — Claude Code 一键环境变量配置脚本
# 用法: bash cc-setup.sh cr_你的专属密钥

set -e

TOKEN="${1:-}"
BASE_URL="https://claudeagent.com.cn/rental-api"

if [ -z "$TOKEN" ]; then
  echo "用法: bash cc-setup.sh <cr_你的专属密钥>"
  echo "获取密钥: https://claudeagent.com.cn/console/rentals"
  exit 1
fi

SHELL_RC="$HOME/.bashrc"
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

{
  echo ""
  echo "# Claude Agent (https://claudeagent.com.cn) 直连配置"
  echo "export ANTHROPIC_BASE_URL=\"$BASE_URL\""
  echo "export ANTHROPIC_AUTH_TOKEN=\"$TOKEN\""
} >> "$SHELL_RC"

echo "✅ 已写入 $SHELL_RC ！请执行以下命令生效并启动 Claude Code："
echo "   source $SHELL_RC && claude"
