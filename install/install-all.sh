#!/bin/bash

# 一键安装所有开发工具

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "一键安装所有开发工具"

if ! confirm "这将安装所有开发工具，是否继续？"; then
    exit 0
fi

# 安装所有工具
print_info "开始安装所有工具..."

bash "$SCRIPT_DIR/install-node.sh"
bash "$SCRIPT_DIR/install-python.sh"
bash "$SCRIPT_DIR/install-docker.sh"
bash "$SCRIPT_DIR/install-git.sh"
bash "$SCRIPT_DIR/install-db.sh"

echo ""
print_title "所有工具安装完成"
print_success "请检查上述输出确认安装状态"
