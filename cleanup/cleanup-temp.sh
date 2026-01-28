#!/bin/bash

# 临时文件清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "临时文件清理"

# 加载路径配置
load_paths_config() {
    local config_file="$SCRIPT_DIR/../config/paths.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# 清理临时目录
cleanup_temp_dirs() {
    load_paths_config
    
    local temp_dirs=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "/tmp"
        "/var/tmp"
    )
    
    # 从配置文件加载
    if [[ -n "${TEMP_DIRS[@]}" ]]; then
        temp_dirs=("${TEMP_DIRS[@]}")
    fi
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [[ ! -d "$temp_dir" ]]; then
            continue
        fi
        
        # 安全检查
        if ! is_safe_to_delete "$temp_dir"; then
            print_warning "跳过受保护的目录: $temp_dir"
            continue
        fi
        
        local size=$(get_dir_size "$temp_dir")
        print_info "检查临时目录: $temp_dir ($size)"
        
        # 查找旧文件（7天前修改的）
        local old_files=$(find "$temp_dir" -type f -mtime +7 2>/dev/null | wc -l)
        
        if [[ $old_files -gt 0 ]]; then
            print_info "发现 $old_files 个旧文件（7天前）"
            
            if confirm "是否清理 $temp_dir 中的旧文件？"; then
                local deleted=0
                find "$temp_dir" -type f -mtime +7 -print0 2>/dev/null | while IFS= read -r -d '' file; do
                    if safe_delete_file "$file"; then
                        deleted=$((deleted + 1))
                    fi
                done
                
                # 删除空目录
                find "$temp_dir" -type d -empty -delete 2>/dev/null
                
                log_cleanup "temp" "临时文件: $temp_dir"
                print_success "已清理 $temp_dir"
            fi
        else
            print_info "没有需要清理的旧文件"
        fi
    done
}

# 清理特定类型的临时文件
cleanup_specific_temp_files() {
    print_info "查找特定类型的临时文件..."
    
    local patterns=(
        "*.tmp"
        "*.temp"
        "*.log"
        "*.cache"
        "*.swp"
        "*.swo"
        "*~"
        ".DS_Store"
    )
    
    local search_dirs=(
        "$HOME/Downloads"
        "$HOME/Desktop"
    )
    
    for dir in "${search_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi
        
        for pattern in "${patterns[@]}"; do
            local files=$(find "$dir" -name "$pattern" -type f 2>/dev/null)
            
            if [[ -n "$files" ]]; then
                local count=$(echo "$files" | wc -l)
                print_info "在 $dir 中发现 $count 个 $pattern 文件"
                
                if confirm "是否删除这些文件？"; then
                    echo "$files" | while read -r file; do
                        safe_delete_file "$file"
                    done
                    log_cleanup "temp" "临时文件类型 $pattern: $dir"
                fi
            fi
        done
    done
}

# 清理浏览器下载的临时文件
cleanup_browser_downloads() {
    print_info "查找浏览器下载的临时文件..."
    
    local download_dirs=(
        "$HOME/Downloads"
    )
    
    for dir in "${download_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi
        
        # 查找不完整的下载文件（.crdownload, .part 等）
        local incomplete_files=$(find "$dir" -type f \( -name "*.crdownload" -o -name "*.part" -o -name "*.download" \) 2>/dev/null)
        
        if [[ -n "$incomplete_files" ]]; then
            local count=$(echo "$incomplete_files" | wc -l)
            print_info "发现 $count 个不完整的下载文件"
            
            if confirm "是否删除这些不完整的下载文件？"; then
                echo "$incomplete_files" | while read -r file; do
                    safe_delete_file "$file"
                done
                log_cleanup "temp" "不完整下载文件: $dir"
            fi
        fi
    done
}

# 主函数
main() {
    cleanup_temp_dirs
    cleanup_specific_temp_files
    cleanup_browser_downloads
    
    echo ""
    print_title "临时文件清理完成"
}

main "$@"
