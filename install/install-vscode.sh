#!/bin/bash

# VSCode 安装脚本
# 支持 macOS 和 Linux，可安装或升级到最新稳定版

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "VSCode 安装/升级"

# 获取 VSCode 最新稳定版版本号
get_latest_vscode_version() {
    local version=""
    
    # 尝试从 GitHub API 获取最新版本
    if command_exists curl; then
        version=$(curl -sL https://api.github.com/repos/microsoft/vscode/releases/latest 2>/dev/null | grep -oE '"tag_name": "[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | cut -d'"' -f4)
    fi
    
    # 如果 API 失败，尝试从官网获取
    if [[ -z "$version" ]]; then
        version=$(curl -sL https://code.visualstudio.com/updates 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    
    [[ -z "$version" ]] && echo "" && return 1
    normalize_version "$version"
}

# 获取当前已安装的 VSCode 版本
get_vscode_version() {
    if command_exists code; then
        local version
        version=$(code --version 2>/dev/null | head -n 1)
        [[ -n "$version" ]] && normalize_version "$version"
    else
        echo ""
    fi
}

# 在 macOS 上安装 VSCode
install_vscode_macos() {
    print_info "在 macOS 上安装 VSCode..."
    
    if command_exists brew; then
        run_command "brew install --cask visual-studio-code" "通过 Homebrew 安装 VSCode"
    else
        print_warning "未检测到 Homebrew，尝试手动下载安装..."
        
        local download_url="https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
        local temp_dir=$(mktemp -d)
        local zip_file="$temp_dir/VSCode-darwin-universal.zip"
        
        run_command "curl -L -o '$zip_file' '$download_url'" "下载 VSCode"
        
        if [[ -f "$zip_file" ]]; then
            run_command "unzip -q '$zip_file' -d '$temp_dir'" "解压 VSCode"
            
            # 移动到 Applications
            if [[ -d "$temp_dir/Visual Studio Code.app" ]]; then
                run_command "sudo mv '$temp_dir/Visual Studio Code.app' /Applications/" "安装到 Applications"
                print_success "VSCode 已安装到 /Applications"
            fi
            
            # 清理临时文件
            rm -rf "$temp_dir"
            
            # 添加到 PATH
            if [[ ! -f "/usr/local/bin/code" ]]; then
                run_command "sudo ln -sf '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' /usr/local/bin/code" "创建 code 命令链接"
            fi
        else
            print_error "下载失败"
            return 1
        fi
    fi
    
    return 0
}

# 在 Linux 上安装 VSCode
install_vscode_linux() {
    print_info "在 Linux 上安装 VSCode..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            # Debian/Ubuntu
            print_info "使用 apt 安装..."
            run_command "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg" "导入 Microsoft GPG 密钥"
            run_command "sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/" "安装 GPG 密钥"
            run_command "echo 'deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list" "添加 VSCode 仓库"
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y code" "安装 VSCode"
            rm -f /tmp/packages.microsoft.gpg
            ;;
        yum)
            # CentOS/RHEL
            print_info "使用 yum 安装..."
            run_command "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc" "导入 Microsoft GPG 密钥"
            run_command "echo -e '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/vscode.repo" "添加 VSCode 仓库"
            run_command "sudo yum check-update" "检查更新"
            run_command "sudo yum install -y code" "安装 VSCode"
            ;;
        dnf)
            # Fedora
            print_info "使用 dnf 安装..."
            run_command "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc" "导入 Microsoft GPG 密钥"
            run_command "echo -e '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/vscode.repo" "添加 VSCode 仓库"
            run_command "sudo dnf check-update" "检查更新"
            run_command "sudo dnf install -y code" "安装 VSCode"
            ;;
        *)
            print_warning "不支持的包管理器，尝试手动下载安装..."
            
            # 检测架构
            local arch="x64"
            case $(uname -m) in
                aarch64) arch="arm64" ;;
                armv7l) arch="armhf" ;;
            esac
            
            local download_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-${arch}"
            local temp_dir=$(mktemp -d)
            local deb_file="$temp_dir/vscode.deb"
            
            run_command "curl -L -o '$deb_file' '$download_url'" "下载 VSCode"
            
            if [[ -f "$deb_file" ]]; then
                run_command "sudo dpkg -i '$deb_file' || sudo apt-get install -f -y" "安装 VSCode"
                rm -rf "$temp_dir"
            else
                print_error "下载失败"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# 升级 VSCode
upgrade_vscode() {
    print_info "升级 VSCode..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            run_command "brew upgrade --cask visual-studio-code" "升级 VSCode"
        else
            print_warning "未使用 Homebrew 安装，请手动下载最新版本"
            install_vscode_macos
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        case "$PACKAGE_MANAGER" in
            apt)
                run_command "sudo apt-get update && sudo apt-get install --only-upgrade -y code" "升级 VSCode"
                ;;
            yum)
                run_command "sudo yum update -y code" "升级 VSCode"
                ;;
            dnf)
                run_command "sudo dnf update -y code" "升级 VSCode"
                ;;
            *)
                print_warning "无法自动升级，请手动重新安装"
                return 1
                ;;
        esac
    fi
    
    return 0
}

# 安装或升级 VSCode
install_or_upgrade_vscode() {
    local current_ver
    local latest_ver
    
    current_ver=$(get_vscode_version)
    latest_ver=$(get_latest_vscode_version)
    
    if [[ -n "$current_ver" ]]; then
        print_info "当前 VSCode 版本: $current_ver"
        
        if [[ -n "$latest_ver" ]]; then
            print_info "最新稳定版: $latest_ver"
            
            if compare_versions "$current_ver" "$latest_ver"; then
                if confirm_upgrade "VSCode" "$current_ver" "$latest_ver"; then
                    upgrade_vscode
                else
                    print_info "跳过升级"
                    return 0
                fi
            else
                print_success "VSCode 已是最新版本"
                return 0
            fi
        else
            print_warning "无法获取最新版本信息"
            if confirm "是否尝试升级 VSCode？"; then
                upgrade_vscode
            else
                return 0
            fi
        fi
    else
        print_info "未检测到 VSCode，开始安装..."
        
        if [[ "$OS_TYPE" == "macos" ]]; then
            install_vscode_macos
        elif [[ "$OS_TYPE" == "linux" ]]; then
            install_vscode_linux
        else
            print_error "不支持的操作系统: $OS_TYPE"
            return 1
        fi
    fi
    
    # 验证安装
    if command_exists code; then
        local new_ver
        new_ver=$(get_vscode_version)
        print_success "VSCode 安装/升级成功！版本: $new_ver"
        log_installation "VSCode" "$new_ver"
        
        # 显示常用命令
        echo ""
        print_info "常用命令："
        echo "  code              # 启动 VSCode"
        echo "  code .            # 在当前目录启动 VSCode"
        echo "  code file.txt     # 打开指定文件"
        
        return 0
    else
        print_error "VSCode 安装/升级可能失败，请检查"
        return 1
    fi
}

# 安装常用扩展（可选）
install_common_extensions() {
    if ! command_exists code; then
        print_error "请先安装 VSCode"
        return 1
    fi
    
    echo ""
    if confirm "是否安装常用扩展？"; then
        print_info "安装常用扩展..."
        
        local extensions=(
            "ms-vscode.vscode-json"
            "ms-python.python"
            "dbaeumer.vscode-eslint"
            "esbenp.prettier-vscode"
            "eamodio.gitlens"
            "formulahendry.auto-close-tag"
            "formulahendry.auto-rename-tag"
            "ms-vscode.vscode-typescript-next"
            "bradlc.vscode-tailwindcss"
        )
        
        for ext in "${extensions[@]}"; do
            run_command "code --install-extension '$ext' --force" "安装扩展: $ext"
        done
        
        print_success "常用扩展安装完成"
    fi
}

# 主函数
main() {
    install_or_upgrade_vscode
    
    if command_exists code; then
        install_common_extensions
    fi
    
    echo ""
    print_title "VSCode 安装/升级完成"
}

main "$@"
