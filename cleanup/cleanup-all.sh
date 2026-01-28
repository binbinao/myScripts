#!/bin/bash

# 一键清理所有脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "一键清理所有"

print_warning "这将执行所有清理操作，包括："
echo "  - 系统缓存清理"
echo "  - 包管理器缓存清理"
echo "  - Docker 资源清理"
echo "  - Git 仓库清理"
echo "  - 临时文件清理"
echo "  - 日志文件清理"
echo "  - node_modules 清理"
echo "  - Python 缓存清理"
echo ""

if ! confirm "确认执行所有清理操作？"; then
    exit 0
fi

# 执行所有清理脚本
print_info "开始执行清理操作..."
echo ""

bash "$SCRIPT_DIR/cleanup-system.sh"
bash "$SCRIPT_DIR/cleanup-packages.sh"
bash "$SCRIPT_DIR/cleanup-docker.sh"
bash "$SCRIPT_DIR/cleanup-git.sh"
bash "$SCRIPT_DIR/cleanup-temp.sh"
bash "$SCRIPT_DIR/cleanup-logs.sh"
bash "$SCRIPT_DIR/cleanup-node.sh"
bash "$SCRIPT_DIR/cleanup-python.sh"

echo ""
print_title "所有清理操作完成"
print_success "请检查上述输出确认清理状态"
