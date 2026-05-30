#!/bin/bash

# Python 缓存清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Python 缓存清理"

# 加载路径配置
load_paths_config() {
    local config_file="$SCRIPT_DIR/../config/paths.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# 查找 Python 缓存文件
find_python_cache() {
    local search_dir="${1:-$HOME}"
    local patterns=(
        "__pycache__"
        "*.pyc"
        "*.pyo"
        "*.pyd"
        ".Python"
    )

    if [[ ${#PYTHON_CACHE_PATTERNS[@]} -gt 0 ]]; then
        patterns=("${PYTHON_CACHE_PATTERNS[@]}")
    fi
    
    local cache_files=()
    
    for pattern in "${patterns[@]}"; do
        if [[ "$pattern" == "__pycache__" ]]; then
            # 查找目录
            while IFS= read -r dir; do
                if [[ -n "$dir" ]] && is_safe_to_delete "$dir"; then
                    cache_files+=("$dir")
                fi
            done < <(find "$search_dir" -type d -name "$pattern" 2>/dev/null)
        else
            # 查找文件
            while IFS= read -r file; do
                if [[ -n "$file" ]] && is_safe_to_delete "$file"; then
                    cache_files+=("$file")
                fi
            done < <(find "$search_dir" -type f -name "$pattern" 2>/dev/null)
        fi
    done
    
    printf '%s\n' "${cache_files[@]}"
}

# 清理 Python 缓存
cleanup_python_cache() {
    load_paths_config
    
    print_info "查找 Python 缓存文件..."
    
    local search_dir="${1:-$HOME}"
    local cache_items=$(find_python_cache "$search_dir")
    
    if [[ -z "$cache_items" ]]; then
        print_info "未找到 Python 缓存文件"
        return 0
    fi
    
    local total_size=0
    local item_count=0
    declare -a items_array
    
    # 收集信息
    while IFS= read -r item; do
        if [[ -n "$item" ]]; then
            items_array+=("$item")
            local size_bytes
            size_bytes=$(get_path_size_bytes "$item")
            total_size=$((total_size + size_bytes))
            item_count=$((item_count + 1))
        fi
    done <<< "$cache_items"
    
    if [[ $item_count -eq 0 ]]; then
        print_info "没有可清理的 Python 缓存"
        return 0
    fi
    
    print_info "找到 $item_count 个 Python 缓存项"
    print_info "总大小: $(format_bytes $total_size)"
    echo ""
    
    # 显示一些示例
    print_info "示例缓存项："
    for item in "${items_array[@]}"; do
        if [[ -d "$item" ]]; then
            local size=$(get_dir_size "$item")
            echo "  目录: $item ($size)"
        else
            local size=$(get_file_size "$item")
            echo "  文件: $item ($size)"
        fi
    done | head -10
    
    if [[ $item_count -gt 10 ]]; then
        print_info "... 还有 $((item_count - 10)) 个项目"
    fi
    
    echo ""
    if ! confirm "是否删除所有找到的 Python 缓存？"; then
        return 0
    fi
    
    # 逐个删除
    local deleted=0
    local failed=0
    
    for item in "${items_array[@]}"; do
        if [[ -d "$item" ]]; then
            if safe_delete_dir "$item" "false"; then
                deleted=$((deleted + 1))
                log_cleanup "python" "Python 缓存目录: $item"
            else
                failed=$((failed + 1))
            fi
        else
            if safe_delete_file "$item" "false"; then
                deleted=$((deleted + 1))
                log_cleanup "python" "Python 缓存文件: $item"
            else
                failed=$((failed + 1))
            fi
        fi
    done
    
    echo ""
    print_info "清理完成: 成功 $deleted 个, 失败 $failed 个"
    print_info "释放空间: $(format_bytes $total_size)"
}

# 使用 Python 工具清理
cleanup_with_python() {
    local search_dir="${1:-$HOME}"

    if ! command_exists python3; then
        print_info "Python3 未安装，跳过"
        return 0
    fi

    print_info "清理遗留的空 __pycache__ 目录..."

    if python3 - "$search_dir" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).expanduser()
removed = 0

for path in root.rglob("__pycache__"):
    if path.is_dir():
        try:
            next(path.iterdir())
        except StopIteration:
            path.rmdir()
            removed += 1
        except OSError:
            pass

print(removed)
PY
    then
        log_cleanup "python" "清理空 __pycache__ 目录: $search_dir"
    else
        print_warning "清理空 __pycache__ 目录时出现问题"
    fi
}

# 主函数
main() {
    local search_dir="${1:-$HOME}"

    cleanup_python_cache "$search_dir"
    cleanup_with_python "$search_dir"
    
    echo ""
    print_title "Python 缓存清理完成"
}

main "$@"
