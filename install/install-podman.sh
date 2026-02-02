#!/bin/bash

# Podman 安装脚本
# Podman 是 Docker 的无守护进程替代方案

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Podman 安装"

# 添加 docker alias 到 shell 配置文件
add_docker_alias() {
    local shell_config=""
    local current_shell=$(basename "$SHELL")
    
    # 检测当前使用的 shell 和配置文件
    if [[ "$current_shell" == "zsh" ]] || [[ -n "$ZSH_VERSION" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ "$current_shell" == "bash" ]] || [[ -n "$BASH_VERSION" ]]; then
        shell_config="$HOME/.bashrc"
    else
        # 如果无法确定，尝试两个文件
        if [[ -f "$HOME/.zshrc" ]]; then
            shell_config="$HOME/.zshrc"
        elif [[ -f "$HOME/.bashrc" ]]; then
            shell_config="$HOME/.bashrc"
        else
            # 如果都不存在，创建 .zshrc（macOS 默认）或 .bashrc（Linux 默认）
            if [[ "$OS_TYPE" == "macos" ]]; then
                shell_config="$HOME/.zshrc"
            else
                shell_config="$HOME/.bashrc"
            fi
        fi
    fi
    
    # 检查是否已存在 docker alias
    if [[ -f "$shell_config" ]] && grep -q "alias docker=" "$shell_config"; then
        print_info "检测到已存在 docker alias，跳过添加"
        return 0
    fi
    
    # 添加 alias
    print_info "添加 docker alias 到 $shell_config"
    {
        echo ""
        echo "# Podman alias for Docker compatibility (added by install-podman.sh)"
        echo "alias docker='podman'"
        echo "alias docker-compose='podman-compose'"
    } >> "$shell_config"
    
    print_success "已添加 docker alias 到 $shell_config"
    print_warning "请运行以下命令使配置生效："
    if [[ "$shell_config" == *".zshrc" ]]; then
        echo "  source ~/.zshrc"
    else
        echo "  source ~/.bashrc"
    fi
}

# 安装或升级 Podman
install_podman() {
    if command_exists podman && podman --version &>/dev/null; then
        local current_ver
        current_ver=$(get_current_version "podman" "podman --version")
        if [[ -n "$current_ver" ]]; then
            if confirm "是否通过包管理器升级 Podman？（当前: $current_ver）" "n"; then
                check_sudo
                if [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
                    run_command "brew upgrade podman" "升级 Podman"
                elif [[ "$OS_TYPE" == "linux" ]]; then
                    if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                        run_command "sudo apt-get update" "更新包列表"
                        run_command "sudo apt-get install -y --only-upgrade podman 2>/dev/null || sudo apt-get install -y podman" "升级 Podman"
                    elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                        run_command "sudo $PACKAGE_MANAGER upgrade -y podman" "升级 Podman"
                    fi
                fi
            else
                print_info "Podman 已安装（$current_ver），跳过"
            fi
        else
            print_info "Podman 已安装，跳过"
        fi
        if confirm "是否添加 docker alias 到 shell 配置文件？"; then
            add_docker_alias
        fi
        command_exists podman && log_installation "Podman" "$(podman --version)"
        return 0
    fi
    
    print_info "开始安装 Podman..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install podman" "安装 Podman"
        
        # 初始化 Podman 机器（macOS 需要）
        print_info "初始化 Podman 机器..."
        if podman machine init &>/dev/null || podman machine list &>/dev/null; then
            print_info "Podman 机器已初始化或已存在"
        fi
        
        if ! podman machine list | grep -q "podman-machine"; then
            print_info "启动 Podman 机器..."
            podman machine start 2>/dev/null || true
        fi
        
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            # Ubuntu/Debian
            # 添加 Podman 仓库
            print_info "添加 Podman 仓库..."
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y software-properties-common" "安装软件属性工具" || true
            run_command "sudo add-apt-repository -y ppa:projectatomic/ppa" "添加 Podman PPA" || true
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y podman" "安装 Podman"
            
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            # CentOS/RHEL/Fedora
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                # Fedora 通常已包含 Podman
                run_command "sudo dnf install -y podman" "安装 Podman"
            else
                # CentOS/RHEL
                run_command "sudo yum install -y podman" "安装 Podman"
            fi
        else
            print_error "不支持的包管理器"
            return 1
        fi
        
        # 配置 subuid 和 subgid（Linux 需要）
        print_info "配置用户命名空间..."
        if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
            print_info "配置 subuid..."
            echo "$USER:100000:65536" | sudo tee -a /etc/subuid > /dev/null
        fi
        if ! grep -q "^$USER:" /etc/subgid 2>/dev/null; then
            print_info "配置 subgid..."
            echo "$USER:100000:65536" | sudo tee -a /etc/subgid > /dev/null
        fi
    fi
    
    # 验证安装
    if command_exists podman && podman --version &>/dev/null; then
        local version=$(podman --version)
        log_installation "Podman" "$version"
        print_success "Podman 安装完成"
        
        # 询问是否添加 alias
        if confirm "是否添加 docker alias 到 shell 配置文件？"; then
            add_docker_alias
        fi
        
        return 0
    else
        print_warning "Podman 安装完成，但可能需要重启终端"
        return 0
    fi
}

# 安装 Podman Compose（可选）
install_podman_compose() {
    if command_exists podman-compose && podman-compose --version &>/dev/null; then
        local version=$(podman-compose --version 2>/dev/null | head -n 1)
        print_info "Podman Compose 已安装: $version"
        return 0
    fi
    
    if ! confirm "是否安装 Podman Compose（Docker Compose 的替代）？"; then
        return 0
    fi
    
    print_info "开始安装 Podman Compose..."
    
    # 使用 pip 安装 podman-compose
    if command_exists pip3; then
        run_command "pip3 install --user podman-compose" "安装 Podman Compose"
    elif command_exists pip; then
        run_command "pip install --user podman-compose" "安装 Podman Compose"
    else
        print_warning "未找到 pip，跳过 Podman Compose 安装"
        print_info "您可以稍后使用以下命令安装："
        print_info "  pip3 install --user podman-compose"
        return 0
    fi
    
    if command_exists podman-compose && podman-compose --version &>/dev/null; then
        local version=$(podman-compose --version 2>/dev/null | head -n 1)
        log_installation "Podman Compose" "$version"
        print_success "Podman Compose 安装完成"
        print_warning "请重新打开终端或运行: source ~/.zshrc (或 ~/.bashrc)"
        return 0
    else
        print_warning "Podman Compose 安装可能未完成"
        return 1
    fi
}

# 主函数
main() {
    install_podman
    install_podman_compose
    
    echo ""
    print_title "安装完成"
    echo "已安装工具版本："
    command_exists podman && echo "  Podman: $(podman --version)"
    command_exists podman-compose && echo "  Podman Compose: $(podman-compose --version 2>/dev/null | head -n 1)"
    
    if [[ -f "$HOME/.zshrc" ]] && grep -q "alias docker=" "$HOME/.zshrc"; then
        echo ""
        print_info "已配置 docker alias，使用 'docker' 命令将调用 podman"
    elif [[ -f "$HOME/.bashrc" ]] && grep -q "alias docker=" "$HOME/.bashrc"; then
        echo ""
        print_info "已配置 docker alias，使用 'docker' 命令将调用 podman"
    fi
}

main "$@"
