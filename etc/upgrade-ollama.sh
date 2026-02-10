#!/bin/bash

# Ollama 升级脚本
# 支持 Linux 和 macOS 平台
# 具备版本检测、自动升级和用户交互功能

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载公共函数库
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/logger.sh"
source "$PROJECT_ROOT/lib/safety.sh"

# Ollama GitHub 仓库信息
GITHUB_REPO="ollama/ollama"
GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"

# 默认安装路径
INSTALL_PATH="/usr/local/bin/ollama"

# 获取系统架构
get_architecture() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            print_error "不支持的架构: $arch"
            exit 1
            ;;
    esac
}

# 获取当前安装版本
get_current_version() {
    if command_exists "ollama"; then
        local version
        version=$(ollama --version 2>/dev/null | head -n 1 | sed 's/^v\?\([0-9.]\+\).*/\1/')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

# 获取 GitHub 最新版本信息
get_latest_version() {
    print_info "正在检查 GitHub 最新版本..."
    
    if command_exists "curl"; then
        local response
        response=$(curl -s "$GITHUB_API_URL")
        if [[ $? -eq 0 ]]; then
            local version
            version=$(echo "$response" | grep '"tag_name":' | sed 's/.*"tag_name": "\([^"]*\)".*/\1/' | sed 's/^v\?//')
            if [[ -n "$version" ]]; then
                echo "$version"
                return 0
            fi
        fi
    fi
    
    print_error "无法获取最新版本信息"
    return 1
}

# 构建下载URL
build_download_url() {
    local version=$1
    local arch=$2
    local os_type="linux"
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        os_type="darwin"
    fi
    
    echo "https://github.com/$GITHUB_REPO/releases/download/v${version}/ollama-${os_type}-${arch}"
}

# 下载 Ollama
download_ollama() {
    local url=$1
    local dest=$2
    
    print_info "正在下载 Ollama..."
    if command_exists "curl"; then
        if curl -L -o "$dest" "$url" --progress-bar; then
            return 0
        fi
    elif command_exists "wget"; then
        if wget -O "$dest" "$url" --progress=bar:force; then
            return 0
        fi
    fi
    
    print_error "下载失败"
    return 1
}

# 安装 Ollama
install_ollama() {
    local binary_path=$1
    
    # 检查是否需要sudo权限
    if [[ ! -w "$(dirname "$INSTALL_PATH")" ]]; then
        print_warning "需要管理员权限来安装 Ollama"
        check_sudo
        sudo mv "$binary_path" "$INSTALL_PATH"
        sudo chmod +x "$INSTALL_PATH"
    else
        mv "$binary_path" "$INSTALL_PATH"
        chmod +x "$INSTALL_PATH"
    fi
    
    # 验证安装
    if [[ -x "$INSTALL_PATH" ]]; then
        print_success "Ollama 安装完成"
        return 0
    else
        print_error "安装失败"
        return 1
    fi
}

# 备份当前版本（如果存在）
backup_current_version() {
    if [[ -f "$INSTALL_PATH" ]]; then
        local backup_path="${INSTALL_PATH}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$INSTALL_PATH" "$backup_path"
        print_info "已备份当前版本到: $backup_path"
    fi
}

# 执行升级
perform_upgrade() {
    local current_version=$1
    local latest_version=$2
    local arch=$3
    
    print_title "开始升级 Ollama"
    print_info "当前版本: $current_version"
    print_info "目标版本: $latest_version"
    
    # 创建临时目录
    local temp_dir
    temp_dir=$(mktemp -d)
    local temp_binary="$temp_dir/ollama"
    
    # 构建下载URL
    local download_url
    download_url=$(build_download_url "$latest_version" "$arch")
    print_info "下载地址: $download_url"
    
    # 下载新版本的 Ollama
    if download_ollama "$download_url" "$temp_binary"; then
        # 备份当前版本
        backup_current_version
        
        # 安装新版本  
        if install_ollama "$temp_binary"; then
            print_success "升级成功！"
            print_info "新版本信息:"
            ollama --version
            return 0
        fi
    fi
    
    # 清理临时文件
    rm -rf "$temp_dir"
    return 1
}

# 主函数
main() {
    print_title "Ollama 版本管理器"
    
    # 检查当前操作系统
    if [[ "$OS_TYPE" == "unknown" ]]; then
        print_error "不支持的操作系统"
        exit 1
    fi
    
    # 获取系统架构
    local arch
    arch=$(get_architecture)
    print_info "系统架构: $arch"
    
    # 检查网络连接
    if ! check_network; then
        print_error "网络连接异常，无法检查更新"
        exit 1
    fi
    
    # 获取当前版本
    local current_version
    current_version=$(get_current_version)
    
    if [[ -z "$current_version" ]]; then
        print_warning "Ollama 未安装"
        if confirm "是否现在安装 Ollama？" "y"; then
            current_version="未安装"
        else
            exit 0
        fi
    fi
    
    # 获取最新版本
    local latest_version
    latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        print_error "无法获取最新版本信息"
        exit 1
    fi
    
    # 版本比较
    if [[ "$current_version" != "未安装" ]] && [[ $(compare_versions "$current_version" "$latest_version") -eq 1 ]]; then
        print_success "当前版本 ($current_version) 已是最新"
        exit 0
    fi
    
    # 显示版本信息并询问是否升级
    echo
    print_info "当前版本: $current_version"
    print_info "最新版本: $latest_version"
    
    if [[ "$current_version" == "未安装" ]] || confirm "是否 $([ "$current_version" != "未安装" ] && echo "升级" || echo "安装")到版本 $latest_version？" "y"; then
        if perform_upgrade "$current_version" "$latest_version" "$arch"; then
            print_success "操作完成"
        else
            print_error "升级失败，请检查日志"
            exit 1
        fi
    else
        print_info "已取消操作"
    fi
}

# 网络检查函数
check_network() {
    if command_exists "curl"; then
        if curl -s --connect-timeout 5 https://github.com >/dev/null; then
            return 0
        fi
    fi
    return 1
}

# 如果脚本被直接执行，则运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi