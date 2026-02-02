#!/bin/bash

# lsd 图标显示修复脚本
# 问题：brew install lsd 后终端中图标显示为方框
# 原因：lsd 使用 Nerd Font 图标，终端字体未包含对应字形
# 处理：安装 Nerd Font，并可选配置 Cursor/VS Code 终端字体
# 详见：etc/lsd-icons-fix.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/lib/common.sh"

NERD_FONT_NAME="MesloLGS NF"
BREW_FONT_CASK="font-meslo-lg-nerd-font"

# 在 settings.json 中设置终端字体（仅 macOS，仅当尚未设置时）
config_ide_terminal_font() {
    local settings_file="$1"
    local ide_name="$2"
    if [[ ! -f "$settings_file" ]]; then
        print_info "$ide_name 配置文件不存在，跳过: $settings_file"
        return 0
    fi
    if grep -q '"terminal.integrated.fontFamily"' "$settings_file" 2>/dev/null; then
        print_info "$ide_name 已配置终端字体，跳过"
        return 0
    fi
    # 在 "terminal.integrated.fontSize" 前插入 fontFamily 配置（保留原 fontSize 值）
    if sed -i.bak 's/"terminal.integrated.fontSize": \([0-9]*\),/"terminal.integrated.fontFamily": "'"$NERD_FONT_NAME"'",\
    "terminal.integrated.fontSize": \1,/' "$settings_file" 2>/dev/null; then
        rm -f "${settings_file}.bak"
        print_success "已为 $ide_name 设置终端字体: $NERD_FONT_NAME"
    else
        print_warning "无法自动修改 $ide_name 配置，请参考文档手动添加"
        return 1
    fi
    return 0
}

# macOS: 配置 Cursor 与 VS Code 的终端字体
config_macos_ide_fonts() {
    local cursor_settings="$HOME/Library/Application Support/Cursor/User/settings.json"
    local code_settings="$HOME/Library/Application Support/Code/User/settings.json"
    config_ide_terminal_font "$cursor_settings" "Cursor"
    config_ide_terminal_font "$code_settings" "VS Code"
}

main() {
    print_title "lsd 图标显示修复（Nerd Font + 终端字体）"

    if [[ "$OS_TYPE" != "macos" ]]; then
        print_info "当前为 $OS_TYPE，仅安装 Nerd Font；终端字体请在本机 IDE 中手动设置为 $NERD_FONT_NAME"
    fi

    # 1. 安装 Nerd Font
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            exit 1
        fi
        if brew list --cask "$BREW_FONT_CASK" &>/dev/null; then
            print_success "Nerd Font 已安装: $BREW_FONT_CASK"
        else
            run_command "brew install --cask $BREW_FONT_CASK" "安装 Nerd Font（$BREW_FONT_CASK）" || exit 1
        fi
    else
        print_warning "非 macOS 需自行安装 Nerd Font，详见 etc/lsd-icons-fix.md"
    fi

    # 2. 可选：配置 Cursor / VS Code 终端字体（仅 macOS）
    if [[ "$OS_TYPE" == "macos" ]]; then
        if confirm "是否为 Cursor / VS Code 终端自动设置字体？"; then
            config_macos_ide_fonts
        else
            print_info "请手动在 Cursor/VS Code 设置中将终端字体设为: $NERD_FONT_NAME"
        fi
    fi

    echo ""
    print_success "处理完成。若使用 Cursor/VS Code，请新建终端或重载窗口后执行 lsd 查看图标。"
    if command_exists lsd; then
        print_info "验证: 执行 lsd 应看到文件类型图标而非方框"
    else
        print_info "未检测到 lsd，可先执行: brew install lsd"
    fi
}

main "$@"
