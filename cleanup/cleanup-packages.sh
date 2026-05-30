#!/bin/bash

# 包管理器缓存清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "包管理器缓存清理"

# 清理 npm 缓存
cleanup_npm_cache() {
    if command_exists npm; then
        print_info "清理 npm 缓存..."
        local cache_dir=$(npm config get cache 2>/dev/null || echo "$HOME/.npm")
        local size=$(get_dir_size "$cache_dir" 2>/dev/null || echo "unknown")
        
        print_info "npm 缓存目录: $cache_dir ($size)"
        
        if confirm "是否清理 npm 缓存？"; then
            run_command "npm cache clean --force" "清理 npm 缓存"
            log_cleanup "packages" "npm 缓存"
        fi
    else
        print_info "npm 未安装，跳过"
    fi
}

# 清理 yarn 缓存
cleanup_yarn_cache() {
    if command_exists yarn; then
        print_info "清理 yarn 缓存..."
        local cache_dir="$HOME/.yarn/cache"
        local size=$(get_dir_size "$cache_dir" 2>/dev/null || echo "unknown")
        
        print_info "yarn 缓存目录: $cache_dir ($size)"
        
        if confirm "是否清理 yarn 缓存？"; then
            run_command "yarn cache clean" "清理 yarn 缓存"
            log_cleanup "packages" "yarn 缓存"
        fi
    else
        print_info "yarn 未安装，跳过"
    fi
}

# 清理 pnpm 缓存
cleanup_pnpm_cache() {
    if command_exists pnpm; then
        print_info "清理 pnpm 缓存..."
        local cache_dir="$HOME/.pnpm-store"
        local size=$(get_dir_size "$cache_dir" 2>/dev/null || echo "unknown")
        
        print_info "pnpm 缓存目录: $cache_dir ($size)"
        
        if confirm "是否清理 pnpm 缓存？"; then
            run_command "pnpm store prune" "清理 pnpm 缓存"
            log_cleanup "packages" "pnpm 缓存"
        fi
    else
        print_info "pnpm 未安装，跳过"
    fi
}

# 清理 pip 缓存
cleanup_pip_cache() {
    if command_exists pip3 || command_exists pip; then
        print_info "清理 pip 缓存..."
        local pip_cmd="pip3"
        command_exists pip3 || pip_cmd="pip"
        
        local cache_dir=$($pip_cmd cache dir 2>/dev/null || echo "$HOME/.cache/pip")
        local size=$(get_dir_size "$cache_dir" 2>/dev/null || echo "unknown")
        
        print_info "pip 缓存目录: $cache_dir ($size)"
        
        if confirm "是否清理 pip 缓存？"; then
            run_command "$pip_cmd cache purge" "清理 pip 缓存"
            log_cleanup "packages" "pip 缓存"
        fi
    else
        print_info "pip 未安装，跳过"
    fi
}

# 清理 uv 缓存
cleanup_uv_cache() {
    local uv_cmd="uv"
    if ! command_exists uv; then
        if [[ -f "$HOME/.cargo/bin/uv" ]]; then
            uv_cmd="$HOME/.cargo/bin/uv"
        else
            print_info "uv 未安装，跳过"
            return 0
        fi
    fi
    
    print_info "清理 uv 缓存..."
    local cache_dir="$HOME/.cache/uv"
    local size=$(get_dir_size "$cache_dir" 2>/dev/null || echo "unknown")
    
    print_info "uv 缓存目录: $cache_dir ($size)"
    
    if confirm "是否清理 uv 缓存？"; then
        if [[ -d "$cache_dir" ]]; then
            if rm -rf -- "$cache_dir"; then
                print_success "清理 uv 缓存 完成"
                log_cleanup "packages" "uv 缓存"
            else
                print_error "清理 uv 缓存 失败"
            fi
        else
            print_info "uv 缓存目录不存在，无需清理"
        fi
    fi
}

# 清理 conda 缓存
cleanup_conda_cache() {
    if command_exists conda; then
        print_info "清理 conda 缓存..."
        
        if confirm "是否清理 conda 缓存？"; then
            run_command "conda clean --all -y" "清理 conda 缓存"
            log_cleanup "packages" "conda 缓存"
        fi
    else
        print_info "conda 未安装，跳过"
    fi
}

# 清理 Homebrew 缓存 (macOS)
cleanup_brew_cache() {
    if [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
        print_info "清理 Homebrew 缓存..."
        local cache_dir="$HOME/Library/Caches/Homebrew"
        local size=$(get_dir_size "$cache_dir" 2>/dev/null || echo "unknown")
        
        print_info "Homebrew 缓存目录: $cache_dir ($size)"
        
        if confirm "是否清理 Homebrew 缓存？"; then
            run_command "brew cleanup -s" "清理 Homebrew 缓存"
            log_cleanup "packages" "Homebrew 缓存"
        fi
    else
        print_info "Homebrew 未安装或不在 macOS 上，跳过"
    fi
}

# 清理 apt 缓存 (Linux)
cleanup_apt_cache() {
    if [[ "$OS_TYPE" == "linux" ]] && [[ "$PACKAGE_MANAGER" == "apt" ]]; then
        print_info "清理 apt 缓存..."
        
        if confirm "是否清理 apt 缓存？"; then
            check_sudo
            run_command "sudo apt-get clean" "清理 apt 包缓存"
            run_command "sudo apt-get autoclean" "清理 apt 旧包"
            log_cleanup "packages" "apt 缓存"
        fi
    else
        print_info "apt 未使用，跳过"
    fi
}

# 清理 yum/dnf 缓存 (Linux)
cleanup_yum_cache() {
    if [[ "$OS_TYPE" == "linux" ]] && ([[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]); then
        print_info "清理 $PACKAGE_MANAGER 缓存..."
        
        if confirm "是否清理 $PACKAGE_MANAGER 缓存？"; then
            check_sudo
            run_command "sudo $PACKAGE_MANAGER clean all" "清理 $PACKAGE_MANAGER 缓存"
            log_cleanup "packages" "$PACKAGE_MANAGER 缓存"
        fi
    else
        print_info "$PACKAGE_MANAGER 未使用，跳过"
    fi
}

# 主函数
main() {
    cleanup_npm_cache
    cleanup_yarn_cache
    cleanup_pnpm_cache
    cleanup_pip_cache
    cleanup_uv_cache
    cleanup_conda_cache
    cleanup_brew_cache
    cleanup_apt_cache
    cleanup_yum_cache
    
    echo ""
    print_title "包管理器缓存清理完成"
}

main "$@"
