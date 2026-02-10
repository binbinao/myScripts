#!/bin/bash

# 重装常用全局 npm 包（与 /opt/homebrew/lib 下列表一致）
# 用法: ./etc/reinstall-global-npm-packages.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/common.sh"

# 要重装的全局包列表（与 Homebrew node 全局安装路径下一致）
GLOBAL_PACKAGES=(
    "@fission-ai/openspec"
    "@qwen-code/qwen-code"
    "@tencent-ai/codebuddy-code"
    "bing-cn-mcp"
    "firecrawl-mcp"
    "mcp-chrome-bridge"
    "npm@11.9.0"
    "openskills"
    "playwright"
    "pnpm"
    "pptxgenjs"
)

main() {
    print_title "重装全局 npm 包"

    if ! command -v npm &>/dev/null; then
        print_error "未找到 npm，请先运行: ./etc/fix-node-npm.sh"
        exit 1
    fi

    print_info "将安装以下包: ${GLOBAL_PACKAGES[*]}"
    echo ""
    npm install -g "${GLOBAL_PACKAGES[@]}"
    echo ""
    print_success "全局包重装完成"
    npm list -g --depth=0 2>/dev/null | head -30
}

main "$@"
