#!/bin/bash

# Git 清理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/safety.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "Git 仓库清理"

# 查找所有 Git 仓库
find_git_repos() {
    local search_dir="${1:-$HOME}"
    find "$search_dir" -type d -name ".git" 2>/dev/null | while read -r git_dir; do
        echo "$(dirname "$git_dir")"
    done
}

# 清理孤立分支
cleanup_orphan_branches() {
    if ! command_exists git; then
        print_error "Git 未安装"
        return 1
    fi
    
    print_info "查找 Git 仓库中的孤立分支..."
    
    local repo_count=0
    local cleaned_count=0
    
    find_git_repos | while read -r repo; do
        if [[ -d "$repo/.git" ]]; then
            repo_count=$((repo_count + 1))
            print_info "检查仓库: $repo"
            
            cd "$repo" || continue
            
            # 获取已合并的远程分支
            git fetch --prune 2>/dev/null
            
            # 查找本地孤立分支（已合并到主分支的）
            local orphan_branches=$(git branch --merged main 2>/dev/null | grep -v "main\|master\|\*" | sed 's/^[[:space:]]*//')
            local orphan_branches_master=$(git branch --merged master 2>/dev/null | grep -v "main\|master\|\*" | sed 's/^[[:space:]]*//')
            
            if [[ -n "$orphan_branches" ]] || [[ -n "$orphan_branches_master" ]]; then
                echo "发现孤立分支："
                [[ -n "$orphan_branches" ]] && echo "$orphan_branches"
                [[ -n "$orphan_branches_master" ]] && echo "$orphan_branches_master"
                
                if confirm "是否删除这些孤立分支？"; then
                    echo "$orphan_branches" "$orphan_branches_master" | xargs -n1 git branch -d 2>/dev/null
                    cleaned_count=$((cleaned_count + 1))
                    log_cleanup "git" "孤立分支: $repo"
                fi
            fi
        fi
    done
    
    print_info "检查了 $repo_count 个仓库"
}

# 清理过期的引用
cleanup_stale_refs() {
    if ! command_exists git; then
        return 1
    fi
    
    print_info "清理过期的 Git 引用..."
    
    find_git_repos | while read -r repo; do
        if [[ -d "$repo/.git" ]]; then
            cd "$repo" || continue
            
            # 清理过期的远程引用
            git remote prune origin 2>/dev/null
            
            # 清理过期的 reflog
            if confirm "是否清理 $repo 的过期 reflog？"; then
                git reflog expire --expire=90.days.ago --expire-unreachable=now --all 2>/dev/null
                git gc --prune=now 2>/dev/null
                log_cleanup "git" "过期引用: $repo"
            fi
        fi
    done
}

# 查找大文件
find_large_files() {
    local repo="${1:-.}"
    
    if [[ ! -d "$repo/.git" ]]; then
        return 1
    fi
    
    cd "$repo" || return 1
    
    print_info "查找仓库中的大文件..."
    
    # 查找历史中的大文件（>10MB）
    git rev-list --objects --all | \
        git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
        awk '/^blob/ {print substr($0,6)}' | \
        sort --numeric-sort --key=2 | \
        tail -20 | \
        while read -r hash size path; do
            if [[ $size -gt 10485760 ]]; then  # 10MB
                local size_mb=$((size / 1048576))
                echo "  $path ($size_mb MB)"
            fi
        done
}

# 清理大文件历史（需要 git-filter-repo 或 BFG）
cleanup_large_files() {
    if ! command_exists git; then
        return 1
    fi
    
    print_warning "清理大文件历史是一个危险操作，可能会重写 Git 历史"
    print_warning "建议先备份仓库"
    
    if ! confirm "是否继续？"; then
        return 0
    fi
    
    print_info "查找包含大文件的仓库..."
    
    find_git_repos | while read -r repo; do
        if [[ -d "$repo/.git" ]]; then
            local large_files=$(find_large_files "$repo")
            
            if [[ -n "$large_files" ]]; then
                print_warning "仓库 $repo 包含大文件："
                echo "$large_files"
                print_info "请手动使用 git-filter-repo 或 BFG 清理"
            fi
        fi
    done
}

# 主函数
main() {
    if ! command_exists git; then
        print_error "Git 未安装"
        exit 1
    fi
    
    cleanup_orphan_branches
    cleanup_stale_refs
    
    echo ""
    if confirm "是否查找包含大文件的仓库？"; then
        cleanup_large_files
    fi
    
    echo ""
    print_title "Git 清理完成"
}

main "$@"
