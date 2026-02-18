# GitHub 上传指南

## 方式 1：通过 GitHub 网页创建仓库（推荐新手）

### 步骤 1：在 GitHub 创建新仓库

1. 访问 https://github.com
2. 登录你的账号
3. 点击右上角的 "+" 按钮，选择 "New repository"
4. 填写仓库信息：
   - Repository name: `openclaw-study`
   - Description: `OpenClaw 项目系统学习与拆解 - 8周完整学习计划`
   - 选择 Public（公开）或 Private（私有）
   - **不要**勾选 "Initialize this repository with a README"
5. 点击 "Create repository"

### 步骤 2：关联本地仓库并推送

在 `openclaw-study` 目录下执行：

```bash
# 添加远程仓库（替换 YOUR_USERNAME 为你的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/openclaw-study.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

---

## 方式 2：使用 GitHub CLI（推荐熟练用户）

### 安装 GitHub CLI

**Windows**:
```powershell
winget install --id GitHub.cli
```

**macOS**:
```bash
brew install gh
```

**Linux**:
```bash
# Debian/Ubuntu
sudo apt install gh

# Fedora
sudo dnf install gh
```

### 使用 GitHub CLI 创建并推送

```bash
# 登录 GitHub
gh auth login

# 创建仓库并推送
gh repo create openclaw-study --public --source=. --remote=origin --push
```

---

## 方式 3：使用 Git GUI 工具

### GitHub Desktop

1. 下载并安装 [GitHub Desktop](https://desktop.github.com/)
2. 打开 GitHub Desktop
3. File → Add Local Repository
4. 选择 `openclaw-study` 目录
5. 点击 "Publish repository"
6. 填写仓库名称和描述
7. 选择公开或私有
8. 点击 "Publish Repository"

---

## 后续更新

### 添加新内容后推送

```bash
# 查看修改
git status

# 添加所有修改
git add .

# 提交修改
git commit -m "描述你的修改"

# 推送到 GitHub
git push
```

### 常用命令

```bash
# 查看当前状态
git status

# 查看提交历史
git log --oneline

# 查看远程仓库
git remote -v

# 拉取最新代码
git pull

# 创建新分支
git checkout -b feature/new-feature

# 切换分支
git checkout main
```

---

## 推荐的仓库设置

### 添加 Topics（标签）

在 GitHub 仓库页面：
1. 点击右侧的 "⚙️ Settings"
2. 在 "Topics" 部分添加标签：
   - `openclaw`
   - `ai-assistant`
   - `learning-resources`
   - `tutorial`
   - `chinese`

### 启用 GitHub Pages（可选）

如果想要网页版文档：
1. Settings → Pages
2. Source 选择 `main` 分支
3. 保存后会生成网页链接

### 添加 README 徽章

在 README.md 顶部添加：

```markdown
![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/openclaw-study?style=social)
![GitHub forks](https://img.shields.io/github/forks/YOUR_USERNAME/openclaw-study?style=social)
![GitHub license](https://img.shields.io/github/license/YOUR_USERNAME/openclaw-study)
```

---

## 常见问题

### 1. 推送时要求输入用户名密码

GitHub 已不支持密码认证，需要使用 Personal Access Token：

1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. 选择 `repo` 权限
4. 复制生成的 token
5. 推送时使用 token 作为密码

### 2. 推送失败：remote rejected

可能是分支保护规则，尝试：
```bash
git push -f origin main
```

### 3. 文件太大无法推送

Git 默认限制单个文件 100MB，如果有大文件：
- 使用 Git LFS
- 或将大文件添加到 `.gitignore`

---

## 下一步

上传成功后：
1. 在 README.md 中添加仓库链接
2. 分享给其他学习者
3. 持续更新学习内容
4. 欢迎其他人贡献

---

祝你上传顺利！🚀
