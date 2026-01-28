#!/bin/bash

# 进程管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "进程管理"

# 显示资源占用最高的进程
show_top_processes() {
    local resource="${1:-cpu}"
    local count="${2:-10}"
    
    print_info "占用 $resource 最高的 $count 个进程："
    echo ""
    
    if [[ "$resource" == "cpu" ]]; then
        if command_exists ps; then
            ps aux --sort=-%cpu | head -n $((count + 1)) | awk '{printf "%-8s %6s %6s %10s %s\n", $1, $2, $3"%", $4"%", $11}'
        fi
    elif [[ "$resource" == "memory" ]] || [[ "$resource" == "mem" ]]; then
        if command_exists ps; then
            ps aux --sort=-%mem | head -n $((count + 1)) | awk '{printf "%-8s %6s %6s %10s %s\n", $1, $2, $3"%", $4"%", $11}'
        fi
    fi
}

# 查找进程
find_process() {
    local keyword="${1:-}"
    
    if [[ -z "$keyword" ]]; then
        read -p "请输入进程名称或关键词: " keyword
    fi
    
    if [[ -z "$keyword" ]]; then
        print_error "关键词不能为空"
        return 1
    fi
    
    print_info "查找包含 '$keyword' 的进程..."
    echo ""
    
    if command_exists ps; then
        ps aux | grep -i "$keyword" | grep -v grep || print_info "未找到匹配的进程"
    elif command_exists pgrep; then
        pgrep -fl "$keyword" || print_info "未找到匹配的进程"
    fi
}

# 显示进程详细信息
show_process_info() {
    local pid="${1:-}"
    
    if [[ -z "$pid" ]]; then
        read -p "请输入进程 ID (PID): " pid
    fi
    
    if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
        print_error "无效的进程 ID: $pid"
        return 1
    fi
    
    print_info "进程 $pid 的详细信息："
    echo ""
    
    if command_exists ps; then
        ps -p "$pid" -o pid,ppid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command
    fi
    
    echo ""
    print_info "进程树："
    if command_exists pstree; then
        pstree -p "$pid"
    else
        print_warning "pstree 未安装，无法显示进程树"
    fi
}

# 终止进程
kill_process() {
    local pid="${1:-}"
    local signal="${2:-TERM}"
    
    if [[ -z "$pid" ]]; then
        read -p "请输入要终止的进程 ID (PID): " pid
    fi
    
    if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
        print_error "无效的进程 ID: $pid"
        return 1
    fi
    
    print_warning "将向进程 $pid 发送 $signal 信号"
    
    if ! confirm "确认终止此进程？"; then
        return 0
    fi
    
    if kill -$signal "$pid" 2>/dev/null; then
        print_success "已向进程 $pid 发送 $signal 信号"
        log_troubleshoot "process" "终止进程: $pid"
    else
        print_error "无法终止进程 $pid"
    fi
}

# 显示端口对应的进程
show_port_process() {
    local port="${1:-}"
    
    if [[ -z "$port" ]]; then
        read -p "请输入端口号: " port
    fi
    
    if [[ -z "$port" ]]; then
        print_error "端口号不能为空"
        return 1
    fi
    
    print_info "占用端口 $port 的进程："
    echo ""
    
    if command_exists lsof; then
        lsof -i :$port
    elif command_exists netstat; then
        netstat -tulpn 2>/dev/null | grep ":$port " || print_info "未找到占用端口 $port 的进程"
    elif command_exists ss; then
        ss -tulpn 2>/dev/null | grep ":$port " || print_info "未找到占用端口 $port 的进程"
    else
        print_error "需要 lsof、netstat 或 ss 工具"
    fi
}

# 主函数
main() {
    show_top_processes "cpu" 10
    echo ""
    show_top_processes "memory" 10
    echo ""
    
    local choice
    echo "请选择操作："
    echo "  1) 查找进程"
    echo "  2) 查看进程详细信息"
    echo "  3) 终止进程"
    echo "  4) 查看端口对应的进程"
    echo "  0) 退出"
    read -p "请选择 [0-4]: " choice
    
    case $choice in
        1)
            find_process
            ;;
        2)
            show_process_info
            ;;
        3)
            kill_process
            ;;
        4)
            show_port_process
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "无效的选择"
            ;;
    esac
    
    echo ""
    print_title "进程管理完成"
}

main "$@"
