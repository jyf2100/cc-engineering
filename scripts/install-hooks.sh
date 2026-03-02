#!/bin/bash
#
# Git Hooks 安装脚本
# 将 pre-commit hook 安装到 .git/hooks 目录
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || echo '.git')"

echo "安装 Git Hooks..."

# 复制 pre-commit hook
cp "$SCRIPT_DIR/pre-commit" "$GIT_DIR/hooks/pre-commit"
chmod +x "$GIT_DIR/hooks/pre-commit"

echo "✓ pre-commit hook 已安装"
echo ""
echo "功能："
echo "  - 检查 API Keys (Anthropic, OpenAI, AWS 等)"
echo "  - 检查密码和私钥"
echo "  - 检查数据库连接字符串"
echo "  - 检查 GitHub Tokens"
echo ""
echo "跳过检查: git commit --no-verify"
