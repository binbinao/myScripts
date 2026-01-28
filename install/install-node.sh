#!/bin/bash

# Node.js 及相关工具安装脚本
# 支持安装 Node.js、npm、yarn、pnpm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Node.js 及相关工具安装"

# 安装 Node.js
install_nodejs() {
    if check_version "node" "node --version"; then
        print_info "Node.js 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 Node.js..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install node" "安装 Node.js"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "curl -fsSL https://deb.nodesource.com/setup_latest.x | sudo -E bash -" "添加 NodeSource 仓库（最新版本）"
            run_command "sudo apt-get install -y nodejs" "安装 Node.js"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "curl -fsSL https://rpm.nodesource.com/setup_latest.x | sudo bash -" "添加 NodeSource 仓库（最新版本）"
            run_command "sudo $PACKAGE_MANAGER install -y nodejs" "安装 Node.js"
        else
            print_error "不支持的包管理器"
            return 1
        fi
    fi
    
    if check_version "node"; then
        local version=$(node --version)
        log_installation "Node.js" "$version"
        return 0
    else
        return 1
    fi
}

# 安装 npm（通常随 Node.js 一起安装）
check_npm() {
    if check_version "npm" "npm --version"; then
        print_info "npm 已安装"
        return 0
    else
        print_warning "npm 未安装，尝试安装..."
        if [[ "$OS_TYPE" == "macos" ]]; then
            run_command "brew install npm" "安装 npm"
        else
            print_error "npm 应该随 Node.js 一起安装，请检查 Node.js 安装"
            return 1
        fi
    fi
}

# 安装 n (Node.js 版本管理工具)
install_n() {
    if command_exists n; then
        print_info "n 已安装，跳过"
        return 0
    fi
    
    if ! command_exists npm; then
        print_error "需要先安装 npm"
        return 1
    fi
    
    print_info "开始安装 n (Node.js 版本管理工具)..."
    run_command "npm install -g n" "安装 n"
    
    if command_exists n; then
        print_success "n 安装完成"
        print_info "使用示例："
        print_info "  n latest    # 安装最新版本"
        print_info "  n lts       # 安装 LTS 版本"
        print_info "  n 20.0.0    # 安装指定版本"
        log_installation "n" "$(n --version 2>/dev/null || echo 'installed')"
        return 0
    else
        print_warning "n 安装可能未完成，请手动运行: npm install -g n"
        return 1
    fi
}

# 安装 yarn
install_yarn() {
    if check_version "yarn" "yarn --version"; then
        print_info "Yarn 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 Yarn..."
    
    if command_exists npm; then
        run_command "npm install -g yarn" "通过 npm 安装 Yarn"
    else
        print_error "需要先安装 npm"
        return 1
    fi
    
    if check_version "yarn"; then
        local version=$(yarn --version)
        log_installation "Yarn" "$version"
        return 0
    else
        return 1
    fi
}

# 安装 pnpm
install_pnpm() {
    if check_version "pnpm" "pnpm --version"; then
        print_info "pnpm 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 pnpm..."
    
    if command_exists npm; then
        run_command "npm install -g pnpm" "通过 npm 安装 pnpm"
    elif command_exists curl; then
        run_command "curl -fsSL https://get.pnpm.io/install.sh | sh -" "通过官方脚本安装 pnpm"
    else
        print_error "需要 npm 或 curl"
        return 1
    fi
    
    if check_version "pnpm"; then
        local version=$(pnpm --version)
        log_installation "pnpm" "$version"
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    install_nodejs
    check_npm
    install_n
    install_yarn
    install_pnpm
    
    echo ""
    print_title "安装完成"
    echo "已安装工具版本："
    command_exists node && echo "  Node.js: $(node --version)"
    command_exists npm && echo "  npm: $(npm --version)"
    if command_exists n; then
        echo "  n: $(n --version 2>/dev/null || echo '已安装')"
    fi
    command_exists yarn && echo "  Yarn: $(yarn --version)"
    command_exists pnpm && echo "  pnpm: $(pnpm --version)"
    
    if command_exists n; then
        echo ""
        print_info "提示：使用 n 工具可以管理 Node.js 版本"
        print_info "  运行 'n latest' 安装最新版本"
        print_info "  运行 'n lts' 安装 LTS 版本"
        print_info "  运行 'n <version>' 安装指定版本（如: n 20.0.0）"
    fi
}

main "$@"
