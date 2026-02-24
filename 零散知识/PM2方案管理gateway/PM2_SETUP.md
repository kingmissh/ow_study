# OpenClaw Gateway PM2 管理方案

## 问题背景

在 Codespace 环境中，systemd 不可用，导致 gateway 进程无法通过服务方式自启。每次断线重连后需要手动重启。

## 解决方案

使用 pm2 管理 gateway 进程，实现自动重启和持久化运行。

## 一键配置

运行以下命令自动完成所有配置：

```bash
~/.openclaw/setup-gateway.sh
```

脚本会自动：
1. 检测并安装 pm2（如未安装）
2. 创建 pm2 配置文件 `ecosystem.config.js`
3. 创建对应系统的启动脚本
4. 启动 Gateway 并验证

## 手动使用（如需要）

### Linux / macOS

```bash
~/.openclaw/start-gateway.sh
```

### Windows

```cmd
%USERPROFILE%\.openclaw\start-gateway.bat
```

## 功能说明

| 功能 | 说明 |
|------|------|
| 自动重启 | 进程崩溃后自动重启（默认最多10次） |
| 指数退避 | 重启间隔：1s → 2s → 4s... |
| 持久化 | `pm2 save` 保存进程列表，重启后自动恢复 |

## 常用命令

```bash
pm2 status openclaw-gateway   # 查看状态
pm2 logs openclaw-gateway    # 查看日志
pm2 restart openclaw-gateway # 重启
pm2 stop openclaw-gateway    # 停止
```

## 验证

```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/
# 预期输出: 200
```
