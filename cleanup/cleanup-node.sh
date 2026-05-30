#!/bin/bash

# node_modules 清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "node_modules 清理"

# 加载路径配置
load_paths_config() {
    local config_file="$SCRIPT_DIR/../config/paths.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# 查找所有 node_modules 目录
find_node_modules() {
    local search_dir="${1:-$HOME}"
    local depth="${2:--1}"
    
    if [[ $depth -eq -1 ]]; then
        find "$search_dir" -type d -name "node_modules" 2>/dev/null
    else
        find "$search_dir" -maxdepth $depth -type d -name "node_modules" 2>/dev/null
    fi
}

# 清理 node_modules
cleanup_node_modules() {
    load_paths_config

    print_info "查找 node_modules 目录..."
    
    local search_dir="${1:-$HOME}"
    local depth="${NODE_MODULES_DEPTH:--1}"
    local node_modules_dirs=$(find_node_modules "$search_dir" "$depth")
    
    if [[ -z "$node_modules_dirs" ]]; then
        print_info "未找到 node_modules 目录"
        return 0
    fi
    
    local total_size=0
    local dir_count=0
    declare -a dirs_array
    
    # 收集信息
    while IFS= read -r dir; do
        if [[ -n "$dir" ]] && [[ -d "$dir" ]]; then
            # 安全检查
            if ! is_safe_to_delete "$dir"; then
                print_warning "跳过受保护的目录: $dir"
                continue
            fi
            
            dirs_array+=("$dir")
            local size_bytes=$(du -sb "$dir" 2>/dev/null | cut -f1)
            total_size=$((total_size + size_bytes))
            dir_count=$((dir_count + 1))
        fi
    done <<< "$node_modules_dirs"
    
    if [[ $dir_count -eq 0 ]]; then
        print_info "没有可清理的 node_modules 目录"
        return 0
    fi
    
    print_info "找到 $dir_count 个 node_modules 目录"
    print_info "总大小: $(format_bytes $total_size)"
    echo ""
    
    # 显示前10个最大的目录
    print_info "最大的 node_modules 目录："
    for dir in "${dirs_array[@]}"; do
        local size=$(get_dir_size "$dir")
        echo "  $dir ($size)"
    done | head -10
    
    if [[ $dir_count -gt 10 ]]; then
        print_info "... 还有 $((dir_count - 10)) 个目录"
    fi
    
    echo ""
    if ! confirm "是否删除所有找到的 node_modules 目录？"; then
        return 0
    fi
    
    # 逐个删除
    local deleted=0
    local failed=0
    
    for dir in "${dirs_array[@]}"; do
        print_info "删除: $dir"
        if safe_delete_dir "$dir" "false"; then
            deleted=$((deleted + 1))
            log_cleanup "node" "node_modules: $dir"
        else
            failed=$((failed + 1))
        fi
    done
    
    echo ""
    print_info "清理完成: 成功 $deleted 个, 失败 $failed 个"
    print_info "释放空间: $(format_bytes $total_size)"
}

# 按项目清理（交互式选择）
cleanup_by_project() {
    load_paths_config

    print_info "按项目清理 node_modules..."
    
    local search_dir="${1:-$HOME}"
    local projects=$(find "$search_dir" -type f -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | xargs -I {} dirname {})
    
    if [[ -z "$projects" ]]; then
        print_info "未找到包含 package.json 的项目"
        return 0
    fi
    
    local project_count=$(echo "$projects" | wc -l | tr -d ' ')
    print_info "找到 $project_count 个项目"
    
    echo "$projects" | while read -r project; do
        if [[ -n "$project" ]] && [[ -d "$project/node_modules" ]]; then
            local size=$(get_dir_size "$project/node_modules")
            echo "  $project/node_modules ($size)"
            
            if confirm "是否删除 $project/node_modules？"; then
                if safe_delete_dir "$project/node_modules"; then
                    log_cleanup "node" "node_modules: $project/node_modules"
                fi
            fi
        fi
    done
}

# 主函数
main() {
    local mode="${1:-all}"
    
    case "$mode" in
        all)
            cleanup_node_modules
            ;;
        interactive)
            cleanup_by_project
            ;;
        *)
            print_error "未知模式: $mode"
            print_info "用法: $0 [all|interactive]"
            exit 1
            ;;
    esac
    
    echo ""
    print_title "node_modules 清理完成"
}

main "$@"
