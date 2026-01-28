#!/bin/bash

# 权限问题排查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "权限问题排查"

# 检查文件权限
check_file_permissions() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        read -p "请输入文件或目录路径: " file
    fi
    
    if [[ ! -e "$file" ]]; then
        print_error "文件或目录不存在: $file"
        return 1
    fi
    
    print_info "文件/目录权限信息："
    echo ""
    
    if command_exists ls; then
        ls -ld "$file"
        echo ""
        
        if [[ -f "$file" ]]; then
            print_info "文件详细信息："
            stat "$file" 2>/dev/null || ls -l "$file"
        elif [[ -d "$file" ]]; then
            print_info "目录内容权限："
            ls -la "$file" | head -20
        fi
    fi
}

# 检查当前用户权限
check_user_permissions() {
    print_info "当前用户信息："
    echo ""
    echo "  用户名: $(whoami)"
    echo "  用户 ID: $(id -u)"
    echo "  组 ID: $(id -g)"
    echo "  所属组: $(id -gn)"
    echo "  所有组: $(id -Gn)"
    echo ""
    
    print_info "sudo 权限检查："
    if sudo -n true 2>/dev/null; then
        print_success "当前用户具有 sudo 权限"
    else
        print_warning "当前用户可能没有 sudo 权限，或需要输入密码"
    fi
}

# 查找权限异常的文件
find_permission_issues() {
    local search_dir="${1:-$HOME}"
    
    print_info "查找权限异常的文件（在 $search_dir 中）..."
    echo ""
    
    print_info "查找可执行但非脚本的文件："
    find "$search_dir" -type f -executable ! -name "*.sh" ! -name "*.py" ! -name "*.pl" ! -name "*.rb" 2>/dev/null | head -20
    
    echo ""
    print_info "查找权限为 777 的文件："
    find "$search_dir" -type f -perm 777 2>/dev/null | head -20
    
    echo ""
    print_info "查找没有读取权限的文件："
    find "$search_dir" -type f ! -readable 2>/dev/null | head -20
}

# 修复常见权限问题
fix_permissions() {
    local target="${1:-}"
    
    if [[ -z "$target" ]]; then
        read -p "请输入要修复的文件或目录路径: " target
    fi
    
    if [[ ! -e "$target" ]]; then
        print_error "文件或目录不存在: $target"
        return 1
    fi
    
    print_warning "将修复 $target 的权限"
    
    if ! confirm "确认修复？"; then
        return 0
    fi
    
    if [[ -f "$target" ]]; then
        # 文件：644
        chmod 644 "$target" 2>/dev/null && print_success "已设置文件权限为 644" || print_error "权限设置失败"
    elif [[ -d "$target" ]]; then
        # 目录：755
        chmod 755 "$target" 2>/dev/null && print_success "已设置目录权限为 755" || print_error "权限设置失败"
    fi
    
    # 修复所有者
    if [[ "$(stat -c %U "$target" 2>/dev/null || stat -f %Su "$target" 2>/dev/null)" != "$(whoami)" ]]; then
        if confirm "文件所有者不是当前用户，是否修复？"; then
            check_sudo
            sudo chown -R "$(whoami):$(id -gn)" "$target" 2>/dev/null && print_success "已修复所有者" || print_error "所有者修复失败"
        fi
    fi
}

# 检查目录写入权限
check_write_permission() {
    local dir="${1:-}"
    
    if [[ -z "$dir" ]]; then
        read -p "请输入目录路径: " dir
    fi
    
    if [[ ! -d "$dir" ]]; then
        print_error "目录不存在: $dir"
        return 1
    fi
    
    print_info "检查目录写入权限: $dir"
    
    if [[ -w "$dir" ]]; then
        print_success "目录可写"
    else
        print_error "目录不可写"
        
        if confirm "是否尝试修复写入权限？"; then
            check_sudo
            sudo chmod u+w "$dir" 2>/dev/null && print_success "已添加写入权限" || print_error "权限修复失败"
        fi
    fi
}

# 主函数
main() {
    check_user_permissions
    echo ""
    
    local choice
    echo "请选择操作："
    echo "  1) 检查文件/目录权限"
    echo "  2) 查找权限异常的文件"
    echo "  3) 修复权限问题"
    echo "  4) 检查目录写入权限"
    echo "  0) 退出"
    read -p "请选择 [0-4]: " choice
    
    case $choice in
        1)
            check_file_permissions
            ;;
        2)
            find_permission_issues
            ;;
        3)
            fix_permissions
            ;;
        4)
            check_write_permission
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "无效的选择"
            ;;
    esac
    
    echo ""
    print_title "权限排查完成"
    log_troubleshoot "permission" "权限检查和修复"
}

main "$@"
