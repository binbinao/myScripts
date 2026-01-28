#!/bin/bash

# Docker 及 Docker Compose 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Docker 及 Docker Compose 安装"

# 安装 Docker
install_docker() {
    if check_version "docker" "docker --version"; then
        print_info "Docker 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 Docker..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        print_info "在 macOS 上，推荐使用 Docker Desktop"
        if confirm "是否通过 Homebrew 安装 Docker Desktop？"; then
            run_command "brew install --cask docker" "安装 Docker Desktop"
            print_success "Docker Desktop 已安装"
            print_info "请从应用程序中启动 Docker Desktop"
        else
            print_info "您可以手动下载 Docker Desktop: https://www.docker.com/products/docker-desktop"
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            # 卸载旧版本
            run_command "sudo apt-get remove -y docker docker-engine docker.io containerd runc" "卸载旧版本 Docker" || true
            
            # 安装依赖
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y ca-certificates curl gnupg lsb-release" "安装依赖"
            
            # 添加 Docker 官方 GPG 密钥
            run_command "sudo mkdir -p /etc/apt/keyrings" "创建密钥目录"
            run_command "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg" "添加 GPG 密钥"
            
            # 设置仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装 Docker Engine
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "安装 Docker"
            
            # 将当前用户添加到 docker 组
            run_command "sudo usermod -aG docker $USER" "添加用户到 docker 组"
            print_warning "请重新登录以使 docker 组权限生效"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            # 卸载旧版本
            run_command "sudo $PACKAGE_MANAGER remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine" "卸载旧版本 Docker" || true
            
            # 安装依赖
            run_command "sudo $PACKAGE_MANAGER install -y yum-utils" "安装 yum-utils"
            
            # 添加 Docker 仓库
            run_command "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo" "添加 Docker 仓库"
            
            # 安装 Docker Engine
            run_command "sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "安装 Docker"
            
            # 启动 Docker
            run_command "sudo systemctl start docker" "启动 Docker 服务"
            run_command "sudo systemctl enable docker" "设置 Docker 开机自启"
            
            # 将当前用户添加到 docker 组
            run_command "sudo usermod -aG docker $USER" "添加用户到 docker 组"
            print_warning "请重新登录以使 docker 组权限生效"
        else
            print_error "不支持的包管理器"
            return 1
        fi
    fi
    
    if check_version "docker"; then
        local version=$(docker --version)
        log_installation "Docker" "$version"
        return 0
    else
        print_warning "Docker 安装完成，但可能需要重启终端或重新登录"
        return 0
    fi
}

# 安装 Docker Compose
install_docker_compose() {
    if check_version "docker-compose" "docker-compose --version"; then
        print_info "Docker Compose 已安装，跳过"
        return 0
    fi
    
    # Docker Compose V2 已集成到 Docker 中
    if command_exists docker && docker compose version &>/dev/null; then
        print_info "Docker Compose V2 已可用（作为 Docker 插件）"
        local version=$(docker compose version)
        log_installation "Docker Compose" "$version"
        return 0
    fi
    
    print_info "开始安装 Docker Compose..."
    
    local compose_version="v2.23.0"
    local compose_url="https://github.com/docker/compose/releases/download/$compose_version/docker-compose-$(uname -s)-$(uname -m)"
    local install_path="/usr/local/bin/docker-compose"
    
    print_info "下载 Docker Compose..."
    check_sudo
    run_command "sudo curl -L $compose_url -o $install_path" "下载 Docker Compose"
    run_command "sudo chmod +x $install_path" "设置执行权限"
    
    if check_version "docker-compose"; then
        local version=$(docker-compose --version)
        log_installation "Docker Compose" "$version"
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    install_docker
    install_docker_compose
    
    echo ""
    print_title "安装完成"
    echo "已安装工具版本："
    command_exists docker && echo "  Docker: $(docker --version)"
    if command_exists docker && docker compose version &>/dev/null; then
        echo "  Docker Compose: $(docker compose version)"
    elif command_exists docker-compose; then
        echo "  Docker Compose: $(docker-compose --version)"
    fi
}

main "$@"
