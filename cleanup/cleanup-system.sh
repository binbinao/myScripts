#!/bin/bash

# 系统缓存清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "系统缓存清理"

# 清理 DNS 缓存
cleanup_dns_cache() {
    print_info "清理 DNS 缓存..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if confirm "是否清理 DNS 缓存？"; then
            check_sudo
            run_command "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder" "清理 DNS 缓存"
            log_cleanup "system" "DNS 缓存"
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command_exists systemd-resolve; then
            if confirm "是否清理 DNS 缓存？"; then
                check_sudo
                run_command "sudo systemd-resolve --flush-caches" "清理 DNS 缓存"
                log_cleanup "system" "DNS 缓存"
            fi
        else
            print_info "系统未使用 systemd-resolve，跳过 DNS 缓存清理"
        fi
    fi
}

# 清理系统日志
cleanup_system_logs() {
    print_info "清理系统日志..."
    
    local log_dirs=()
    local total_size=0
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        log_dirs=(
            "$HOME/Library/Logs"
            "/var/log"
            "/Library/Logs"
        )
    elif [[ "$OS_TYPE" == "linux" ]]; then
        log_dirs=(
            "/var/log"
            "$HOME/.cache"
        )
    fi
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]] && is_safe_to_delete "$log_dir"; then
            local size=$(get_dir_size "$log_dir")
            print_info "发现日志目录: $log_dir ($size)"
            
            if confirm "是否清理 $log_dir 中的旧日志？"; then
                # 只清理 .log 文件，保留目录结构
                find "$log_dir" -name "*.log" -type f -mtime +30 -exec rm -f {} \; 2>/dev/null
                find "$log_dir" -name "*.log.*" -type f -mtime +30 -exec rm -f {} \; 2>/dev/null
                log_cleanup "system" "日志文件: $log_dir"
            fi
        fi
    done
}

# 清理系统缓存
cleanup_system_cache() {
    print_info "清理系统缓存..."
    
    local cache_dirs=()
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        cache_dirs=(
            "$HOME/Library/Caches"
            "/Library/Caches"
        )
    elif [[ "$OS_TYPE" == "linux" ]]; then
        cache_dirs=(
            "$HOME/.cache"
            "/var/cache"
        )
    fi
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]] && is_safe_to_delete "$cache_dir"; then
            local size=$(get_dir_size "$cache_dir")
            print_info "发现缓存目录: $cache_dir ($size)"
            
            if confirm "是否清理 $cache_dir？"; then
                # 清理缓存但保留目录结构
                find "$cache_dir" -type f -atime +7 -exec rm -f {} \; 2>/dev/null
                find "$cache_dir" -type d -empty -delete 2>/dev/null
                log_cleanup "system" "系统缓存: $cache_dir"
            fi
        fi
    done
}

# 主函数
main() {
    cleanup_dns_cache
    cleanup_system_logs
    cleanup_system_cache
    
    echo ""
    print_title "系统缓存清理完成"
}

main "$@"
