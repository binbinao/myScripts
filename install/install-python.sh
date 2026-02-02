#!/bin/bash

# Python 及相关工具安装脚本
# 支持安装 Python、pip、conda、uv

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Python 及相关工具安装"

# 安装或升级 Python
install_python() {
    if command_exists python3; then
        local current_ver
        current_ver=$(get_current_version "python3" "python3 --version 2>&1")
        if [[ -n "$current_ver" ]]; then
            if confirm "是否通过包管理器升级 Python3？（当前: $current_ver）" "n"; then
                check_sudo
                if [[ "$OS_TYPE" == "macos" ]] && command_exists brew; then
                    run_command "brew upgrade python@3.11 2>/dev/null || brew upgrade python3" "升级 Python3"
                elif [[ "$OS_TYPE" == "linux" ]]; then
                    if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                        run_command "sudo apt-get update" "更新包列表"
                        run_command "sudo apt-get install -y --only-upgrade python3 python3-pip python3-venv 2>/dev/null || true" "升级 Python3"
                    elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                        run_command "sudo $PACKAGE_MANAGER upgrade -y python3 python3-pip" "升级 Python3"
                    fi
                fi
            else
                print_info "Python3 已安装（$current_ver），跳过"
            fi
        else
            print_info "Python3 已安装，跳过"
        fi
        command_exists python3 && log_installation "Python3" "$(python3 --version 2>&1)"
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

# 检查并安装或升级 pip
check_pip() {
    if ! command_exists pip3 && ! python3 -m pip --version &>/dev/null; then
        print_warning "pip3 未安装，尝试安装..."
        if command_exists python3; then
            run_command "python3 -m ensurepip --upgrade" "安装 pip"
        else
            print_error "需要先安装 Python3"
            return 1
        fi
        return 0
    fi
    local current_ver
    current_ver=$(get_current_version "pip3" "pip3 --version 2>/dev/null")
    [[ -z "$current_ver" ]] && current_ver=$(python3 -m pip --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    local latest_ver
    latest_ver=$(curl -sL https://pypi.org/pypi/pip/json 2>/dev/null | grep -oE '"version":"[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | cut -d'"' -f4)
    latest_ver=$(normalize_version "$latest_ver")
    if [[ -n "$latest_ver" ]] && [[ -n "$current_ver" ]] && compare_versions "$current_ver" "$latest_ver"; then
        if confirm_upgrade "pip" "$current_ver" "$latest_ver"; then
            run_command "python3 -m pip install --upgrade pip" "升级 pip"
        fi
    elif [[ -n "$current_ver" ]]; then
        print_info "pip3 已是最新（$current_ver），跳过"
    else
        print_info "pip3 已安装"
    fi
    return 0
}

# 获取 uv 最新版本号
get_latest_uv_version() {
    local raw
    raw=$(curl -sL https://api.github.com/repos/astral-sh/uv/releases/latest 2>/dev/null | grep -oE '"tag_name":"v[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | cut -d'"' -f4)
    [[ -z "$raw" ]] && echo "" && return 1
    normalize_version "$raw"
}

# 安装或升级 uv
install_uv() {
    local uv_cmd="uv"
    command_exists uv || [[ -f "$HOME/.cargo/bin/uv" ]] && uv_cmd="$HOME/.cargo/bin/uv" || true
    if command_exists uv || [[ -f "$HOME/.cargo/bin/uv" ]]; then
        "$uv_cmd" --version &>/dev/null || true
        local current_ver
        current_ver=$("$uv_cmd" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        current_ver=$(normalize_version "$current_ver")
        local latest_ver
        latest_ver=$(get_latest_uv_version)
        if [[ -n "$latest_ver" ]] && compare_versions "$current_ver" "$latest_ver"; then
            if confirm_upgrade "uv" "$current_ver" "$latest_ver"; then
                run_command "curl -LsSf https://astral.sh/uv/install.sh | sh" "升级 uv"
                export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
            fi
        elif [[ -n "$current_ver" ]]; then
            print_info "uv 已是最新（$current_ver），跳过"
        else
            print_info "uv 已安装，跳过"
        fi
        command_exists uv || uv_cmd="$HOME/.cargo/bin/uv"
        $uv_cmd --version &>/dev/null && log_installation "uv" "$($uv_cmd --version 2>/dev/null | head -n 1)"
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

# 安装或升级 conda (Miniconda)
install_conda() {
    if command_exists conda; then
        local current_ver
        current_ver=$(get_current_version "conda" "conda --version 2>&1")
        if [[ -n "$current_ver" ]]; then
            if confirm "是否升级 Conda？（当前: $current_ver）" "n"; then
                run_command "conda update -n base conda -y" "升级 Conda"
            else
                print_info "Conda 已安装（$current_ver），跳过"
            fi
        else
            print_info "Conda 已安装，跳过"
        fi
        command_exists conda && log_installation "Conda" "$(conda --version)"
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
