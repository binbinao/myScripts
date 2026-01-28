#!/bin/bash

# 性能分析脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "性能分析"

# 显示系统负载
show_system_load() {
    print_info "系统负载："
    echo ""
    
    if command_exists uptime; then
        uptime
    else
        print_warning "uptime 命令不可用"
    fi
    
    echo ""
    if command_exists top; then
        print_info "CPU 和内存使用情况（按 q 退出）："
        top -l 1 2>/dev/null || top -bn1 | head -20
    elif command_exists htop; then
        print_info "使用 htop 查看详细信息（按 q 退出）"
        htop
    fi
}

# 显示 CPU 使用情况
show_cpu_usage() {
    print_info "CPU 使用情况："
    echo ""
    
    if command_exists top; then
        top -l 1 -n 10 -stats pid,command,cpu 2>/dev/null | head -15 || \
        top -bn1 | head -20
    elif command_exists ps; then
        ps aux --sort=-%cpu | head -11 | awk '{printf "%-8s %6s %6s %s\n", $1, $2, $3"%", $11}'
    fi
}

# 显示内存使用情况
show_memory_usage() {
    print_info "内存使用情况："
    echo ""
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576);'
    elif [[ "$OS_TYPE" == "linux" ]]; then
        free -h
    fi
    
    echo ""
    print_info "占用内存最多的进程："
    if command_exists ps; then
        ps aux --sort=-%mem | head -11 | awk '{printf "%-8s %6s %6s %10s %s\n", $1, $2, $3"%", $4"%", $11}'
    fi
}

# 显示磁盘 I/O
show_disk_io() {
    print_info "磁盘 I/O 使用情况："
    echo ""
    
    if command_exists iostat; then
        iostat -x 1 2 2>/dev/null || print_warning "iostat 不可用"
    elif command_exists vm_stat; then
        print_info "磁盘活动（macOS）："
        iotop -o -d 1 -n 3 2>/dev/null || print_warning "需要安装 iotop"
    else
        print_warning "无法显示磁盘 I/O 信息（需要 iostat 或 iotop）"
    fi
}

# 显示网络流量
show_network_traffic() {
    print_info "网络流量："
    echo ""
    
    if command_exists iftop; then
        print_info "使用 iftop 查看网络流量（按 q 退出）"
        sudo iftop
    elif command_exists nethogs; then
        print_info "使用 nethogs 查看网络流量（按 q 退出）"
        sudo nethogs
    else
        print_warning "需要 iftop 或 nethogs 来查看网络流量"
        print_info "可以使用以下命令安装："
        if [[ "$OS_TYPE" == "macos" ]]; then
            echo "  brew install iftop"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            echo "  sudo apt-get install iftop nethogs"
        fi
    fi
}

# 监控特定进程
monitor_process() {
    local pid="${1:-}"
    
    if [[ -z "$pid" ]]; then
        read -p "请输入进程 ID (PID): " pid
    fi
    
    if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
        print_error "无效的进程 ID: $pid"
        return 1
    fi
    
    print_info "监控进程 $pid（按 Ctrl+C 停止）..."
    echo ""
    
    while kill -0 "$pid" 2>/dev/null; do
        if command_exists ps; then
            clear
            print_title "进程 $pid 监控"
            ps -p "$pid" -o pid,ppid,user,%cpu,%mem,vsz,rss,time,command
            echo ""
            print_info "按 Ctrl+C 停止监控"
        fi
        sleep 2
    done
    
    print_warning "进程 $pid 已结束"
}

# 主函数
main() {
    show_system_load
    echo ""
    show_cpu_usage
    echo ""
    show_memory_usage
    echo ""
    show_disk_io
    echo ""
    
    local choice
    echo "请选择操作："
    echo "  1) 查看网络流量"
    echo "  2) 监控特定进程"
    echo "  0) 退出"
    read -p "请选择 [0-2]: " choice
    
    case $choice in
        1)
            show_network_traffic
            ;;
        2)
            monitor_process
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "无效的选择"
            ;;
    esac
    
    echo ""
    print_title "性能分析完成"
    log_troubleshoot "performance" "系统性能分析"
}

main "$@"
