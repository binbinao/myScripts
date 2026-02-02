# lsd 图标显示为方框的修复说明

## 问题现象

使用 `brew install lsd` 安装 [lsd](https://github.com/lsd-rs/lsd) 后，在终端执行 `lsd` 时，文件/文件夹前的图标显示为**方框**或乱码，无法正常显示文件类型图标。

## 原因说明

lsd 通过 **Nerd Font** 的专用字形（glyph）来显示图标。若终端使用的字体未包含这些字形，对应字符会显示为方框、问号或空白。

- Nerd Font 是在常见等宽字体基础上合并了 [Nerd Fonts](https://www.nerdfonts.com/) 图标集的字体。
- 本方案采用 **Meslo LG Nerd Font**（与 Oh My Zsh Powerlevel10k 等常用主题兼容良好）。

## 解决步骤概览

1. **安装 Nerd Font**（如 Meslo LG Nerd Font）。
2. **将终端/IDE 的终端字体**设置为该 Nerd Font。
3. **重新打开终端或重载窗口**后，再执行 `lsd` 验证。

---

## 方式一：使用项目脚本（推荐）

在项目根目录执行：

```bash
./etc/fix-lsd-icons.sh
```

脚本会：

- 在 macOS 上通过 Homebrew 安装 `font-meslo-lg-nerd-font`（若未安装）。
- 可选：自动在 Cursor、VS Code 的 `settings.json` 中写入 `terminal.integrated.fontFamily": "MesloLGS NF"`（仅当尚未配置时）。

执行完成后：

- **Cursor**：新建终端（如 `` Ctrl+` ``）或执行「Developer: Reload Window」。
- **VS Code**：同上，新建终端或重载窗口。
- 在新终端中执行 `lsd`，图标应正常显示。

---

## 方式二：手动操作

### 1. 安装 Nerd Font（macOS）

```bash
brew install --cask font-meslo-lg-nerd-font
```

### 2. 配置 Cursor 终端字体

1. 打开 Cursor 设置（JSON）：  
   `~/Library/Application Support/Cursor/User/settings.json`
2. 添加或修改：

```json
"terminal.integrated.fontFamily": "MesloLGS NF",
"terminal.integrated.fontSize": 14
```

（`fontSize` 可按需保留原值。）

### 3. 配置 VS Code 终端字体

1. 打开 VS Code 设置（JSON）：  
   `~/Library/Application Support/Code/User/settings.json`
2. 同样添加或修改：

```json
"terminal.integrated.fontFamily": "MesloLGS NF",
"terminal.integrated.fontSize": 15
```

### 4. 其他终端（iTerm2、系统终端等）

- **iTerm2**：Preferences → Profiles → Text → Font → 选择「MesloLGS NF」。
- **macOS 自带终端**：偏好设置 → 描述文件 → 文本 → 字体 → 选择「MesloLGS NF」。

### 5. 验证

- 关闭并重新打开终端（或在 IDE 中新建终端/重载窗口）。
- 执行：`lsd`
- 应能看到文件夹、文件类型等图标，而不再是方框。

---

## 常见问题

- **脚本已运行但仍显示方框**  
  确认已**新建终端**或**重载窗口**，使新字体配置生效；并确认当前终端使用的字体为「MesloLGS NF」。

- **非 macOS 系统**  
  请在本机用系统包管理器或从 [Nerd Fonts 官网](https://www.nerdfonts.com/font-downloads) 下载安装 Meslo LGS Nerd Font，然后在对应 IDE/终端中把字体设为「MesloLGS NF」。

- **想用其他 Nerd Font**  
  可安装如 `font-fira-code-nerd-font`、`font-jetbrains-mono-nerd-font` 等，并在上述配置中把 `terminal.integrated.fontFamily` 改为对应字体名（如 "FiraCode Nerd Font"）。

---

## 相关文件

- 自动修复脚本：`etc/fix-lsd-icons.sh`
- 本文档：`etc/lsd-icons-fix.md`
