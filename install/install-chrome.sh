#!/bin/bash

# Chrome 浏览器安装脚本
# 支持 macOS 和 Linux，可安装或升级到最新稳定版

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Chrome 浏览器安装/升级"

# 获取 Chrome 最新稳定版版本号
get_latest_chrome_version() {
    local version=""
    
    # 从 Google Chrome 版本说明页面获取
    if command_exists curl; then
        version=$(curl -sL https://chromereleases.googleblog.com/ 2>/dev/null | grep -oE 'Stable Channel Update for Desktop[^0-9]*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    fi
    
    # 备用方案：使用固定版本检查 URL
    if [[ -z "$version" ]]; then
        version=$(curl -sL "https://versionhistory.googleapis.com/v1/chrome/platforms/all/channels/stable/versions" 2>/dev/null | grep -oE '"version": "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | cut -d'"' -f4)
    fi
    
    [[ -z "$version" ]] && echo "" && return 1
    normalize_version "$version"
}

# 获取当前已安装的 Chrome 版本
get_chrome_version() {
    local chrome_path=""
    
    # 检测 Chrome 安装路径
    if [[ "$OS_TYPE" == "macos" ]]; then
        chrome_path="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else
        chrome_path=$(which google-chrome 2>/dev/null || which google-chrome-stable 2>/dev/null || echo "")
    fi
    
    if [[ -n "$chrome_path" && -f "$chrome_path" ]]; then
        local version
        version=$("$chrome_path" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        [[ -n "$version" ]] && normalize_version "$version"
    else
        echo ""
    fi
}

# 在 macOS 上安装 Chrome
install_chrome_macos() {
    print_info "在 macOS 上安装 Chrome..."
    
    if command_exists brew; then
        run_command "brew install --cask google-chrome" "通过 Homebrew 安装 Chrome"
    else
        print_warning "未检测到 Homebrew，尝试手动下载安装..."
        
        local download_url="https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
        local temp_dir=$(mktemp -d)
        local dmg_file="$temp_dir/googlechrome.dmg"
        
        run_command "curl -L -o '$dmg_file' '$download_url'" "下载 Chrome"
        
        if [[ -f "$dmg_file" ]]; then
            run_command "hdiutil attach '$dmg_file' -nobrowse -quiet" "挂载 DMG"
            
            # 复制到 Applications
            if [[ -d "/Volumes/Google Chrome/Google Chrome.app" ]]; then
                run_command "sudo cp -R '/Volumes/Google Chrome/Google Chrome.app' /Applications/" "安装到 Applications"
                run_command "hdiutil detach '/Volumes/Google Chrome' -quiet" "卸载 DMG"
                print_success "Chrome 已安装到 /Applications"
            fi
            
            # 清理临时文件
            rm -rf "$temp_dir"
        else
            print_error "下载失败"
            return 1
        fi
    fi
    
    return 0
}

# 在 Linux 上安装 Chrome
install_chrome_linux() {
    print_info "在 Linux 上安装 Chrome..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            # Debian/Ubuntu
            print_info "使用 apt 安装..."
            run_command "wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -" "导入 Google GPG 密钥"
            run_command "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list" "添加 Chrome 仓库"
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y google-chrome-stable" "安装 Chrome"
            ;;
        yum)
            # CentOS/RHEL
            print_info "使用 yum 安装..."
            run_command "sudo rpm --import https://dl-ssl.google.com/linux/linux_signing_key.pub" "导入 Google GPG 密钥"
            run_command "echo -e '[google-chrome]\nname=google-chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo tee /etc/yum.repos.d/google-chrome.repo" "添加 Chrome 仓库"
            run_command "sudo yum check-update" "检查更新"
            run_command "sudo yum install -y google-chrome-stable" "安装 Chrome"
            ;;
        dnf)
            # Fedora
            print_info "使用 dnf 安装..."
            run_command "sudo rpm --import https://dl-ssl.google.com/linux/linux_signing_key.pub" "导入 Google GPG 密钥"
            run_command "echo -e '[google-chrome]\nname=google-chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo tee /etc/yum.repos.d/google-chrome.repo" "添加 Chrome 仓库"
            run_command "sudo dnf check-update" "检查更新"
            run_command "sudo dnf install -y google-chrome-stable" "安装 Chrome"
            ;;
        *)
            print_warning "不支持的包管理器，尝试手动下载安装..."
            
            # 检测架构
            local arch="amd64"
            case $(uname -m) in
                aarch64) arch="arm64" ;;
                armv7l) arch="armhf" ;;
            esac
            
            local download_url="https://dl.google.com/linux/direct/google-chrome-stable_current_${arch}.deb"
            local temp_dir=$(mktemp -d)
            local deb_file="$temp_dir/google-chrome-stable.deb"
            
            run_command "curl -L -o '$deb_file' '$download_url'" "下载 Chrome"
            
            if [[ -f "$deb_file" ]]; then
                run_command "sudo dpkg -i '$deb_file' || sudo apt-get install -f -y" "安装 Chrome"
                rm -rf "$temp_dir"
            else
                print_error "下载失败"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# 升级 Chrome
upgrade_chrome() {
    print_info "升级 Chrome..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            run_command "brew upgrade --cask google-chrome" "升级 Chrome"
        else
            print_warning "未使用 Homebrew 安装，请手动下载最新版本"
            install_chrome_macos
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        case "$PACKAGE_MANAGER" in
            apt)
                run_command "sudo apt-get update && sudo apt-get install --only-upgrade -y google-chrome-stable" "升级 Chrome"
                ;;
            yum)
                run_command "sudo yum update -y google-chrome-stable" "升级 Chrome"
                ;;
            dnf)
                run_command "sudo dnf update -y google-chrome-stable" "升级 Chrome"
                ;;
            *)
                print_warning "无法自动升级，请手动重新安装"
                return 1
                ;;
        esac
    fi
    
    return 0
}

# 安装或升级 Chrome
install_or_upgrade_chrome() {
    local current_ver
    local latest_ver
    
    current_ver=$(get_chrome_version)
    latest_ver=$(get_latest_chrome_version)
    
    if [[ -n "$current_ver" ]]; then
        print_info "当前 Chrome 版本: $current_ver"
        
        if [[ -n "$latest_ver" ]]; then
            print_info "最新稳定版: $latest_ver"
            
            if compare_versions "$current_ver" "$latest_ver"; then
                if confirm_upgrade "Chrome" "$current_ver" "$latest_ver"; then
                    upgrade_chrome
                else
                    print_info "跳过升级"
                    return 0
                fi
            else
                print_success "Chrome 已是最新版本"
                return 0
            fi
        else
            print_warning "无法获取最新版本信息"
            if confirm "是否尝试升级 Chrome？"; then
                upgrade_chrome
            else
                return 0
            fi
        fi
    else
        print_info "未检测到 Chrome，开始安装..."
        
        if [[ "$OS_TYPE" == "macos" ]]; then
            install_chrome_macos
        elif [[ "$OS_TYPE" == "linux" ]]; then
            install_chrome_linux
        else
            print_error "不支持的操作系统: $OS_TYPE"
            return 1
        fi
    fi
    
    # 验证安装
    local new_ver
    new_ver=$(get_chrome_version)
    if [[ -n "$new_ver" ]]; then
        print_success "Chrome 安装/升级成功！版本: $new_ver"
        log_installation "Chrome" "$new_ver"
        return 0
    else
        print_error "Chrome 安装/升级可能失败，请检查"
        return 1
    fi
}

# 主函数
main() {
    install_or_upgrade_chrome
    
    echo ""
    print_title "Chrome 安装/升级完成"
}

main "$@"
