# 开发工具脚本仓库

一个功能完整的 Shell 脚本工具集合，包含开发工具安装、系统清理和问题排查三大类功能，支持 macOS 和 Linux 系统。

## 功能特性

- 🚀 **开发工具安装**: 一键安装 Node.js、Python、Docker、Git、数据库、VSCode、Chrome 等开发工具
- 🧹 **系统清理**: 安全清理系统缓存、包管理器缓存、Docker 资源、临时文件等
- 🔍 **问题排查**: 网络、磁盘、进程、权限、服务、依赖、性能等全方位排查
- 🛡️ **安全保护**: 白名单保护、大文件确认、操作日志记录
- 🎨 **用户友好**: 彩色输出、进度条、交互式菜单
- 🔧 **跨平台**: 自动检测操作系统并适配（macOS/Linux）

## 快速开始

### 使用主菜单

```bash
# 运行主菜单
./main.sh

# 或使用绝对路径
bash /path/to/myScripts/main.sh
```

### 直接运行脚本

```bash
# 安装工具
./main.sh install-node
./main.sh install-python
./main.sh install-docker
./main.sh install-vscode
./main.sh install-chrome

# 清理操作
./main.sh cleanup-system
./main.sh cleanup-packages
./main.sh cleanup-docker

# 问题排查
./main.sh check-network
./main.sh check-disk
./main.sh check-process

# 杂项工具
./main.sh fix-node           # 修复 Node.js/npm
./main.sh reinstall-npm-packages  # 重装全局 npm 包
./main.sh upgrade-ollama     # 升级 Ollama
```

### 查看帮助

```bash
./main.sh help
```

## 目录结构

```
myScripts/
├── main.sh                    # 主菜单脚本
├── README.md                  # 本文档
├── config/                    # 配置文件目录
│   ├── whitelist.conf        # 清理白名单配置
│   └── paths.conf            # 自定义路径配置
├── lib/                       # 公共函数库
│   ├── common.sh             # 通用函数
│   ├── safety.sh             # 安全检查函数
│   └── logger.sh             # 日志记录函数
├── install/                   # 安装脚本
│   ├── install-node.sh       # Node.js 安装
│   ├── install-python.sh     # Python 安装
│   ├── install-docker.sh     # Docker 安装
│   ├── install-git.sh        # Git 安装
│   ├── install-db.sh         # 数据库安装
│   ├── install-vscode.sh     # VSCode 安装
│   ├── install-chrome.sh     # Chrome 浏览器安装
│   └── install-all.sh        # 一键安装所有
├── cleanup/                   # 清理脚本
│   ├── cleanup-system.sh     # 系统缓存清理
│   ├── cleanup-packages.sh    # 包管理器缓存清理
│   ├── cleanup-docker.sh      # Docker 清理
│   ├── cleanup-git.sh         # Git 清理
│   ├── cleanup-temp.sh        # 临时文件清理
│   ├── cleanup-logs.sh        # 日志文件清理
│   ├── cleanup-node.sh        # node_modules 清理
│   ├── cleanup-python.sh      # Python 缓存清理
│   └── cleanup-all.sh         # 一键清理所有
├── troubleshoot/              # 排查脚本
│   ├── check-network.sh       # 网络排查
│   ├── check-disk.sh          # 磁盘分析
│   ├── check-process.sh       # 进程管理
│   ├── check-permission.sh    # 权限排查
│   ├── check-services.sh      # 服务状态检查
│   ├── check-dependencies.sh  # 依赖冲突排查
│   └── check-performance.sh    # 性能分析
├── examples/                  # 使用示例
│   └── usage-examples.md      # 常见场景说明
├── crawler/                   # 数据爬取工具
│   ├── nuscenes_lidarseg_crawler.py  # nuScenes LiDAR分割数据爬取
│   ├── requirements.txt       # Python依赖
│   └── README.md              # 使用说明
└── etc/                       # 杂项工具脚本
    ├── fix-node-npm.sh        # Node.js/npm 修复脚本
    ├── reinstall-global-npm-packages.sh  # 重装全局 npm 包
    ├── upgrade-ollama.sh      # Ollama 升级脚本
    ├── fix-lsd-icons.sh       # LSD图标修复脚本
    └── lsd-icons-fix.md       # 修复说明文档
```

## 安装脚本说明

### Node.js 及相关工具

安装 Node.js、npm、yarn、pnpm：

```bash
./install/install-node.sh
```

### Python 及相关工具

安装 Python3、pip、uv、conda：

```bash
./install/install-python.sh
```

**注意**: uv 是一个快速的 Python 包管理器，推荐用于现代 Python 项目。

### Docker 及 Docker Compose

安装 Docker 和 Docker Compose：

```bash
./install/install-docker.sh
```

### Git 及相关工具

安装 Git、GitHub CLI、Git LFS：

```bash
./install/install-git.sh
```

### 数据库工具

安装 MySQL、PostgreSQL、MongoDB、Redis：

```bash
./install/install-db.sh
```

### VSCode 编辑器

安装或升级到最新稳定版 VSCode：

```bash
./install/install-vscode.sh
```

**特性**：
- 自动检测已安装版本并提示升级
- 支持 macOS (Homebrew/手动安装) 和 Linux (apt/yum/dnf)
- 可选安装常用扩展（Python、ESLint、Prettier、GitLens 等）

### Chrome 浏览器

安装或升级到最新稳定版 Google Chrome：

```bash
./install/install-chrome.sh
```

**特性**：
- 自动检测已安装版本并提示升级
- 支持 macOS (Homebrew/手动下载) 和 Linux (apt/yum/dnf)
- 自动配置官方软件源，支持后续系统更新

### 一键安装所有工具

```bash
./install/install-all.sh
```

## 清理脚本说明

所有清理脚本都包含安全保护机制：

- ✅ 白名单保护（重要目录不会被删除）
- ✅ 大文件删除前二次确认（>100MB）
- ✅ 操作日志记录

### 系统缓存清理

清理 DNS 缓存、系统日志、系统缓存：

```bash
./cleanup/cleanup-system.sh
```

### 包管理器缓存清理

清理 npm、yarn、pnpm、pip、uv、conda、brew、apt 等缓存：

```bash
./cleanup/cleanup-packages.sh
```

### Docker 资源清理

清理未使用的镜像、容器、卷、网络：

```bash
./cleanup/cleanup-docker.sh
```

### Git 仓库清理

清理孤立分支、过期引用、大文件历史：

```bash
./cleanup/cleanup-git.sh
```

### 临时文件清理

清理 Downloads、Desktop、临时目录中的旧文件：

```bash
./cleanup/cleanup-temp.sh
```

### 日志文件清理

清理系统日志、应用日志：

```bash
./cleanup/cleanup-logs.sh
```

### node_modules 清理

清理所有 node_modules 目录：

```bash
./cleanup/cleanup-node.sh
```

### Python 缓存清理

清理 `__pycache__`、`.pyc` 等 Python 缓存文件：

```bash
./cleanup/cleanup-python.sh
```

### 一键清理所有

执行所有清理操作（需确认）：

```bash
./cleanup/cleanup-all.sh
```

## 排查脚本说明

### 网络问题排查

检查网络连接、DNS 解析、端口占用：

```bash
./troubleshoot/check-network.sh
```

### 磁盘空间分析

分析磁盘使用情况、查找大文件、显示目录大小：

```bash
./troubleshoot/check-disk.sh
```

### 进程管理

查看资源占用、查找进程、终止进程：

```bash
./troubleshoot/check-process.sh
```

### 权限问题排查

检查文件权限、查找权限异常、修复权限：

```bash
./troubleshoot/check-permission.sh
```

### 服务状态检查

检查 Docker、数据库等服务状态：

```bash
./troubleshoot/check-services.sh
```

### 依赖冲突排查

检查 npm、pip 依赖冲突：

```bash
./troubleshoot/check-dependencies.sh
```

### 性能分析

分析系统性能、CPU、内存使用情况：

```bash
./troubleshoot/check-performance.sh
```

## 数据爬取工具

### nuScenes LiDAR 分割数据爬取

用于爬取 nuScenes 数据集的 LiDAR 分割数据：

```bash
# 安装依赖
cd crawler
pip install -r requirements.txt

# 运行爬取脚本
python nuscenes_lidarseg_crawler.py
```

详细用法参考 `crawler/README.md`。

## 杂项工具脚本

### 修复 Node.js/npm

当 node 或 npm 命令找不到或损坏时，自动检测并修复：

```bash
./etc/fix-node-npm.sh           # 自动检测并修复
./etc/fix-node-npm.sh --path    # 仅修复 PATH，不安装
./etc/fix-node-npm.sh --force   # 强制重新安装 Node.js
```

**特性**：
- 自动检测 nvm、fnm、volta、Homebrew、系统路径中的 Node.js
- 支持修复 PATH 配置或强制重装
- 支持 macOS 和 Linux

### 重装全局 npm 包

批量重装常用全局 npm 包：

```bash
./etc/reinstall-global-npm-packages.sh
```

### 升级 Ollama

检查并升级 Ollama 到最新版本：

```bash
./etc/upgrade-ollama.sh
```

**特性**：
- 自动检测当前版本并与 GitHub 最新版本比较
- 升级前自动备份当前版本
- 支持 macOS 和 Linux（amd64/arm64）

### LSD 图标修复

修复 LSD (LSD: Dream Emulator) 游戏图标问题：

```bash
./etc/fix-lsd-icons.sh
```

详细说明参考 `etc/lsd-icons-fix.md`。

## 配置文件

### 白名单配置 (config/whitelist.conf)

定义清理脚本不会删除的受保护路径：

```conf
# 用户重要目录
~/Documents
~/Desktop
~/Pictures

# 开发项目目录
~/Projects
~/Workspace
```

### 路径配置 (config/paths.conf)

自定义清理路径和阈值：

```conf
# 大文件阈值（字节）
LARGE_FILE_THRESHOLD=104857600

# 临时文件目录
TEMP_DIRS=(
    "$HOME/Downloads"
    "$HOME/Desktop"
)
```

## 安全注意事项

1. **白名单保护**: 重要目录已默认加入白名单，不会被清理
2. **大文件确认**: 删除大于 100MB 的文件前会二次确认
3. **操作日志**: 所有删除操作都会记录到 `logs/operations.log`
4. **预览模式**: 清理前会显示将要删除的内容预览

## 系统要求

- macOS 10.14+ 或 Linux (Ubuntu/Debian/CentOS)
- Bash 4.0+
- 部分功能需要管理员权限（sudo）

## 常见问题

### Q: 如何添加自定义路径到白名单？

A: 编辑 `config/whitelist.conf` 文件，添加要保护的路径。

### Q: 清理脚本会删除我的重要文件吗？

A: 不会。重要目录已在白名单中，且大文件删除前会确认。

### Q: 如何查看操作日志？

A: 运行主菜单选择 "查看操作日志"，或直接查看 `logs/operations.log`。

### Q: 脚本支持 Windows 吗？

A: 目前仅支持 macOS 和 Linux。Windows 用户可以使用 WSL 或 Git Bash。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 更新日志

### v1.2.4
- ✨ 新增 VSCode 一键安装脚本，支持安装和升级到最新稳定版
- ✨ 新增 Chrome 浏览器一键安装脚本，支持安装和升级
- ✨ 支持 macOS (Homebrew/手动下载) 和 Linux (apt/yum/dnf) 多平台安装
- ✨ 可选安装常用扩展（Python、ESLint、Prettier、GitLens 等）
- 📝 更新主菜单，添加 VSCode 和 Chrome 安装选项
- 📝 更新 README，补充 crawler/ 和 etc/ 目录说明

### v1.2.1
- 🔧 优化 Node.js 安装脚本，默认安装最新版本（而非 LTS）
- ✨ 新增 n 版本管理工具自动安装
- 📝 支持使用 n 工具安装指定版本（n latest、n lts、n <version>）

### v1.2.0
- ✨ 新增 Podman 安装支持（Docker 的无守护进程替代方案）
- ✨ 支持自动配置 docker alias 指向 podman
- 🔧 优化 Docker 安装脚本，支持选择 Docker 或 Podman
- 📝 更新主菜单，添加 Podman 安装选项
- 🔧 优化一键安装脚本，支持选择容器运行时

### v1.0.0
- 初始版本
- 支持开发工具安装
- 支持系统清理
- 支持问题排查
