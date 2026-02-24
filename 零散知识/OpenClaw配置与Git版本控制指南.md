# OpenClaw 配置与 Git 版本控制指南

## 目录

1. [需求概述](#需求概述)
2. [当前配置](#当前配置)
3. [Git 版本控制设置](#git-版本控制设置)
4. [推送到远程仓库](#推送到远程仓库)
5. [Subtree 方案](#subtree-方案)
6. [Submodule 方案](#submodule-方案)
7. [方案对比与选择建议](#方案对比与选择建议)

---

## 需求概述

用户希望在本地使用 OpenClaw 作为个人 AI 助手，并将整个 `.openclaw` 目录纳入 Git 版本控制。

### 核心需求

- **本地版本控制**：对 `.openclaw` 目录进行 Git 管理
- **配置保留**：保留 gateway、credentials、agents、workspace 等配置
- **未来可推送**：workspace 未来可能需要推送到远程仓库
- **宽松策略**：不需要过度严格地排除文件

### 目录结构

```
.openclaw/
├── agents/          # Agent 配置和会话
├── canvas/          # 画布文件
├── completions/     # Shell 补全脚本
├── credentials/     # 第三方认证凭据
├── cron/            # 定时任务配置
├── devices/         # 配对设备信息
├── identity/        # 设备身份信息
├── logs/            # 日志文件
├── media/           # 媒体文件
├── memory/          # 记忆数据库
├── telegram/        # Telegram 配置
├── workspace/       # Agent 工作空间
└── openclaw.json    # 主配置文件
```

---

## 当前配置

### Gateway 配置

```json
{
  "port": 18789,
  "mode": "local",
  "bind": "lan",
  "auth": {
    "mode": "token",
    "token": "12ff92da17007d66db0521cb5a2dda57f169262facbf76d0"
  },
  "tailscale": {
    "mode": "off"
  },
  "nodes": {
    "denyCommands": [
      "camera.snap",
      "camera.clip",
      "screen.record",
      "calendar.add",
      "contacts.add",
      "reminders.add"
    ]
  }
}
```

### Workspace 核心文件

| 文件 | 用途 |
|------|------|
| `SOUL.md` | Agent 的核心身份定义 |
| `USER.md` | 用户信息与偏好 |
| `AGENTS.md` | Agent 行为规范 |
| `TOOLS.md` | 工具配置与笔记 |
| `HEARTBEAT.md` | 心跳任务清单 |
| `IDENTITY.md` | 身份声明 |

---

## Git 版本控制设置

### 当前状态

已在 `/workspaces/ow1/.openclaw` 初始化 Git，并完成首次提交：

```bash
cd /workspaces/ow1/.openclaw
git log --oneline
# 输出: da6913c Initial commit
```

### .gitignore 配置

```gitignore
# OpenClaw .gitignore - lenient

# Logs and cache
logs/
# memory/

# Media and temp files
# media/
# canvas/

# Credentials (optional - uncomment if you want to exclude credentials)
# credentials/

# System files
.git
```

### 已版本控制的文件

- `openclaw.json` - 主配置
- `agents/` - Agent 配置和会话
- `workspace/` - 工作空间（重要！）
- `credentials/` - 第三方凭据
- `identity/` - 设备身份
- `telegram/` - Telegram 配置
- `cron/` - 定时任务
- `devices/` - 配对设备
- 其他配置文件

### 常用 Git 操作

```bash
# 查看状态
git status

# 查看差异
git diff

# 查看提交历史
git log --oneline

# 添加修改
git add .

# 提交修改
git commit -m "描述内容"

# 查看特定文件的历史
git log --oneline workspace/AGENTS.md
```

---

## 推送到远程仓库

### 方式一：整体推送（推荐当前使用）

将整个 `.openclaw` 作为单一仓库推送：

```bash
# 1. 在 GitHub/GitLab 创建新仓库，得到 URL
# 例如: https://github.com/username/openclaw-config.git

# 2. 添加远程仓库
cd /workspaces/ow1/.openclaw
git remote add origin https://github.com/username/openclaw-config.git

# 3. 推送到远程
git push -u origin main
```

### 方式二：仅推送 workspace

如果只想单独推送 workspace：

```bash
# 1. 创建远程仓库，得到 URL
# 例如: https://github.com/username/openclaw-workspace.git

# 2. 添加远程（使用不同名称避免冲突）
git remote add workspace-origin https://github.com/username/openclaw-workspace.git

# 3. 推送 workspace 目录
git subtree push --prefix=workspace workspace-origin main

# 或使用 filter-branch 分离
git push workspace-origin main
```

---

## Subtree 方案

### 什么是 Subtree

Subtree 允许你将一个仓库作为子目录嵌入另一个仓库，同时保持独立的提交历史。

### 配置步骤

#### 1. 准备远程仓库

先在 GitHub/GitLab 创建 workspace 专属仓库，获得 URL：
`https://github.com/username/openclaw-workspace.git`

#### 2. 添加 Subtree

```bash
cd /workspaces/ow1/.openclaw

# 首次添加（--squash 压缩历史）
git subtree add --prefix=workspace \
  https://github.com/username/openclaw-workspace.git \
  main --squash
```

#### 3. 推送更新

当 workspace 有修改时：

```bash
# 推送到远程
git subtree push --prefix=workspace \
  https://github.com/username/openclaw-workspace.git \
  main
```

#### 4. 拉取更新

```bash
git subtree pull --prefix=workspace \
  https://github.com/username/openclaw-workspace.git \
  main
```

### Subtree 优点

- 无需克隆额外仓库
- 推送拉取简单
- 不需要协作者安装额外工具

### Subtree 缺点

- 历史记录混合
- 解决冲突较复杂
- 需要每次指定远程 URL

---

## Submodule 方案

### 什么是 Submodule

Submodule 允许你将一个仓库作为独立子模块嵌入，可以在主仓库中精确控制版本。

### 配置步骤

#### 1. 准备远程仓库

创建 workspace 远程仓库，获得 URL：
`https://github.com/username/openclaw-workspace.git`

#### 2. 初始化 Submodule

```bash
cd /workspaces/ow1/.openclaw

# 如果 workspace 已在主仓库中，先删除目录
rm -rf workspace/

# 添加 submodule
git submodule add https://github.com/username/openclaw-workspace.git workspace
```

#### 3. 提交 Submodule 配置

```bash
git add .gitmodules workspace
git commit -m "Add workspace submodule"
```

#### 4. 克隆含 Submodule 的仓库

```bash
# 克隆主仓库
git clone https://github.com/username/openclaw-config.git

# 初始化 Submodule
git submodule init

# 拉取 Submodule 内容
git submodule update
```

或使用单命令：

```bash
git clone --recurse-submodules https://github.com/username/openclaw-config.git
```

#### 5. 更新 Submodule

```bash
# 进入 Submodule 目录
cd workspace

# 切换分支、提交修改
git checkout main
# ... 做修改 ...
git commit -m "Update workspace"
git push

# 回到主仓库，更新引用
cd ..
git add workspace
git commit -m "Update workspace to latest"
```

#### 6. 拉取主仓库更新

```bash
git pull

# 更新 Submodule 到最新提交
git submodule update --remote workspace
```

### Submodule 优点

- 清晰的版本控制
- 独立的历史记录
- 可以使用不同分支

### Submodule 缺点

- 命令复杂，易出错
- 协作者需要了解 submodule 工作原理
- 克隆和更新步骤多

---

## 方案对比与选择建议

### 对比表

| 特性 | 直接推送 | Subtree | Submodule |
|------|----------|---------|-----------|
| 配置复杂度 | 简单 | 中等 | 复杂 |
| 历史记录 | 统一 | 压缩后混合 | 独立 |
| 推送难度 | 简单 | 中等 | 较难 |
| 协作者友好 | 是 | 是 | 需要了解 |
| 远程仓库需求 | 1 个 | 1-2 个 | 1-2 个 |

### 选择建议

#### 场景一：个人使用，无需分享

**推荐：直接推送**

```bash
# 整体推送
git remote add origin <url>
git push -u origin main
```

简单直接，将来想拆分时可以用 `git subtree split` 分离。

#### 场景二：workspace 需要独立开源

**推荐：Subtree**

```bash
git subtree add --prefix=workspace <workspace-url> main --squash
```

保持独立性的同时管理简单。

#### 场景三：多项目共享 workspace

**推荐：Submodule**

```bash
git submodule add <workspace-url> workspace
```

精确版本控制，适合需要严格同步的场景。

### 当前推荐

鉴于当前需求，**推荐保持现有直接管理的方案**：

1. **现在**：直接管理整个 `.openclaw`
2. **将来需要**：根据具体场景选择 subtree 或 submodule

理由：
- 当前是个人使用
- 方案简单，不增加复杂度
- 将来有需求时再迁移成本不高

---

## 附录：常用命令速查

### OpenClaw 配置

```bash
# 查看配置
openclaw config get gateway
openclaw config get gateway --json

# 获取 Token
cat ~/.openclaw/openclaw.json | grep token
```

### Git 操作

```bash
# 查看状态
git status

# 添加修改
git add -A

# 提交
git commit -m "message"

# 推送
git push

# 查看历史
git log --oneline

# 撤销修改
git checkout -- <file>
```

### Subtree 操作

```bash
# 添加
git subtree add --prefix=<dir> <url> <branch> --squash

# 推送
git subtree push --prefix=<dir> <url> <branch>

# 拉取
git subtree pull --prefix=<dir> <url> <branch>
```

### Submodule 操作

```bash
# 添加
git submodule add <url> <dir>

# 克隆（含 submodule）
git clone --recurse-submodules <url>

# 更新
git submodule update --remote <dir>

# 删除
git submodule deinit <dir>
git rm <dir>
```

---

*文档创建于 2026-02-24*
