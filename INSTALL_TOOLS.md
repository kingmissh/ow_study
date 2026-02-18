# Windows 开发工具安装指南

## 方法 1：使用安装脚本（推荐）

在 PowerShell 中运行：

```powershell
# 以管理员身份运行 PowerShell
# 右键点击 PowerShell 图标 → "以管理员身份运行"

cd E:\code\openclaw-study
.\install-tools.ps1
```

---

## 方法 2：手动安装 GitHub CLI

### 选项 A：直接下载安装包（最简单）

1. 访问 https://github.com/cli/cli/releases/latest
2. 下载 `gh_*_windows_amd64.msi`
3. 双击运行安装程序
4. 重新打开 PowerShell
5. 验证安装：`gh --version`

### 选项 B：使用 Scoop（推荐给开发者）

```powershell
# 1. 安装 Scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# 2. 安装 GitHub CLI
scoop install gh

# 3. 验证安装
gh --version
```

### 选项 C：使用 Chocolatey

```powershell
# 1. 以管理员身份运行 PowerShell

# 2. 安装 Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 3. 安装 GitHub CLI
choco install gh -y

# 4. 验证安装
gh --version
```

---

## 方法 3：使用 winget（Windows 11 自带）

```powershell
# 检查 winget 是否可用
winget --version

# 如果可用，直接安装
winget install --id GitHub.cli

# 验证安装
gh --version
```

---

## 安装 Git（如果还没有）

### 选项 A：官方安装包

1. 访问 https://git-scm.com/download/win
2. 下载并安装
3. 使用默认选项即可

### 选项 B：使用包管理器

```powershell
# Scoop
scoop install git

# Chocolatey
choco install git -y

# winget
winget install --id Git.Git
```

---

## 验证安装

```powershell
# 检查 Git
git --version

# 检查 GitHub CLI
gh --version
```

预期输出：
```
git version 2.43.0.windows.1
gh version 2.40.1 (2024-01-15)
```

---

## 配置 GitHub CLI

### 1. 登录 GitHub

```powershell
gh auth login
```

按照提示操作：
1. 选择 `GitHub.com`
2. 选择 `HTTPS`
3. 选择 `Login with a web browser`
4. 复制显示的代码
5. 按回车打开浏览器
6. 粘贴代码并授权

### 2. 验证登录

```powershell
gh auth status
```

---

## 快速上传到 GitHub

安装完成后，在 `openclaw-study` 目录运行：

```powershell
# 方式 1：使用 GitHub CLI（推荐）
gh repo create openclaw-study --public --source=. --remote=origin --push

# 方式 2：使用脚本
.\push-to-github.ps1 YOUR_GITHUB_USERNAME
```

---

## 常见问题

### Q1: winget 命令不存在

**解决方案**：
- 更新 Windows 到最新版本
- 或从 Microsoft Store 安装 "应用安装程序"
- 或使用其他安装方法

### Q2: 执行策略错误

**错误信息**：
```
无法加载文件，因为在此系统上禁止运行脚本
```

**解决方案**：
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q3: GitHub CLI 安装后命令不可用

**解决方案**：
1. 重新打开 PowerShell
2. 或重启电脑
3. 检查环境变量 PATH

### Q4: 网络连接问题

**解决方案**：
- 检查防火墙设置
- 使用代理（如果需要）
- 或手动下载安装包

---

## 推荐的开发工具

安装完 Git 和 GitHub CLI 后，还推荐安装：

### VS Code
```powershell
# Scoop
scoop install vscode

# Chocolatey
choco install vscode -y

# winget
winget install --id Microsoft.VisualStudioCode
```

### Node.js（如果需要开发 OpenClaw）
```powershell
# Scoop
scoop install nodejs

# Chocolatey
choco install nodejs -y

# winget
winget install --id OpenJS.NodeJS
```

---

## 下一步

安装完成后：
1. ✅ 验证所有工具已安装
2. ✅ 登录 GitHub CLI
3. ✅ 上传项目到 GitHub
4. 🎉 开始学习 OpenClaw！

---

需要帮助？查看：
- [GitHub CLI 文档](https://cli.github.com/manual/)
- [Git 文档](https://git-scm.com/doc)
- [UPLOAD_GUIDE.md](./UPLOAD_GUIDE.md)
