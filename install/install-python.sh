#!/bin/bash

# Python 及相关工具安装脚本
# 支持安装 Python、pip、conda、uv

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Python 及相关工具安装"

# 安装 Python
install_python() {
    if check_version "python3" "python3 --version"; then
        print_info "Python3 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 Python3..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install python@3.11" "安装 Python 3.11"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y python3 python3-pip python3-venv" "安装 Python3 和 pip"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "sudo $PACKAGE_MANAGER install -y python3 python3-pip" "安装 Python3 和 pip"
        else
            print_error "不支持的包管理器"
            return 1
        fi
    fi
    
    if check_version "python3"; then
        local version=$(python3 --version)
        log_installation "Python3" "$version"
        return 0
    else
        return 1
    fi
}

# 检查并升级 pip
check_pip() {
    if check_version "pip3" "pip3 --version"; then
        print_info "pip3 已安装"
        print_info "升级 pip 到最新版本..."
        run_command "python3 -m pip install --upgrade pip" "升级 pip"
        return 0
    else
        print_warning "pip3 未安装，尝试安装..."
        if command_exists python3; then
            run_command "python3 -m ensurepip --upgrade" "安装 pip"
        else
            print_error "需要先安装 Python3"
            return 1
        fi
    fi
}

# 安装 uv
install_uv() {
    if check_version "uv" "uv --version"; then
        print_info "uv 已安装，跳过"
        return 0
    fi
    
    print_info "开始安装 uv..."
    
    # uv 官方推荐使用官方安装脚本
    if command_exists curl; then
        print_info "使用官方安装脚本安装 uv..."
        run_command "curl -LsSf https://astral.sh/uv/install.sh | sh" "安装 uv"
        
        # 添加到 PATH（安装脚本通常会自动添加到 shell 配置文件中）
        # 但为了确保当前会话可用，我们手动添加到 PATH
        local uv_bin="$HOME/.cargo/bin"
        if [[ -d "$uv_bin" ]]; then
            export PATH="$uv_bin:$PATH"
        fi
        
        # 检查是否在 .zshrc 或 .bashrc 中
        if [[ -f "$HOME/.zshrc" ]] && ! grep -q "\.cargo/bin" "$HOME/.zshrc"; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
        fi
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q "\.cargo/bin" "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
        fi
    elif command_exists pip3 || command_exists pip; then
        local pip_cmd="pip3"
        command_exists pip3 || pip_cmd="pip"
        print_info "使用 pip 安装 uv..."
        run_command "$pip_cmd install uv" "安装 uv"
    else
        print_error "需要 curl 或 pip 来安装 uv"
        return 1
    fi
    
    # 验证安装
    if command_exists uv || ([[ -f "$HOME/.cargo/bin/uv" ]] && "$HOME/.cargo/bin/uv" --version &>/dev/null); then
        local uv_cmd="uv"
        if ! command_exists uv; then
            uv_cmd="$HOME/.cargo/bin/uv"
        fi
        local version=$($uv_cmd --version 2>/dev/null | head -n 1)
        log_installation "uv" "$version"
        print_success "uv 安装完成"
        if ! command_exists uv; then
            print_warning "请重新打开终端或运行: source ~/.zshrc (或 ~/.bashrc)"
        fi
        return 0
    else
        print_warning "uv 安装可能未完成，请手动验证"
        return 1
    fi
}

# 安装 conda (Miniconda)
install_conda() {
    if check_version "conda" "conda --version"; then
        print_info "Conda 已安装，跳过"
        return 0
    fi
    
    if ! confirm "是否安装 Miniconda？"; then
        return 0
    fi
    
    print_info "开始安装 Miniconda..."
    
    local conda_installer
    if [[ "$OS_TYPE" == "macos" ]]; then
        if [[ "$(uname -m)" == "arm64" ]]; then
            conda_installer="Miniconda3-latest-MacOSX-arm64.sh"
        else
            conda_installer="Miniconda3-latest-MacOSX-x86_64.sh"
        fi
    else
        conda_installer="Miniconda3-latest-Linux-x86_64.sh"
    fi
    
    local install_dir="$HOME/miniconda3"
    local installer_url="https://repo.anaconda.com/miniconda/$conda_installer"
    
    print_info "下载 Miniconda 安装程序..."
    if command_exists curl; then
        run_command "curl -O $installer_url" "下载安装程序"
    elif command_exists wget; then
        run_command "wget $installer_url" "下载安装程序"
    else
        print_error "需要 curl 或 wget"
        return 1
    fi
    
    print_info "运行安装程序..."
    bash "$conda_installer" -b -p "$install_dir"
    
    # 添加到 PATH
    if [[ -f "$HOME/.zshrc" ]]; then
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    if [[ -f "$HOME/.bashrc" ]]; then
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    
    export PATH="$install_dir/bin:$PATH"
    
    # 清理安装程序
    rm -f "$conda_installer"
    
    if check_version "conda"; then
        local version=$(conda --version)
        log_installation "Conda" "$version"
        print_success "Conda 已安装到 $install_dir"
        print_warning "请重新打开终端或运行: source ~/.zshrc (或 ~/.bashrc)"
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    install_python
    check_pip
    install_uv
    install_conda
    
    echo ""
    print_title "安装完成"
    echo "已安装工具版本："
    command_exists python3 && echo "  Python3: $(python3 --version)"
    command_exists pip3 && echo "  pip3: $(pip3 --version)"
    if command_exists uv; then
        echo "  uv: $(uv --version)"
    elif [[ -f "$HOME/.cargo/bin/uv" ]]; then
        echo "  uv: $($HOME/.cargo/bin/uv --version)"
    fi
    command_exists conda && echo "  Conda: $(conda --version)"
}

main "$@"
