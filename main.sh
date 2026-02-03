#!/bin/bash

# 主菜单脚本 - 开发工具脚本仓库入口
# 提供交互式菜单和脚本调用功能

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 加载公共函数库
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/safety.sh"

# 显示主菜单
show_main_menu() {
    clear
    print_title "开发工具脚本仓库"
    
    echo -e "${BOLD}操作系统:${NC} $OS_TYPE"
    echo -e "${BOLD}包管理器:${NC} $PACKAGE_MANAGER"
    echo ""
    
    echo -e "${GREEN}=== 安装工具 ===${NC}"
    echo "  1) 安装 Node.js 及相关工具"
    echo "  2) 安装 Python 及相关工具"
    echo "  3) 安装 Docker 及 Docker Compose"
    echo "  4) 安装 Podman（Docker 替代方案）"
    echo "  5) 安装 Git 及相关工具"
    echo "  6) 安装数据库工具"
    echo "  7) 安装 VSCode"
    echo "  8) 安装 Chrome 浏览器"
    echo "  9) 一键安装所有工具"
    echo ""

    echo -e "${YELLOW}=== 清理工具 ===${NC}"
    echo " 10) 清理系统缓存"
    echo " 11) 清理包管理器缓存"
    echo " 12) 清理 Docker 资源"
    echo " 13) 清理 Git 仓库"
    echo " 14) 清理临时文件"
    echo " 15) 清理日志文件"
    echo " 16) 清理 node_modules"
    echo " 17) 清理 Python 缓存"
    echo " 18) 一键清理所有（需确认）"
    echo ""

    echo -e "${CYAN}=== 问题排查 ===${NC}"
    echo " 19) 网络问题排查"
    echo " 20) 磁盘空间分析"
    echo " 21) 进程管理"
    echo " 22) 权限问题排查"
    echo " 23) 服务状态检查"
    echo " 24) 依赖冲突排查"
    echo " 25) 性能分析"
    echo ""

    echo -e "${MAGENTA}=== 其他功能 ===${NC}"
    echo " 26) 查看操作日志"
    echo " 27) 查看使用示例"
    echo "  0) 退出"
    echo ""
}

# 执行安装脚本
run_install_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/install/$script_name"
    
    if [[ -f "$script_path" ]]; then
        bash "$script_path"
    else
        print_error "脚本不存在: $script_path"
    fi
}

# 执行清理脚本
run_cleanup_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/cleanup/$script_name"
    
    if [[ -f "$script_path" ]]; then
        bash "$script_path"
    else
        print_error "脚本不存在: $script_path"
    fi
}

# 执行排查脚本
run_troubleshoot_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/troubleshoot/$script_name"
    
    if [[ -f "$script_path" ]]; then
        bash "$script_path"
    else
        print_error "脚本不存在: $script_path"
    fi
}

# 查看日志
view_logs() {
    view_log 50
    press_any_key
}

# 查看使用示例
view_examples() {
    local examples_file="$SCRIPT_DIR/examples/usage-examples.md"
    
    if [[ -f "$examples_file" ]]; then
        if command_exists less; then
            less "$examples_file"
        else
            cat "$examples_file"
            press_any_key
        fi
    else
        print_warning "使用示例文件不存在"
        press_any_key
    fi
}

# 主循环
main_loop() {
    while true; do
        show_main_menu
        read -p "$(echo -e ${CYAN}请选择操作 [0-27]: ${NC})" choice
        
        case $choice in
            1)
                run_install_script "install-node.sh"
                press_any_key
                ;;
            2)
                run_install_script "install-python.sh"
                press_any_key
                ;;
            3)
                run_install_script "install-docker.sh"
                press_any_key
                ;;
            4)
                run_install_script "install-podman.sh"
                press_any_key
                ;;
            5)
                run_install_script "install-git.sh"
                press_any_key
                ;;
            6)
                run_install_script "install-db.sh"
                press_any_key
                ;;
            7)
                run_install_script "install-vscode.sh"
                press_any_key
                ;;
            8)
                run_install_script "install-chrome.sh"
                press_any_key
                ;;
            9)
                run_install_script "install-all.sh"
                press_any_key
                ;;
            10)
                run_cleanup_script "cleanup-system.sh"
                press_any_key
                ;;
            11)
                run_cleanup_script "cleanup-packages.sh"
                press_any_key
                ;;
            12)
                run_cleanup_script "cleanup-docker.sh"
                press_any_key
                ;;
            13)
                run_cleanup_script "cleanup-git.sh"
                press_any_key
                ;;
            14)
                run_cleanup_script "cleanup-temp.sh"
                press_any_key
                ;;
            15)
                run_cleanup_script "cleanup-logs.sh"
                press_any_key
                ;;
            16)
                run_cleanup_script "cleanup-node.sh"
                press_any_key
                ;;
            17)
                run_cleanup_script "cleanup-python.sh"
                press_any_key
                ;;
            18)
                run_cleanup_script "cleanup-all.sh"
                press_any_key
                ;;
            19)
                run_troubleshoot_script "check-network.sh"
                press_any_key
                ;;
            20)
                run_troubleshoot_script "check-disk.sh"
                press_any_key
                ;;
            21)
                run_troubleshoot_script "check-process.sh"
                press_any_key
                ;;
            22)
                run_troubleshoot_script "check-permission.sh"
                press_any_key
                ;;
            23)
                run_troubleshoot_script "check-services.sh"
                press_any_key
                ;;
            24)
                run_troubleshoot_script "check-dependencies.sh"
                press_any_key
                ;;
            25)
                run_troubleshoot_script "check-performance.sh"
                press_any_key
                ;;
            26)
                view_logs
                ;;
            27)
                view_examples
                ;;
            0)
                print_info "感谢使用！"
                exit 0
                ;;
            *)
                print_error "无效的选择，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 检查是否直接运行脚本（带参数）
if [[ $# -gt 0 ]]; then
    case "$1" in
        install-node|node)
            run_install_script "install-node.sh"
            ;;
        install-python|python)
            run_install_script "install-python.sh"
            ;;
        install-docker|docker)
            run_install_script "install-docker.sh"
            ;;
        install-podman|podman)
            run_install_script "install-podman.sh"
            ;;
        install-git|git)
            run_install_script "install-git.sh"
            ;;
        install-db|db)
            run_install_script "install-db.sh"
            ;;
        install-vscode|vscode)
            run_install_script "install-vscode.sh"
            ;;
        install-chrome|chrome)
            run_install_script "install-chrome.sh"
            ;;
        cleanup-system|clean-system)
            run_cleanup_script "cleanup-system.sh"
            ;;
        cleanup-packages|clean-packages)
            run_cleanup_script "cleanup-packages.sh"
            ;;
        cleanup-docker|clean-docker)
            run_cleanup_script "cleanup-docker.sh"
            ;;
        cleanup-git|clean-git)
            run_cleanup_script "cleanup-git.sh"
            ;;
        cleanup-temp|clean-temp)
            run_cleanup_script "cleanup-temp.sh"
            ;;
        cleanup-logs|clean-logs)
            run_cleanup_script "cleanup-logs.sh"
            ;;
        cleanup-node|clean-node)
            run_cleanup_script "cleanup-node.sh"
            ;;
        cleanup-python|clean-python)
            run_cleanup_script "cleanup-python.sh"
            ;;
        check-network|network)
            run_troubleshoot_script "check-network.sh"
            ;;
        check-disk|disk)
            run_troubleshoot_script "check-disk.sh"
            ;;
        check-process|process)
            run_troubleshoot_script "check-process.sh"
            ;;
        check-permission|permission)
            run_troubleshoot_script "check-permission.sh"
            ;;
        check-services|services)
            run_troubleshoot_script "check-services.sh"
            ;;
        check-dependencies|dependencies)
            run_troubleshoot_script "check-dependencies.sh"
            ;;
        check-performance|performance)
            run_troubleshoot_script "check-performance.sh"
            ;;
        log|logs)
            view_logs
            ;;
        help|--help|-h)
            echo "用法: $0 [命令]"
            echo ""
            echo "命令列表:"
            echo "  安装: install-node, install-python, install-docker, install-podman, install-git, install-db"
            echo "  清理: cleanup-system, cleanup-packages, cleanup-docker, cleanup-git, cleanup-temp, cleanup-logs, cleanup-node, cleanup-python"
            echo "  排查: check-network, check-disk, check-process, check-permission, check-services, check-dependencies, check-performance"
            echo "  其他: log, help"
            echo ""
            echo "不带参数运行将显示交互式菜单"
            ;;
        *)
            print_error "未知命令: $1"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
else
    # 无参数时显示菜单
    main_loop
fi
