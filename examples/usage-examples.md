# 使用示例和常见场景

本文档提供脚本仓库的常见使用场景和示例。

## 场景 1: 新系统环境配置

### 场景描述
在新安装的 macOS 或 Linux 系统上配置开发环境。

### 操作步骤

```bash
# 1. 运行主菜单
./main.sh

# 2. 选择 "一键安装所有工具" (选项 6)
# 或直接运行
./install/install-all.sh

# 3. 安装完成后验证
node --version
python3 --version
docker --version
git --version
```

## 场景 2: 清理系统释放空间

### 场景描述
系统磁盘空间不足，需要清理各种缓存和临时文件。

### 操作步骤

```bash
# 1. 先查看磁盘使用情况
./troubleshoot/check-disk.sh

# 2. 清理包管理器缓存（通常占用较多空间）
./cleanup/cleanup-packages.sh

# 3. 清理 Docker 资源
./cleanup/cleanup-docker.sh

# 4. 清理 node_modules（如果是 Node.js 开发者）
./cleanup/cleanup-node.sh

# 5. 清理临时文件
./cleanup/cleanup-temp.sh

# 6. 一键清理所有（谨慎使用）
./cleanup/cleanup-all.sh
```

## 场景 3: 排查端口占用问题

### 场景描述
启动服务时提示端口被占用，需要找出占用端口的进程。

### 操作步骤

```bash
# 方法 1: 使用网络排查脚本
./troubleshoot/check-network.sh
# 选择查看端口占用情况

# 方法 2: 使用进程管理脚本
./troubleshoot/check-process.sh
# 选择 "查看端口对应的进程" (选项 4)
# 输入端口号，如 3000

# 方法 3: 直接使用主菜单
./main.sh check-network
```

## 场景 4: 排查服务启动问题

### 场景描述
Docker 或数据库服务无法启动，需要检查服务状态。

### 操作步骤

```bash
# 1. 检查服务状态
./troubleshoot/check-services.sh

# 2. 如果服务未运行，尝试启动
# 在服务状态检查菜单中选择 "启动服务" (选项 1)
# 输入服务名称，如 docker、mysql

# 3. 检查服务日志
# Docker: docker logs <container_name>
# MySQL: sudo journalctl -u mysql
# PostgreSQL: sudo journalctl -u postgresql
```

## 场景 5: 排查依赖冲突

### 场景描述
npm 或 pip 安装包时出现依赖冲突错误。

### 操作步骤

```bash
# 1. 检查依赖树
./troubleshoot/check-dependencies.sh

# 2. 查看具体的冲突信息
cd /path/to/your/project
npm ls --depth=0

# 3. 修复依赖（删除 node_modules 重新安装）
# 在依赖排查脚本中选择 "修复 npm 依赖" (选项 1)
```

## 场景 6: 清理 Git 仓库

### 场景描述
Git 仓库中有很多孤立分支和过期引用，需要清理。

### 操作步骤

```bash
# 1. 清理孤立分支
./cleanup/cleanup-git.sh
# 脚本会自动查找所有 Git 仓库并清理

# 2. 手动清理特定仓库
cd /path/to/your/repo
git branch --merged main | grep -v "main\|master" | xargs git branch -d
git remote prune origin
```

## 场景 7: 性能问题排查

### 场景描述
系统运行缓慢，需要找出占用资源的进程。

### 操作步骤

```bash
# 1. 查看系统负载和资源使用
./troubleshoot/check-performance.sh

# 2. 查看占用 CPU 最高的进程
./troubleshoot/check-process.sh
# 脚本会自动显示 CPU 和内存占用最高的进程

# 3. 监控特定进程
./troubleshoot/check-process.sh
# 选择 "查看进程详细信息" (选项 2)
# 输入进程 ID，然后选择 "监控特定进程"
```

## 场景 8: 权限问题排查

### 场景描述
文件或目录权限异常，导致无法访问或修改。

### 操作步骤

```bash
# 1. 检查文件权限
./troubleshoot/check-permission.sh
# 选择 "检查文件/目录权限" (选项 1)
# 输入文件或目录路径

# 2. 查找权限异常的文件
./troubleshoot/check-permission.sh
# 选择 "查找权限异常的文件" (选项 2)

# 3. 修复权限
./troubleshoot/check-permission.sh
# 选择 "修复权限问题" (选项 3)
# 输入文件或目录路径
```

## 场景 9: 定期维护

### 场景描述
定期清理系统，保持系统整洁。

### 操作步骤

```bash
# 创建定期维护脚本
cat > ~/weekly-cleanup.sh << 'EOF'
#!/bin/bash
cd /path/to/myScripts

# 清理包管理器缓存
./cleanup/cleanup-packages.sh

# 清理 Docker 资源
./cleanup/cleanup-docker.sh

# 清理临时文件
./cleanup/cleanup-temp.sh

# 清理日志文件
./cleanup/cleanup-logs.sh
EOF

chmod +x ~/weekly-cleanup.sh

# 添加到 crontab（每周执行一次）
# crontab -e
# 添加: 0 2 * * 0 /path/to/weekly-cleanup.sh
```

## 场景 10: 批量安装开发工具

### 场景描述
需要在多台机器上安装相同的开发工具。

### 操作步骤

```bash
# 1. 创建安装脚本
cat > install-dev-tools.sh << 'EOF'
#!/bin/bash
cd /path/to/myScripts

./install/install-node.sh
./install/install-python.sh
./install/install-docker.sh
./install/install-git.sh
EOF

chmod +x install-dev-tools.sh

# 2. 在每台机器上运行
./install-dev-tools.sh
```

## 场景 11: 查找大文件释放空间

### 场景描述
磁盘空间不足，需要找出占用空间的大文件。

### 操作步骤

```bash
# 1. 查看磁盘使用情况
./troubleshoot/check-disk.sh

# 2. 查找大文件（>100MB）
./troubleshoot/check-disk.sh
# 选择 "查找大文件" 选项

# 3. 查看最大的目录
./troubleshoot/check-disk.sh
# 脚本会自动显示最大的目录

# 4. 分析特定目录
./troubleshoot/check-disk.sh
# 选择 "分析特定目录" 选项
# 输入目录路径，如 ~/Downloads
```

## 场景 12: 查看操作历史

### 场景描述
需要查看之前执行了哪些清理或安装操作。

### 操作步骤

```bash
# 方法 1: 使用主菜单
./main.sh
# 选择 "查看操作日志" (选项 23)

# 方法 2: 直接查看日志文件
cat logs/operations.log

# 方法 3: 搜索特定操作
grep "DELETE" logs/operations.log
grep "INSTALL" logs/operations.log
```

## 最佳实践

1. **定期清理**: 建议每周或每月执行一次清理操作
2. **备份重要数据**: 清理前确保重要数据已备份
3. **查看预览**: 清理脚本会显示将要删除的内容，请仔细确认
4. **使用白名单**: 将重要目录添加到白名单配置中
5. **查看日志**: 定期查看操作日志，了解系统变化

## 注意事项

- ⚠️ 清理操作不可逆，请谨慎使用
- ⚠️ 大文件删除前会二次确认，请仔细阅读提示
- ⚠️ 系统关键目录已默认保护，不会被删除
- ⚠️ 某些操作需要管理员权限，会提示输入密码

## 获取帮助

如果遇到问题，可以：

1. 查看 README.md 文档
2. 运行 `./main.sh help` 查看帮助
3. 查看日志文件了解错误信息
4. 提交 Issue 反馈问题
