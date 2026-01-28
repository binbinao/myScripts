#!/bin/bash

# 日志函数库 - 操作日志记录功能
# 提供时间戳、操作类型、文件路径等日志记录

# 获取脚本所在目录
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 如果 PROJECT_ROOT 未设置，则从 LIB_DIR 推导
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$LIB_DIR/.." && pwd)}"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/operations.log"

# 加载公共函数库
source "$LIB_DIR/common.sh"

# 初始化日志目录
init_logger() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi
    
    # 如果日志文件不存在，创建并添加头部
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "# 操作日志文件" > "$LOG_FILE"
        echo "# 格式: [时间戳] [操作类型] [详细信息]" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
    fi
}

# 获取时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 记录日志
log_operation() {
    local operation_type="$1"
    shift
    local message="$*"
    local timestamp=$(get_timestamp)
    
    init_logger
    
    echo "[$timestamp] [$operation_type] $message" >> "$LOG_FILE"
}

# 记录删除操作
log_deletion() {
    local target="$1"
    local size="${2:-unknown}"
    log_operation "DELETE" "删除: $target (大小: $size)"
}

# 记录安装操作
log_installation() {
    local tool="$1"
    local version="${2:-unknown}"
    log_operation "INSTALL" "安装: $tool (版本: $version)"
}

# 记录清理操作
log_cleanup() {
    local category="$1"
    local details="$2"
    log_operation "CLEANUP" "清理 [$category]: $details"
}

# 记录排查操作
log_troubleshoot() {
    local category="$1"
    local details="$2"
    log_operation "TROUBLESHOOT" "排查 [$category]: $details"
}

# 记录错误
log_error() {
    local message="$1"
    log_operation "ERROR" "$message"
}

# 记录警告
log_warning() {
    local message="$1"
    log_operation "WARNING" "$message"
}

# 查看日志
view_log() {
    local lines="${1:-50}"
    
    if [[ -f "$LOG_FILE" ]]; then
        print_title "最近 $lines 条日志记录"
        tail -n "$lines" "$LOG_FILE"
    else
        print_warning "日志文件不存在"
    fi
}

# 清空日志
clear_log() {
    if [[ -f "$LOG_FILE" ]]; then
        if confirm "确认清空日志文件？"; then
            > "$LOG_FILE"
            print_success "日志已清空"
        fi
    else
        print_warning "日志文件不存在"
    fi
}

# 搜索日志
search_log() {
    local keyword="$1"
    
    if [[ -z "$keyword" ]]; then
        print_error "请提供搜索关键词"
        return 1
    fi
    
    if [[ -f "$LOG_FILE" ]]; then
        print_title "搜索日志: $keyword"
        grep -i "$keyword" "$LOG_FILE" || print_info "未找到匹配的日志"
    else
        print_warning "日志文件不存在"
    fi
}

# 初始化（自动执行）
init_logger
