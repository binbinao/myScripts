#!/bin/bash

# 网络问题排查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "网络问题排查"

# 检查网络连接
check_connectivity() {
    print_info "检查网络连接..."
    
    local test_hosts=(
        "8.8.8.8"
        "1.1.1.1"
        "www.google.com"
        "www.baidu.com"
    )
    
    for host in "${test_hosts[@]}"; do
        print_info "测试连接: $host"
        if ping -c 2 -W 2 "$host" &>/dev/null; then
            print_success "$host 连接正常"
        else
            print_error "$host 连接失败"
        fi
    done
}

# 检查 DNS 解析
check_dns() {
    print_info "检查 DNS 解析..."
    
    local test_domains=(
        "google.com"
        "github.com"
        "baidu.com"
    )
    
    for domain in "${test_domains[@]}"; do
        print_info "解析域名: $domain"
        if command_exists dig; then
            dig +short "$domain" | head -1 || print_error "$domain DNS 解析失败"
        elif command_exists nslookup; then
            nslookup "$domain" | grep -A 1 "Name:" || print_error "$domain DNS 解析失败"
        else
            if getent hosts "$domain" &>/dev/null; then
                print_success "$domain DNS 解析正常"
            else
                print_error "$domain DNS 解析失败"
            fi
        fi
    done
}

# 检查端口占用
check_port() {
    local port="${1:-}"
    
    if [[ -z "$port" ]]; then
        print_info "常用端口占用情况："
        local common_ports=(80 443 3000 3306 5432 6379 8080 9000)
        
        for port in "${common_ports[@]}"; do
            if command_exists lsof; then
                local process=$(lsof -i :$port 2>/dev/null | tail -n +2 | awk '{print $1, $2}' | head -1)
                if [[ -n "$process" ]]; then
                    print_warning "端口 $port 被占用: $process"
                else
                    print_info "端口 $port 未被占用"
                fi
            elif command_exists netstat; then
                if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                    print_warning "端口 $port 被占用"
                else
                    print_info "端口 $port 未被占用"
                fi
            elif command_exists ss; then
                if ss -tuln 2>/dev/null | grep -q ":$port "; then
                    print_warning "端口 $port 被占用"
                else
                    print_info "端口 $port 未被占用"
                fi
            fi
        done
    else
        print_info "检查端口 $port 占用情况..."
        if command_exists lsof; then
            local process=$(lsof -i :$port 2>/dev/null)
            if [[ -n "$process" ]]; then
                echo "$process"
            else
                print_info "端口 $port 未被占用"
            fi
        elif command_exists netstat; then
            netstat -tuln 2>/dev/null | grep ":$port " || print_info "端口 $port 未被占用"
        elif command_exists ss; then
            ss -tuln 2>/dev/null | grep ":$port " || print_info "端口 $port 未被占用"
        fi
    fi
}

# 显示网络接口信息
show_interfaces() {
    print_info "网络接口信息："
    echo ""
    
    if command_exists ifconfig; then
        ifconfig | grep -A 1 "^[a-z]" | grep -E "^[a-z]|inet " || ip addr show
    elif command_exists ip; then
        ip addr show
    else
        print_error "无法获取网络接口信息"
    fi
}

# 显示路由表
show_routes() {
    print_info "路由表："
    echo ""
    
    if command_exists route; then
        route -n 2>/dev/null || route
    elif command_exists ip; then
        ip route show
    else
        print_error "无法获取路由表"
    fi
}

# 测试特定端口连接
test_port_connection() {
    local host="${1:-localhost}"
    local port="${2:-80}"
    
    print_info "测试连接 $host:$port..."
    
    if command_exists nc; then
        if nc -z -v "$host" "$port" 2>&1; then
            print_success "端口 $port 可访问"
        else
            print_error "端口 $port 不可访问"
        fi
    elif command_exists telnet; then
        timeout 2 telnet "$host" "$port" 2>&1 | grep -q "Connected" && print_success "端口 $port 可访问" || print_error "端口 $port 不可访问"
    else
        print_warning "需要 nc 或 telnet 工具来测试端口连接"
    fi
}

# 主函数
main() {
    check_connectivity
    echo ""
    check_dns
    echo ""
    check_port
    echo ""
    show_interfaces
    echo ""
    show_routes
    
    echo ""
    if confirm "是否测试特定端口连接？"; then
        read -p "请输入主机地址 [localhost]: " host
        host=${host:-localhost}
        read -p "请输入端口号 [80]: " port
        port=${port:-80}
        test_port_connection "$host" "$port"
    fi
    
    echo ""
    print_title "网络排查完成"
    log_troubleshoot "network" "网络连接和端口检查"
}

main "$@"
