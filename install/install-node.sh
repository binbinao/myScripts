#!/bin/bash

# Node.js 及相关工具安装脚本
# 支持安装 Node.js、npm、yarn、pnpm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Node.js 及相关工具安装"

# 获取 Node.js 最新稳定版版本号（规范化，无 v 前缀）
get_latest_node_version() {
    local raw
    raw=$(curl -sL https://nodejs.org/dist/index.json 2>/dev/null | grep -oE '"version":"v[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | cut -d'"' -f4)
    [[ -z "$raw" ]] && echo "" && return 1
    normalize_version "$raw"
}

# 安装或升级 Node.js
install_nodejs() {
    if command_exists node; then
        local current_ver
        current_ver=$(get_current_version "node" "node --version")
        local latest_ver
        latest_ver=$(get_latest_node_version)
        if [[ -n "$latest_ver" ]] && compare_versions "$current_ver" "$latest_ver"; then
            if confirm_upgrade "Node.js" "$(node --version 2>/dev/null)" "v$latest_ver"; then
                if [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
                    run_command "brew upgrade node" "升级 Node.js"
                elif [[ "$OS_TYPE" == "linux" ]]; then
                    if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                        run_command "curl -fsSL https://deb.nodesource.com/setup_latest.x | sudo -E bash -" "更新 NodeSource 仓库"
                        run_command "sudo apt-get install -y --only-upgrade nodejs" "升级 Node.js"
                    elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                        run_command "curl -fsSL https://rpm.nodesource.com/setup_latest.x | sudo bash -" "更新 NodeSource 仓库"
                        run_command "sudo $PACKAGE_MANAGER upgrade -y nodejs" "升级 Node.js"
                    fi
                fi
            fi
        elif [[ -n "$current_ver" ]]; then
            print_info "Node.js 已是最新（$current_ver），跳过"
        else
            print_info "Node.js 已安装，跳过"
        fi
        command_exists node && log_installation "Node.js" "$(node --version)"
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

# 安装或升级 npm（通常随 Node.js 一起安装）
check_npm() {
    if ! command_exists npm; then
        print_warning "npm 未安装，尝试安装..."
        if [[ "$OS_TYPE" == "macos" ]]; then
            run_command "brew install npm" "安装 npm"
        else
            print_error "npm 应该随 Node.js 一起安装，请检查 Node.js 安装"
            return 1
        fi
        return 0
    fi
    local current_ver
    current_ver=$(get_current_version "npm" "npm --version")
    local latest_ver
    latest_ver=$(npm view npm version 2>/dev/null)
    latest_ver=$(normalize_version "$latest_ver")
    if [[ -n "$latest_ver" ]] && compare_versions "$current_ver" "$latest_ver"; then
        if confirm_upgrade "npm" "$(npm --version 2>/dev/null)" "$latest_ver"; then
            run_command "npm install -g npm@latest" "升级 npm"
        fi
    elif [[ -n "$current_ver" ]]; then
        print_info "npm 已是最新（$current_ver），跳过"
    else
        print_info "npm 已安装"
    fi
    return 0
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

# 安装或升级 yarn
install_yarn() {
    if ! command_exists yarn; then
        print_info "开始安装 Yarn..."
        if command_exists npm; then
            run_command "npm install -g yarn" "通过 npm 安装 Yarn"
        else
            print_error "需要先安装 npm"
            return 1
        fi
        command_exists yarn && log_installation "Yarn" "$(yarn --version)"
        return 0
    fi
    local current_ver
    current_ver=$(get_current_version "yarn" "yarn --version")
    local latest_ver
    latest_ver=$(npm view yarn version 2>/dev/null)
    latest_ver=$(normalize_version "$latest_ver")
    if [[ -n "$latest_ver" ]] && compare_versions "$current_ver" "$latest_ver"; then
        if confirm_upgrade "Yarn" "$(yarn --version 2>/dev/null)" "$latest_ver"; then
            run_command "npm install -g yarn@latest" "升级 Yarn"
        fi
    elif [[ -n "$current_ver" ]]; then
        print_info "Yarn 已是最新（$current_ver），跳过"
    else
        print_info "Yarn 已安装，跳过"
    fi
    command_exists yarn && log_installation "Yarn" "$(yarn --version)"
    return 0
}

# 安装或升级 pnpm
install_pnpm() {
    if ! command_exists pnpm; then
        print_info "开始安装 pnpm..."
        if command_exists npm; then
            run_command "npm install -g pnpm" "通过 npm 安装 pnpm"
        elif command_exists curl; then
            run_command "curl -fsSL https://get.pnpm.io/install.sh | sh -" "通过官方脚本安装 pnpm"
        else
            print_error "需要 npm 或 curl"
            return 1
        fi
        command_exists pnpm && log_installation "pnpm" "$(pnpm --version)"
        return 0
    fi
    local current_ver
    current_ver=$(get_current_version "pnpm" "pnpm --version")
    local latest_ver
    latest_ver=$(npm view pnpm version 2>/dev/null)
    latest_ver=$(normalize_version "$latest_ver")
    if [[ -n "$latest_ver" ]] && compare_versions "$current_ver" "$latest_ver"; then
        if confirm_upgrade "pnpm" "$(pnpm --version 2>/dev/null)" "$latest_ver"; then
            run_command "npm install -g pnpm@latest" "升级 pnpm"
        fi
    elif [[ -n "$current_ver" ]]; then
        print_info "pnpm 已是最新（$current_ver），跳过"
    else
        print_info "pnpm 已安装，跳过"
    fi
    command_exists pnpm && log_installation "pnpm" "$(pnpm --version)"
    return 0
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
