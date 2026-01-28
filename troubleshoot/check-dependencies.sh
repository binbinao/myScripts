#!/bin/bash

# 依赖冲突排查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "依赖冲突排查"

# 检查 npm 依赖
check_npm_dependencies() {
    if ! command_exists npm; then
        print_info "npm 未安装，跳过"
        return 0
    fi
    
    print_info "检查 npm 依赖..."
    
    local project_dir="${1:-.}"
    
    if [[ ! -f "$project_dir/package.json" ]]; then
        print_warning "未找到 package.json，跳过 npm 依赖检查"
        return 0
    fi
    
    cd "$project_dir" || return 1
    
    print_info "当前项目: $project_dir"
    echo ""
    
    # 检查依赖树
    if npm ls --depth=0 &>/dev/null; then
        print_success "npm 依赖树正常"
        echo ""
        print_info "依赖树："
        npm ls --depth=1 2>/dev/null | head -30
    else
        print_error "npm 依赖树存在问题"
        echo ""
        print_info "错误详情："
        npm ls --depth=0 2>&1 | head -20
    fi
    
    echo ""
    print_info "过时的包："
    npm outdated 2>/dev/null | head -20 || print_info "所有包都是最新版本"
}

# 检查 pip 依赖
check_pip_dependencies() {
    if ! command_exists pip3 && ! command_exists pip; then
        print_info "pip 未安装，跳过"
        return 0
    fi
    
    local pip_cmd="pip3"
    command_exists pip3 || pip_cmd="pip"
    
    print_info "检查 pip 依赖..."
    echo ""
    
    # 检查已安装的包
    print_info "已安装的包："
    $pip_cmd list | head -20
    echo ""
    
    # 检查过时的包
    print_info "过时的包："
    $pip_cmd list --outdated 2>/dev/null | head -20 || print_info "所有包都是最新版本"
    echo ""
    
    # 检查依赖冲突
    print_info "检查依赖冲突..."
    if command_exists pipdeptree; then
        pipdeptree 2>/dev/null | head -30
    else
        print_warning "建议安装 pipdeptree 来更好地检查依赖树"
        print_info "安装命令: $pip_cmd install pipdeptree"
    fi
}

# 检查系统包依赖
check_system_dependencies() {
    print_info "检查系统包依赖..."
    echo ""
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            print_info "检查损坏的依赖："
            sudo apt-get check 2>/dev/null || print_info "未发现损坏的依赖"
            echo ""
            print_info "未使用的依赖："
            sudo apt-get autoremove --dry-run 2>/dev/null | grep -E "^Remv|^Del" | head -20 || print_info "没有未使用的依赖"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            print_info "检查依赖问题："
            sudo $PACKAGE_MANAGER check 2>/dev/null || print_info "未发现依赖问题"
        fi
    elif [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
        print_info "检查 Homebrew 依赖："
        brew doctor 2>&1 | head -30
    fi
}

# 修复 npm 依赖
fix_npm_dependencies() {
    local project_dir="${1:-.}"
    
    if [[ ! -f "$project_dir/package.json" ]]; then
        print_error "未找到 package.json"
        return 1
    fi
    
    cd "$project_dir" || return 1
    
    print_info "修复 npm 依赖..."
    
    if confirm "是否删除 node_modules 并重新安装？"; then
        rm -rf node_modules package-lock.json
        npm install
        log_troubleshoot "dependencies" "修复 npm 依赖: $project_dir"
    fi
}

# 修复 pip 依赖
fix_pip_dependencies() {
    local pip_cmd="pip3"
    command_exists pip3 || pip_cmd="pip"
    
    print_info "修复 pip 依赖..."
    
    if confirm "是否升级所有过时的包？"; then
        $pip_cmd list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 $pip_cmd install -U
        log_troubleshoot "dependencies" "升级 pip 包"
    fi
}

# 主函数
main() {
    local project_dir="${1:-.}"
    
    check_npm_dependencies "$project_dir"
    echo ""
    check_pip_dependencies
    echo ""
    check_system_dependencies
    echo ""
    
    local choice
    echo "请选择操作："
    echo "  1) 修复 npm 依赖"
    echo "  2) 修复 pip 依赖"
    echo "  0) 退出"
    read -p "请选择 [0-2]: " choice
    
    case $choice in
        1)
            fix_npm_dependencies "$project_dir"
            ;;
        2)
            fix_pip_dependencies
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "无效的选择"
            ;;
    esac
    
    echo ""
    print_title "依赖冲突排查完成"
    log_troubleshoot "dependencies" "依赖检查和修复"
}

main "$@"
