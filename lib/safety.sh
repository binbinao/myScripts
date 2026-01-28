#!/bin/bash

# 安全函数库 - 安全检查和安全删除功能
# 提供白名单验证、大文件确认、安全检查等功能

# 获取脚本所在目录
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 如果 PROJECT_ROOT 未设置，则从 LIB_DIR 推导
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$LIB_DIR/.." && pwd)}"
WHITELIST_FILE="$PROJECT_ROOT/config/whitelist.conf"

# 大文件阈值（默认100MB）
LARGE_FILE_THRESHOLD=${LARGE_FILE_THRESHOLD:-104857600}  # 100MB in bytes

# 加载公共函数库
source "$LIB_DIR/common.sh"

# 加载白名单配置
load_whitelist() {
    local whitelist=()
    
    if [[ -f "$WHITELIST_FILE" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # 跳过注释和空行
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # 展开路径（支持 ~）
            local expanded_path="${line/#\~/$HOME}"
            whitelist+=("$expanded_path")
        done < "$WHITELIST_FILE"
    else
        # 默认白名单
        whitelist=(
            "$HOME"
            "/"
            "/bin"
            "/sbin"
            "/usr"
            "/usr/bin"
            "/usr/sbin"
            "/usr/local"
            "/etc"
            "/var"
            "/opt"
            "/System"
            "/Library"
            "/Applications"
            "/private"
        )
    fi
    
    printf '%s\n' "${whitelist[@]}"
}

# 检查路径是否在白名单中
is_whitelisted() {
    local target_path="$1"
    local whitelist
    readarray -t whitelist < <(load_whitelist)
    
    # 规范化路径
    target_path=$(realpath "$target_path" 2>/dev/null || echo "$target_path")
    
    for whitelist_path in "${whitelist[@]}"; do
        whitelist_path=$(realpath "$whitelist_path" 2>/dev/null || echo "$whitelist_path")
        
        # 检查目标路径是否在白名单路径下
        if [[ "$target_path" == "$whitelist_path"* ]] || [[ "$target_path" == "$whitelist_path" ]]; then
            return 0
        fi
    done
    
    return 1
}

# 检查路径是否安全（不在白名单中）
is_safe_to_delete() {
    local target_path="$1"
    
    if is_whitelisted "$target_path"; then
        print_error "路径受保护（在白名单中）: $target_path"
        return 1
    fi
    
    # 检查是否是系统关键目录
    local critical_dirs=(
        "/"
        "/bin"
        "/sbin"
        "/usr"
        "/etc"
        "/var"
        "/opt"
        "/System"
        "/Library"
    )
    
    for critical_dir in "${critical_dirs[@]}"; do
        if [[ "$target_path" == "$critical_dir" ]] || [[ "$target_path" == "$critical_dir/" ]]; then
            print_error "禁止删除系统关键目录: $target_path"
            return 1
        fi
    done
    
    return 0
}

# 检查文件大小
get_file_size_bytes() {
    local file="$1"
    if [[ "$OS_TYPE" == "macos" ]]; then
        stat -f%z "$file" 2>/dev/null || echo "0"
    else
        stat -c%s "$file" 2>/dev/null || echo "0"
    fi
}

# 检查是否为大文件
is_large_file() {
    local file="$1"
    local size
    
    if [[ -f "$file" ]]; then
        size=$(get_file_size_bytes "$file")
        if [[ $size -gt $LARGE_FILE_THRESHOLD ]]; then
            return 0
        fi
    fi
    
    return 1
}

# 大文件删除确认
confirm_large_file_deletion() {
    local file="$1"
    local size
    
    if is_large_file "$file"; then
        size=$(get_file_size "$file")
        print_warning "检测到大文件: $file"
        print_warning "文件大小: $size"
        
        if ! confirm "确认删除此大文件？"; then
            return 1
        fi
    fi
    
    return 0
}

# 安全删除文件
safe_delete_file() {
    local file="$1"
    local force="${2:-false}"
    
    # 检查文件是否存在
    if [[ ! -e "$file" ]]; then
        print_warning "文件不存在: $file"
        return 1
    fi
    
    # 安全检查
    if [[ "$force" != "true" ]]; then
        if ! is_safe_to_delete "$file"; then
            return 1
        fi
    fi
    
    # 大文件确认
    if [[ -f "$file" ]]; then
        if ! confirm_large_file_deletion "$file"; then
            return 1
        fi
    fi
    
    # 执行删除
    if rm -rf "$file" 2>/dev/null; then
        print_success "已删除: $file"
        return 0
    else
        print_error "删除失败: $file"
        return 1
    fi
}

# 安全删除目录
safe_delete_dir() {
    local dir="$1"
    local force="${2:-false}"
    
    # 检查目录是否存在
    if [[ ! -d "$dir" ]]; then
        print_warning "目录不存在: $dir"
        return 1
    fi
    
    # 安全检查
    if [[ "$force" != "true" ]]; then
        if ! is_safe_to_delete "$dir"; then
            return 1
        fi
    fi
    
    # 显示目录大小
    local dir_size=$(get_dir_size "$dir")
    print_info "目录大小: $dir_size"
    
    # 确认删除
    if ! confirm "确认删除目录 $dir？"; then
        return 1
    fi
    
    # 执行删除
    if rm -rf "$dir" 2>/dev/null; then
        print_success "已删除目录: $dir"
        return 0
    else
        print_error "删除目录失败: $dir"
        return 1
    fi
}

# 预览将要删除的文件（dry-run模式）
preview_deletion() {
    local target="$1"
    local count=0
    local total_size=0
    
    print_title "预览删除内容: $target"
    
    if [[ -f "$target" ]]; then
        local size=$(get_file_size_bytes "$target")
        local size_human=$(format_bytes "$size")
        echo "文件: $target ($size_human)"
        count=1
        total_size=$size
    elif [[ -d "$target" ]]; then
        while IFS= read -r -d '' file; do
            if is_safe_to_delete "$file"; then
                local size=$(get_file_size_bytes "$file")
                local size_human=$(format_bytes "$size")
                echo "  $file ($size_human)"
                count=$((count + 1))
                total_size=$((total_size + size))
            fi
        done < <(find "$target" -type f -print0 2>/dev/null)
    fi
    
    echo ""
    print_info "总计: $count 个文件"
    print_info "总大小: $(format_bytes $total_size)"
    
    return 0
}

# 批量安全删除
safe_delete_batch() {
    local files=("$@")
    local deleted=0
    local failed=0
    
    for file in "${files[@]}"; do
        if safe_delete_file "$file"; then
            deleted=$((deleted + 1))
        else
            failed=$((failed + 1))
        fi
    done
    
    echo ""
    print_info "删除完成: 成功 $deleted 个, 失败 $failed 个"
    
    return $failed
}
