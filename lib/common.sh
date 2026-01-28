#!/bin/bash

# 公共函数库 - 通用功能函数
# 提供颜色输出、进度条、OS检测、版本检查等功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 操作系统类型
OS_TYPE=""
PACKAGE_MANAGER=""

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        # 检测Linux发行版
        if command -v apt-get &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        elif command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
        else
            PACKAGE_MANAGER="unknown"
        fi
    else
        OS_TYPE="unknown"
        PACKAGE_MANAGER="unknown"
    fi
}

# 初始化（自动检测OS）
init() {
    detect_os
}

# 打印带颜色的消息
print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_title() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

# 确认提示
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        prompt="${prompt} [Y/n]: "
    else
        prompt="${prompt} [y/N]: "
    fi
    
    read -p "$(echo -e ${YELLOW}${prompt}${NC})" response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 进度条
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}进度:${NC} ["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查工具版本
check_version() {
    local tool=$1
    local version_cmd=$2
    
    if command_exists "$tool"; then
        local version
        if [[ -n "$version_cmd" ]]; then
            version=$($version_cmd 2>/dev/null | head -n 1)
        else
            version=$($tool --version 2>/dev/null | head -n 1)
        fi
        print_success "$tool 已安装: $version"
        return 0
    else
        print_warning "$tool 未安装"
        return 1
    fi
}

# 执行命令并检查结果
run_command() {
    local cmd="$1"
    local description="${2:-执行命令}"
    
    print_info "$description..."
    if eval "$cmd"; then
        print_success "$description 完成"
        return 0
    else
        print_error "$description 失败"
        return 1
    fi
}

# 需要sudo权限时检查
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            print_warning "此操作需要管理员权限，请输入密码"
            sudo -v
        fi
    fi
}

# 获取文件大小（人类可读格式）
get_file_size() {
    local file="$1"
    if [[ "$OS_TYPE" == "macos" ]]; then
        stat -f%z "$file" 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || du -h "$file" | cut -f1
    else
        stat -c%s "$file" 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || du -h "$file" | cut -f1
    fi
}

# 获取目录大小（人类可读格式）
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# 格式化字节数
format_bytes() {
    local bytes=$1
    if command_exists numfmt; then
        numfmt --to=iec-i --suffix=B "$bytes"
    else
        # 简单格式化
        if [[ $bytes -lt 1024 ]]; then
            echo "${bytes}B"
        elif [[ $bytes -lt 1048576 ]]; then
            echo "$((bytes / 1024))KB"
        elif [[ $bytes -lt 1073741824 ]]; then
            echo "$((bytes / 1048576))MB"
        else
            echo "$((bytes / 1073741824))GB"
        fi
    fi
}

# 等待用户按键
press_any_key() {
    read -n 1 -s -r -p "$(echo -e ${YELLOW}按任意键继续...${NC})"
    echo ""
}

# 显示分隔线
print_separator() {
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

# 错误退出
error_exit() {
    print_error "$1"
    exit 1
}

# 加载配置文件
load_config() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        return 0
    else
        print_warning "配置文件不存在: $config_file"
        return 1
    fi
}

# 初始化（自动执行）
init
