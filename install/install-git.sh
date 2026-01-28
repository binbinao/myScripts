#!/bin/bash

# Git 及相关工具安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Git 及相关工具安装"

# 安装 Git
install_git() {
    if check_version "git" "git --version"; then
        print_info "Git 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 Git..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install git" "安装 Git"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y git" "安装 Git"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "sudo $PACKAGE_MANAGER install -y git" "安装 Git"
        else
            print_error "不支持的包管理器"
            return 1
        fi
    fi
    
    if check_version "git"; then
        local version=$(git --version)
        log_installation "Git" "$version"
        return 0
    else
        return 1
    fi
}

# 配置 Git（可选）
configure_git() {
    if ! command_exists git; then
        return 1
    fi
    
    if confirm "是否配置 Git 用户信息？"; then
        read -p "请输入 Git 用户名: " git_name
        read -p "请输入 Git 邮箱: " git_email
        
        if [[ -n "$git_name" ]]; then
            run_command "git config --global user.name \"$git_name\"" "设置 Git 用户名"
        fi
        
        if [[ -n "$git_email" ]]; then
            run_command "git config --global user.email \"$git_email\"" "设置 Git 邮箱"
        fi
        
        # 设置默认分支名
        run_command "git config --global init.defaultBranch main" "设置默认分支名"
        
        print_success "Git 配置完成"
    fi
}

# 安装 Git 相关工具（可选）
install_git_tools() {
    if ! confirm "是否安装 Git 相关工具（GitHub CLI、Git LFS）？"; then
        return 0
    fi
    
    # 安装 GitHub CLI
    if ! command_exists gh; then
        if [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
            run_command "brew install gh" "安装 GitHub CLI"
        elif [[ "$OS_TYPE" == "linux" ]]; then
            if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                run_command "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg" "添加 GitHub CLI 密钥"
                run_command "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null" "添加 GitHub CLI 仓库"
                run_command "sudo apt-get update" "更新包列表"
                run_command "sudo apt-get install -y gh" "安装 GitHub CLI"
            fi
        fi
        if command_exists gh; then
            local version=$(gh --version | head -n 1)
            log_installation "GitHub CLI" "$version"
        fi
    else
        print_info "GitHub CLI 已安装"
    fi
    
    # 安装 Git LFS
    if ! command_exists git-lfs; then
        if [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
            run_command "brew install git-lfs" "安装 Git LFS"
        elif [[ "$OS_TYPE" == "linux" ]]; then
            if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                run_command "curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash" "添加 Git LFS 仓库"
                run_command "sudo apt-get install -y git-lfs" "安装 Git LFS"
            elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                run_command "curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash" "添加 Git LFS 仓库"
                run_command "sudo $PACKAGE_MANAGER install -y git-lfs" "安装 Git LFS"
            fi
        fi
        if command_exists git-lfs; then
            run_command "git lfs install" "初始化 Git LFS"
            local version=$(git-lfs --version)
            log_installation "Git LFS" "$version"
        fi
    else
        print_info "Git LFS 已安装"
    fi
}

# 主函数
main() {
    install_git
    configure_git
    install_git_tools
    
    echo ""
    print_title "安装完成"
    echo "已安装工具版本："
    command_exists git && echo "  Git: $(git --version)"
    command_exists gh && echo "  GitHub CLI: $(gh --version | head -n 1)"
    command_exists git-lfs && echo "  Git LFS: $(git-lfs --version)"
}

main "$@"
