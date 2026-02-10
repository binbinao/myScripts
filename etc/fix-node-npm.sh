#!/bin/bash

# 强制修复 Node.js 和 npm
# 场景：node/npm 未找到（command not found）或损坏
# 处理：检测 nvm/fnm/volta/brew 等环境并修复 PATH，或强制重装 Node.js
# 支持：macOS、Linux（apt / yum / dnf）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/common.sh"

# 是否仅修复 PATH（不重装）
FIX_PATH_ONLY=false
# 是否强制重装（跳过检测直接重装）
FORCE_REINSTALL=false

usage() {
    echo "用法: $0 [选项]"
    echo "  无参数    检测并修复 node/npm（修复 PATH 或按需重装）"
    echo "  --path    仅尝试修复 PATH，不安装/重装"
    echo "  --force   强制重新安装 Node.js 和 npm"
}

for arg in "$@"; do
    case "$arg" in
        --path)  FIX_PATH_ONLY=true ;;
        --force) FORCE_REINSTALL=true ;;
        -h|--help) usage; exit 0 ;;
    esac
done

# 检测 node 是否在 PATH 且可用
node_available() {
    command -v node &>/dev/null && node --version &>/dev/null
}

# 检测 npm 是否在 PATH 且可用
npm_available() {
    command -v npm &>/dev/null && npm --version &>/dev/null
}

# 尝试加载 nvm 并检测 node（必须在当前 shell 执行以使 PATH 生效）
try_nvm() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$nvm_dir/nvm.sh" ]]; then
        source "$nvm_dir/nvm.sh" 2>/dev/null || true
        if node_available; then
            return 0
        fi
    fi
    return 1
}

# 尝试 fnm
try_fnm() {
    if [[ -n "$FNM_DIR" && -x "$FNM_DIR/fnm" ]]; then
        eval "$("$FNM_DIR/fnm" env)" 2>/dev/null || true
        if node_available; then
            return 0
        fi
    fi
    if [[ -f "$HOME/.local/share/fnm/fnm" ]]; then
        eval "$("$HOME/.local/share/fnm/fnm" env)" 2>/dev/null || true
        if node_available; then
            return 0
        fi
    fi
    return 1
}

# 尝试 volta
try_volta() {
    if [[ -n "$VOLTA_HOME" && -x "$VOLTA_HOME/bin/volta" ]]; then
        export PATH="$VOLTA_HOME/bin:$PATH"
        if node_available; then
            return 0
        fi
    fi
    if [[ -x "$HOME/.volta/bin/volta" ]]; then
        export PATH="$HOME/.volta/bin:$PATH"
        if node_available; then
            return 0
        fi
    fi
    return 1
}

# 尝试 Homebrew 的 node（macOS）
try_brew_node() {
    if [[ "$OS_TYPE" != "macos" ]]; then
        return 1
    fi
    if command -v brew &>/dev/null; then
        local brew_prefix
        brew_prefix=$(brew --prefix 2>/dev/null)
        if [[ -n "$brew_prefix" && -x "$brew_prefix/bin/node" ]]; then
            export PATH="$brew_prefix/bin:$PATH"
            if node_available; then
                return 0
            fi
        fi
    fi
    return 1
}

# 尝试系统 /usr/local 等常见路径
try_system_paths() {
    local dirs=("/usr/local/bin" "/opt/homebrew/bin")
    for dir in "${dirs[@]}"; do
        if [[ -x "$dir/node" ]]; then
            export PATH="$dir:$PATH"
            if node_available; then
                return 0
            fi
        fi
    done
    return 1
}

# 修复 PATH：尝试所有已知来源（在当前 shell 中执行以便 PATH 生效）
fix_path() {
    print_info "正在检测 Node 环境（nvm / fnm / volta / Homebrew / 系统路径）..."
    local found=""
    if try_nvm; then
        found="nvm"
    elif try_fnm; then
        found="fnm"
    elif try_volta; then
        found="volta"
    elif try_brew_node; then
        found="brew"
    elif try_system_paths; then
        found="system"
    fi
    if [[ -n "$found" ]]; then
        print_success "已找到 Node 环境: $found"
        if node_available; then
            print_success "node: $(node --version)"
        fi
        if npm_available; then
            print_success "npm: $(npm --version)"
        else
            print_warning "npm 仍不可用，建议执行一次强制重装: $0 --force"
        fi
        return 0
    fi
    return 1
}

# 写入 shell 配置，使 PATH 在新建终端中生效
write_shell_rc() {
    local rc_file=""
    if [[ -n "$ZSH_VERSION" || -f "$HOME/.zshrc" ]]; then
        rc_file="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        rc_file="$HOME/.bashrc"
    else
        rc_file="$HOME/.profile"
    fi

    local line=""
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        line="export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\""
    elif command -v brew &>/dev/null && [[ "$OS_TYPE" == "macos" ]]; then
        line="export PATH=\"\$(brew --prefix)/bin:\$PATH\""
    fi

    if [[ -n "$line" && -n "$rc_file" ]]; then
        if grep -q "NVM_DIR\|brew --prefix.*bin" "$rc_file" 2>/dev/null; then
            print_info "检测到 $rc_file 中已有相关配置，请确保新建终端或执行: source $rc_file"
        else
            if confirm "是否将 PATH 配置追加到 $rc_file？"; then
                echo "" >> "$rc_file"
                echo "# Node/npm PATH (added by fix-node-npm.sh)" >> "$rc_file"
                echo "$line" >> "$rc_file"
                print_success "已写入 $rc_file，请执行: source $rc_file"
            fi
        fi
    fi
}

# 强制安装/重装 Node.js（与 install-node.sh 逻辑一致）
install_node_force() {
    print_info "开始安装/重装 Node.js（含 npm）..."

    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command -v brew &>/dev/null; then
            print_error "请先安装 Homebrew: https://brew.sh"
            return 1
        fi
        # 若已安装则先卸载再装，确保干净
        if brew list node &>/dev/null; then
            print_info "检测到已通过 Homebrew 安装 Node，执行 reinstall..."
            run_command "brew reinstall node" "重装 Node.js" || run_command "brew install node" "安装 Node.js"
        else
            run_command "brew install node" "安装 Node.js"
        fi
        export PATH="$(brew --prefix)/bin:$PATH"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        check_sudo
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "curl -fsSL https://deb.nodesource.com/setup_latest.x | sudo -E bash -" "配置 NodeSource 仓库"
            run_command "sudo apt-get install -y nodejs" "安装 Node.js"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "curl -fsSL https://rpm.nodesource.com/setup_latest.x | sudo bash -" "配置 NodeSource 仓库"
            run_command "sudo $PACKAGE_MANAGER install -y nodejs" "安装 Node.js"
        else
            print_error "不支持的 Linux 包管理器（需 apt / yum / dnf）"
            return 1
        fi
    else
        print_error "不支持的操作系统: $OS_TYPE"
        return 1
    fi

    if node_available; then
        print_success "Node.js: $(node --version)"
    else
        print_error "安装后仍无法找到 node，请检查 PATH 或手动 source 当前 shell 配置"
        return 1
    fi

    if npm_available; then
        print_success "npm: $(npm --version)"
        if confirm "是否将 npm 升级到最新版？"; then
            run_command "npm install -g npm@latest" "升级 npm" || true
        fi
    else
        print_warning "npm 未找到，尝试: npm install -g npm@latest（需先确保 node 在 PATH）"
    fi
    return 0
}

main() {
    print_title "强制修复 Node.js 和 npm"

    if [[ "$OS_TYPE" != "macos" && "$OS_TYPE" != "linux" ]]; then
        print_error "当前系统不支持: $OS_TYPE"
        exit 1
    fi

    if [[ "$FORCE_REINSTALL" == true ]]; then
        install_node_force
        write_shell_rc
        exit $?
    fi

    if node_available && npm_available; then
        print_success "node 与 npm 已可用，无需修复"
        echo "  node: $(node --version)"
        echo "  npm:  $(npm --version)"
        exit 0
    fi

    if [[ "$FIX_PATH_ONLY" == true ]]; then
        if fix_path; then
            write_shell_rc
            exit 0
        fi
        print_warning "仅 PATH 修复未找到 Node，请尝试: $0 --force"
        exit 1
    fi

    # 先尝试修复 PATH
    if fix_path; then
        write_shell_rc
        print_success "修复完成，请在新终端或执行 source ~/.zshrc（或 ~/.bashrc）后使用 node/npm"
        exit 0
    fi

    # 未找到则安装
    print_warning "未在 PATH 或常见位置找到 Node.js"
    if confirm "是否现在安装/重装 Node.js 和 npm？"; then
        install_node_force
        write_shell_rc
    else
        print_info "已取消。可稍后执行: $0 --force"
        exit 0
    fi
}

main "$@"
