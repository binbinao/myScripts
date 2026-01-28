#!/bin/bash

# 日志文件清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "日志文件清理"

# 加载路径配置
load_paths_config() {
    local config_file="$SCRIPT_DIR/../config/paths.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# 清理日志目录
cleanup_log_dirs() {
    load_paths_config
    
    local log_dirs=()
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        log_dirs=(
            "$HOME/Library/Logs"
            "$HOME/.cache"
            "/var/log"
        )
    elif [[ "$OS_TYPE" == "linux" ]]; then
        log_dirs=(
            "$HOME/.cache"
            "/var/log"
        )
    fi
    
    # 从配置文件加载
    if [[ -n "${LOG_DIRS[@]}" ]]; then
        log_dirs=("${LOG_DIRS[@]}")
    fi
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ ! -d "$log_dir" ]]; then
            continue
        fi
        
        # 安全检查
        if ! is_safe_to_delete "$log_dir"; then
            print_warning "跳过受保护的目录: $log_dir"
            continue
        fi
        
        local size=$(get_dir_size "$log_dir")
        print_info "检查日志目录: $log_dir ($size)"
        
        # 查找日志文件
        local log_files=$(find "$log_dir" -type f \( -name "*.log" -o -name "*.log.*" \) -mtime +30 2>/dev/null)
        local log_count=$(echo "$log_files" | grep -v "^$" | wc -l | tr -d ' ')
        
        if [[ $log_count -gt 0 ]]; then
            print_info "发现 $log_count 个旧日志文件（30天前）"
            
            # 显示一些示例
            echo "$log_files" | head -5 | while read -r file; do
                if [[ -n "$file" ]]; then
                    local file_size=$(get_file_size "$file")
                    echo "  $file ($file_size)"
                fi
            done
            
            if [[ $log_count -gt 5 ]]; then
                print_info "... 还有 $((log_count - 5)) 个文件"
            fi
            
            if confirm "是否删除这些旧日志文件？"; then
                local deleted=0
                echo "$log_files" | while read -r file; do
                    if [[ -n "$file" ]] && safe_delete_file "$file"; then
                        deleted=$((deleted + 1))
                    fi
                done
                
                log_cleanup "logs" "日志文件: $log_dir ($log_count 个文件)"
                print_success "已清理 $log_dir"
            fi
        else
            print_info "没有需要清理的旧日志文件"
        fi
    done
}

# 清理应用特定日志
cleanup_app_logs() {
    print_info "查找应用特定日志..."
    
    local app_log_patterns=(
        "$HOME/Library/Logs/*.log"
        "$HOME/.cache/*/*.log"
        "$HOME/.local/share/*/logs/*.log"
    )
    
    for pattern in "${app_log_patterns[@]}"; do
        local files=$(find $(dirname "$pattern") -name "$(basename "$pattern")" -type f -mtime +7 2>/dev/null 2>/dev/null)
        
        if [[ -n "$files" ]]; then
            local count=$(echo "$files" | wc -l)
            print_info "发现 $count 个应用日志文件"
            
            if confirm "是否清理这些应用日志？"; then
                echo "$files" | while read -r file; do
                    if [[ -n "$file" ]] && is_safe_to_delete "$file"; then
                        safe_delete_file "$file"
                    fi
                done
                log_cleanup "logs" "应用日志: $pattern"
            fi
        fi
    done
}

# 清理系统日志（需要权限）
cleanup_system_logs() {
    if [[ "$OS_TYPE" == "linux" ]]; then
        print_info "检查系统日志..."
        
        local syslog_dirs=(
            "/var/log"
        )
        
        for log_dir in "${syslog_dirs[@]}"; do
            if [[ ! -d "$log_dir" ]]; then
                continue
            fi
            
            # 只清理轮转的旧日志
            local rotated_logs=$(find "$log_dir" -type f -name "*.log.*" -o -name "*.gz" -mtime +90 2>/dev/null)
            local count=$(echo "$rotated_logs" | grep -v "^$" | wc -l | tr -d ' ')
            
            if [[ $count -gt 0 ]]; then
                print_info "发现 $count 个旧的系统日志文件（90天前）"
                
                if confirm "是否清理这些旧的系统日志？（需要管理员权限）"; then
                    check_sudo
                    echo "$rotated_logs" | while read -r file; do
                        if [[ -n "$file" ]]; then
                            sudo rm -f "$file" 2>/dev/null && print_success "已删除: $file"
                        fi
                    done
                    log_cleanup "logs" "系统日志: $log_dir"
                fi
            fi
        done
    fi
}

# 主函数
main() {
    cleanup_log_dirs
    cleanup_app_logs
    cleanup_system_logs
    
    echo ""
    print_title "日志文件清理完成"
}

main "$@"
