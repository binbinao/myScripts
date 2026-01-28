#!/bin/bash

# 数据库工具安装脚本
# 支持安装 MySQL、PostgreSQL、MongoDB、Redis

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

print_title "数据库工具安装"

# 安装 MySQL
install_mysql() {
    if ! confirm "是否安装 MySQL？"; then
        return 0
    fi
    
    if command_exists mysql; then
        print_info "MySQL 已安装: $(mysql --version)"
        return 0
    fi
    
    print_info "开始安装 MySQL..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install mysql" "安装 MySQL"
        run_command "brew services start mysql" "启动 MySQL 服务"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y mysql-server" "安装 MySQL"
            run_command "sudo systemctl start mysql" "启动 MySQL 服务"
            run_command "sudo systemctl enable mysql" "设置 MySQL 开机自启"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "sudo $PACKAGE_MANAGER install -y mysql-server" "安装 MySQL"
            run_command "sudo systemctl start mysqld" "启动 MySQL 服务"
            run_command "sudo systemctl enable mysqld" "设置 MySQL 开机自启"
        fi
    fi
    
    if command_exists mysql; then
        local version=$(mysql --version)
        log_installation "MySQL" "$version"
        print_success "MySQL 安装完成"
        print_warning "请运行 'sudo mysql_secure_installation' 进行安全配置"
        return 0
    else
        return 1
    fi
}

# 安装 PostgreSQL
install_postgresql() {
    if ! confirm "是否安装 PostgreSQL？"; then
        return 0
    fi
    
    if command_exists psql; then
        print_info "PostgreSQL 已安装: $(psql --version)"
        return 0
    fi
    
    print_info "开始安装 PostgreSQL..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install postgresql@15" "安装 PostgreSQL"
        run_command "brew services start postgresql@15" "启动 PostgreSQL 服务"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y postgresql postgresql-contrib" "安装 PostgreSQL"
            run_command "sudo systemctl start postgresql" "启动 PostgreSQL 服务"
            run_command "sudo systemctl enable postgresql" "设置 PostgreSQL 开机自启"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "sudo $PACKAGE_MANAGER install -y postgresql-server postgresql-contrib" "安装 PostgreSQL"
            run_command "sudo postgresql-setup --initdb" "初始化 PostgreSQL"
            run_command "sudo systemctl start postgresql" "启动 PostgreSQL 服务"
            run_command "sudo systemctl enable postgresql" "设置 PostgreSQL 开机自启"
        fi
    fi
    
    if command_exists psql; then
        local version=$(psql --version)
        log_installation "PostgreSQL" "$version"
        print_success "PostgreSQL 安装完成"
        return 0
    else
        return 1
    fi
}

# 安装 MongoDB
install_mongodb() {
    if ! confirm "是否安装 MongoDB？"; then
        return 0
    fi
    
    if command_exists mongod; then
        print_info "MongoDB 已安装: $(mongod --version | head -n 1)"
        return 0
    fi
    
    print_info "开始安装 MongoDB..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew tap mongodb/brew" "添加 MongoDB tap"
        run_command "brew install mongodb-community" "安装 MongoDB"
        run_command "brew services start mongodb-community" "启动 MongoDB 服务"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor" "添加 MongoDB GPG 密钥"
            run_command "echo \"deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse\" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list" "添加 MongoDB 仓库"
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y mongodb-org" "安装 MongoDB"
            run_command "sudo systemctl start mongod" "启动 MongoDB 服务"
            run_command "sudo systemctl enable mongod" "设置 MongoDB 开机自启"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "sudo $PACKAGE_MANAGER install -y mongodb-org" "安装 MongoDB"
            run_command "sudo systemctl start mongod" "启动 MongoDB 服务"
            run_command "sudo systemctl enable mongod" "设置 MongoDB 开机自启"
        fi
    fi
    
    if command_exists mongod; then
        local version=$(mongod --version | head -n 1)
        log_installation "MongoDB" "$version"
        print_success "MongoDB 安装完成"
        return 0
    else
        return 1
    fi
}

# 安装 Redis
install_redis() {
    if ! confirm "是否安装 Redis？"; then
        return 0
    fi
    
    if command_exists redis-server; then
        print_info "Redis 已安装: $(redis-server --version | head -n 1)"
        return 0
    fi
    
    print_info "开始安装 Redis..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists brew; then
            print_error "请先安装 Homebrew"
            return 1
        fi
        run_command "brew install redis" "安装 Redis"
        run_command "brew services start redis" "启动 Redis 服务"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            run_command "sudo apt-get update" "更新包列表"
            run_command "sudo apt-get install -y redis-server" "安装 Redis"
            run_command "sudo systemctl start redis-server" "启动 Redis 服务"
            run_command "sudo systemctl enable redis-server" "设置 Redis 开机自启"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
            run_command "sudo $PACKAGE_MANAGER install -y redis" "安装 Redis"
            run_command "sudo systemctl start redis" "启动 Redis 服务"
            run_command "sudo systemctl enable redis" "设置 Redis 开机自启"
        fi
    fi
    
    if command_exists redis-server; then
        local version=$(redis-server --version | head -n 1)
        log_installation "Redis" "$version"
        print_success "Redis 安装完成"
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    install_mysql
    install_postgresql
    install_mongodb
    install_redis
    
    echo ""
    print_title "安装完成"
    echo "已安装数据库工具："
    command_exists mysql && echo "  MySQL: $(mysql --version)"
    command_exists psql && echo "  PostgreSQL: $(psql --version)"
    command_exists mongod && echo "  MongoDB: $(mongod --version | head -n 1)"
    command_exists redis-server && echo "  Redis: $(redis-server --version | head -n 1)"
}

main "$@"
