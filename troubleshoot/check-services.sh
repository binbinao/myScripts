#!/bin/bash

# 服务状态检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "服务状态检查"

# 检查 Docker 服务
check_docker() {
    print_info "检查 Docker 服务..."
    
    if ! command_exists docker; then
        print_warning "Docker 未安装"
        return 1
    fi
    
    if docker info &>/dev/null; then
        print_success "Docker 服务运行正常"
        echo ""
        print_info "Docker 版本: $(docker --version)"
        print_info "Docker Compose 版本: $(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo '未安装')"
        echo ""
        print_info "运行中的容器："
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || print_info "无运行中的容器"
    else
        print_error "Docker 服务未运行或无法连接"
        print_info "请检查 Docker 是否已启动"
    fi
}

# 检查数据库服务
check_database() {
    print_info "检查数据库服务..."
    echo ""
    
    # MySQL
    if command_exists mysql; then
        print_info "MySQL:"
        if mysql -u root -e "SELECT 1;" &>/dev/null 2>&1; then
            print_success "  MySQL 服务运行正常"
            mysql --version
        else
            if systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mysqld 2>/dev/null; then
                print_warning "  MySQL 服务运行中，但无法连接（可能需要密码）"
            else
                print_error "  MySQL 服务未运行"
            fi
        fi
        echo ""
    fi
    
    # PostgreSQL
    if command_exists psql; then
        print_info "PostgreSQL:"
        if systemctl is-active --quiet postgresql 2>/dev/null; then
            print_success "  PostgreSQL 服务运行中"
            psql --version
        else
            print_error "  PostgreSQL 服务未运行"
        fi
        echo ""
    fi
    
    # MongoDB
    if command_exists mongod; then
        print_info "MongoDB:"
        if systemctl is-active --quiet mongod 2>/dev/null || pgrep mongod &>/dev/null; then
            print_success "  MongoDB 服务运行中"
            mongod --version | head -1
        else
            print_error "  MongoDB 服务未运行"
        fi
        echo ""
    fi
    
    # Redis
    if command_exists redis-server; then
        print_info "Redis:"
        if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null || pgrep redis-server &>/dev/null; then
            print_success "  Redis 服务运行中"
            redis-server --version
        else
            print_error "  Redis 服务未运行"
        fi
        echo ""
    fi
}

# 检查系统服务
check_system_services() {
    print_info "检查系统服务状态..."
    echo ""
    
    if command_exists systemctl; then
        print_info "关键服务状态："
        local services=("docker" "mysql" "mysqld" "postgresql" "mongod" "redis" "redis-server")
        
        for service in "${services[@]}"; do
            if systemctl list-unit-files | grep -q "^${service}"; then
                if systemctl is-active --quiet "$service" 2>/dev/null; then
                    print_success "  $service: 运行中"
                else
                    print_warning "  $service: 未运行"
                fi
            fi
        done
    elif [[ "$OS_TYPE" == "macos" ]]; then
        print_info "macOS 服务状态："
        if command_exists brew; then
            brew services list
        fi
    else
        print_warning "无法检查系统服务状态（需要 systemctl）"
    fi
}

# 启动服务
start_service() {
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        read -p "请输入服务名称: " service
    fi
    
    if [[ -z "$service" ]]; then
        print_error "服务名称不能为空"
        return 1
    fi
    
    print_info "启动服务: $service"
    
    if command_exists systemctl; then
        check_sudo
        if sudo systemctl start "$service" 2>/dev/null; then
            print_success "服务 $service 已启动"
            log_troubleshoot "services" "启动服务: $service"
        else
            print_error "无法启动服务 $service"
        fi
    elif [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
        if brew services start "$service" 2>/dev/null; then
            print_success "服务 $service 已启动"
            log_troubleshoot "services" "启动服务: $service"
        else
            print_error "无法启动服务 $service"
        fi
    else
        print_error "无法启动服务（需要 systemctl 或 brew）"
    fi
}

# 停止服务
stop_service() {
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        read -p "请输入服务名称: " service
    fi
    
    if [[ -z "$service" ]]; then
        print_error "服务名称不能为空"
        return 1
    fi
    
    print_warning "停止服务: $service"
    
    if ! confirm "确认停止此服务？"; then
        return 0
    fi
    
    if command_exists systemctl; then
        check_sudo
        if sudo systemctl stop "$service" 2>/dev/null; then
            print_success "服务 $service 已停止"
            log_troubleshoot "services" "停止服务: $service"
        else
            print_error "无法停止服务 $service"
        fi
    elif [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
        if brew services stop "$service" 2>/dev/null; then
            print_success "服务 $service 已停止"
            log_troubleshoot "services" "停止服务: $service"
        else
            print_error "无法停止服务 $service"
        fi
    else
        print_error "无法停止服务（需要 systemctl 或 brew）"
    fi
}

# 主函数
main() {
    check_docker
    echo ""
    check_database
    echo ""
    check_system_services
    echo ""
    
    local choice
    echo "请选择操作："
    echo "  1) 启动服务"
    echo "  2) 停止服务"
    echo "  0) 退出"
    read -p "请选择 [0-2]: " choice
    
    case $choice in
        1)
            start_service
            ;;
        2)
            stop_service
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "无效的选择"
            ;;
    esac
    
    echo ""
    print_title "服务状态检查完成"
    log_troubleshoot "services" "服务状态检查"
}

main "$@"
