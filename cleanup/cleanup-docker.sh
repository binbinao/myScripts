#!/bin/bash

# Docker 清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Docker 资源清理"

# 检查 Docker 是否运行
check_docker() {
    if ! command_exists docker; then
        print_error "Docker 未安装"
        return 1
    fi
    
    if ! docker info &>/dev/null; then
        print_error "Docker 未运行，请先启动 Docker"
        return 1
    fi
    
    return 0
}

# 显示 Docker 资源使用情况
show_docker_usage() {
    print_info "Docker 资源使用情况："
    echo ""
    docker system df
    echo ""
}

# 清理未使用的镜像
cleanup_unused_images() {
    if ! check_docker; then
        return 1
    fi
    
    print_info "查找未使用的镜像..."
    local unused_images=$(docker images -f "dangling=true" -q)
    
    if [[ -z "$unused_images" ]]; then
        print_info "没有未使用的镜像"
        return 0
    fi
    
    echo "未使用的镜像："
    docker images -f "dangling=true"
    echo ""
    
    if confirm "是否删除未使用的镜像？"; then
        run_command "docker image prune -f" "删除未使用的镜像"
        log_cleanup "docker" "未使用的镜像"
    fi
}

# 清理停止的容器
cleanup_stopped_containers() {
    if ! check_docker; then
        return 1
    fi
    
    print_info "查找停止的容器..."
    local stopped_containers=$(docker ps -a -f "status=exited" -q)
    
    if [[ -z "$stopped_containers" ]]; then
        print_info "没有停止的容器"
        return 0
    fi
    
    echo "停止的容器："
    docker ps -a -f "status=exited"
    echo ""
    
    if confirm "是否删除停止的容器？"; then
        run_command "docker container prune -f" "删除停止的容器"
        log_cleanup "docker" "停止的容器"
    fi
}

# 清理未使用的卷
cleanup_unused_volumes() {
    if ! check_docker; then
        return 1
    fi
    
    print_info "查找未使用的卷..."
    local unused_volumes=$(docker volume ls -f "dangling=true" -q)
    
    if [[ -z "$unused_volumes" ]]; then
        print_info "没有未使用的卷"
        return 0
    fi
    
    echo "未使用的卷："
    docker volume ls -f "dangling=true"
    echo ""
    
    if confirm "是否删除未使用的卷？"; then
        run_command "docker volume prune -f" "删除未使用的卷"
        log_cleanup "docker" "未使用的卷"
    fi
}

# 清理未使用的网络
cleanup_unused_networks() {
    if ! check_docker; then
        return 1
    fi
    
    print_info "查找未使用的网络..."
    local unused_networks=$(docker network ls -f "dangling=true" -q)
    
    if [[ -z "$unused_networks" ]]; then
        print_info "没有未使用的网络"
        return 0
    fi
    
    echo "未使用的网络："
    docker network ls -f "dangling=true"
    echo ""
    
    if confirm "是否删除未使用的网络？"; then
        run_command "docker network prune -f" "删除未使用的网络"
        log_cleanup "docker" "未使用的网络"
    fi
}

# 清理所有未使用的资源
cleanup_all_unused() {
    if ! check_docker; then
        return 1
    fi
    
    print_warning "这将删除所有未使用的镜像、容器、卷和网络"
    
    if confirm "是否清理所有未使用的 Docker 资源？"; then
        run_command "docker system prune -a --volumes -f" "清理所有未使用的资源"
        log_cleanup "docker" "所有未使用的资源"
    fi
}

# 主函数
main() {
    if ! check_docker; then
        exit 1
    fi
    
    show_docker_usage
    
    cleanup_unused_images
    cleanup_stopped_containers
    cleanup_unused_volumes
    cleanup_unused_networks
    
    echo ""
    if confirm "是否清理所有未使用的 Docker 资源（包括未使用的镜像）？"; then
        cleanup_all_unused
    fi
    
    echo ""
    print_title "Docker 清理完成"
    show_docker_usage
}

main "$@"
