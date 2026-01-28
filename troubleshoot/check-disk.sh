#!/bin/bash

# 磁盘空间分析脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "磁盘空间分析"

# 显示磁盘使用情况
show_disk_usage() {
    print_info "磁盘使用情况："
    echo ""
    
    if command_exists df; then
        df -h | grep -E "^Filesystem|^/dev"
    else
        print_error "df 命令不可用"
    fi
}

# 查找大文件
find_large_files() {
    local search_dir="${1:-$HOME}"
    local size_limit="${2:-100M}"
    
    print_info "查找大于 $size_limit 的文件（在 $search_dir 中）..."
    echo ""
    
    if command_exists find; then
        find "$search_dir" -type f -size +$size_limit 2>/dev/null | while read -r file; do
            if [[ -f "$file" ]]; then
                local size=$(get_file_size "$file")
                echo "  $file ($size)"
            fi
        done | head -20
        
        print_info "（仅显示前20个）"
    else
        print_error "find 命令不可用"
    fi
}

# 显示目录大小
show_dir_sizes() {
    local search_dir="${1:-$HOME}"
    local top_n="${2:-10}"
    
    print_info "最大的 $top_n 个目录（在 $search_dir 中）："
    echo ""
    
    if command_exists du; then
        du -h -d 1 "$search_dir" 2>/dev/null | sort -hr | head -$top_n | while read -r line; do
            echo "  $line"
        done
    else
        print_error "du 命令不可用"
    fi
}

# 查找空目录
find_empty_dirs() {
    local search_dir="${1:-$HOME}"
    
    print_info "查找空目录（在 $search_dir 中）..."
    echo ""
    
    if command_exists find; then
        local empty_dirs=$(find "$search_dir" -type d -empty 2>/dev/null | head -20)
        
        if [[ -n "$empty_dirs" ]]; then
            echo "$empty_dirs" | while read -r dir; do
                echo "  $dir"
            done
        else
            print_info "未找到空目录"
        fi
    fi
}

# 分析特定目录
analyze_directory() {
    local dir="${1:-}"
    
    if [[ -z "$dir" ]]; then
        read -p "请输入要分析的目录路径: " dir
    fi
    
    if [[ ! -d "$dir" ]]; then
        print_error "目录不存在: $dir"
        return 1
    fi
    
    print_info "分析目录: $dir"
    echo ""
    
    local total_size=$(get_dir_size "$dir")
    print_info "总大小: $total_size"
    echo ""
    
    show_dir_sizes "$dir" 10
}

# 查找重复文件
find_duplicate_files() {
    local search_dir="${1:-$HOME}"
    
    print_info "查找重复文件（在 $search_dir 中）..."
    print_warning "这可能需要较长时间..."
    echo ""
    
    if command_exists fdupes; then
        fdupes -r "$search_dir" 2>/dev/null | head -50
    else
        print_warning "需要安装 fdupes 工具来查找重复文件"
        print_info "可以使用以下命令安装："
        if [[ "$OS_TYPE" == "macos" ]]; then
            echo "  brew install fdupes"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            echo "  sudo apt-get install fdupes"
        fi
    fi
}

# 主函数
main() {
    show_disk_usage
    echo ""
    
    show_dir_sizes "$HOME" 10
    echo ""
    
    if confirm "是否查找大文件（>100MB）？"; then
        find_large_files "$HOME" "100M"
        echo ""
    fi
    
    if confirm "是否查找空目录？"; then
        find_empty_dirs "$HOME"
        echo ""
    fi
    
    if confirm "是否分析特定目录？"; then
        analyze_directory
        echo ""
    fi
    
    if confirm "是否查找重复文件？（可能需要较长时间）"; then
        find_duplicate_files "$HOME"
        echo ""
    fi
    
    echo ""
    print_title "磁盘分析完成"
    log_troubleshoot "disk" "磁盘空间分析"
}

main "$@"
