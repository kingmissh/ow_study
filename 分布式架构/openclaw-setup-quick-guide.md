# OpenClaw Gateway + Node 快速配置指南

> 通过 Linux Gateway 控制远程 Windows 虚拟机

## 前置要求

- Linux 主机（Gateway）：192.168.2.134
- Windows 虚拟机（Node）：192.168.2.146
- 两台机器在同一局域网
- Node.js 22+ 已安装在两台机器上

---

## 第一部分：Linux Gateway 配置

### 1. 安装 OpenClaw

```bash
# 安装
npm install -g openclaw@latest

# 验证安装
openclaw --version
```

### 2. 配置防火墙

```bash
# 允许 Gateway 端口
sudo ufw allow 18789/tcp

# 验证
sudo ufw status
```

### 3. 创建配置文件

```bash
# 创建配置目录（如果不存在）
mkdir -p ~/.openclaw

# 创建配置文件
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "UoV4mCuOwgzixikzBuAvkpZnEpdiHoKNs8PBACwy03Y"
    }
  },
  "browser": {
    "enabled": true,
    "headless": false,
    "defaultProfile": "openclaw",
    "profiles": {
      "openclaw": {
        "cdpPort": 18800,
        "color": "#FF4500"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "你的_TELEGRAM_BOT_TOKEN",
      "dmPolicy": "pairing"
    }
  },
  "agents": {
    "defaults": {
      "target": "node:Windows-VM",
      "model": {
        "primary": "minimax-portal/MiniMax-M2.5"
      }
    }
  }
}
EOF
```

**重要配置说明：**
- `bind: "lan"` - 必须设置为 lan，允许局域网访问
- `auth.token` - 可以自定义，建议使用强随机字符串
- `target: "node:Windows-VM"` - 默认将任务路由到 Windows Node

**生成安全的 Token（可选）：**
```bash
openssl rand -base64 32
```

### 4. 启动 Gateway

```bash
# 前台运行（测试用）
openclaw gateway run

# 或安装为系统服务（推荐）
openclaw gateway install
openclaw gateway start

# 查看状态
openclaw gateway status
```

### 5. 验证 Gateway 运行

```bash
# 检查端口监听
sudo netstat -tlnp | grep 18789

# 访问 Web 界面
# 浏览器打开：http://192.168.2.134:18789
```

---

## 第二部分：Windows Node 配置

### 1. 安装 OpenClaw

在 PowerShell 中执行：

```powershell
# 安装
npm install -g openclaw@latest

# 验证安装
openclaw --version
```

### 2. 创建配置文件

```powershell
# 创建配置目录
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.openclaw"

# 创建配置文件
@"
{
  "browser": {
    "enabled": true,
    "headless": false,
    "defaultProfile": "windows-node",
    "profiles": {
      "windows-node": {
        "cdpPort": 18801,
        "color": "#00FF00",
        "userDataDir": "$env:USERPROFILE\\.openclaw\\browser-profiles\\windows-node"
      }
    }
  },
  "node": {
    "displayName": "Windows-VM",
    "capabilities": ["browser", "filesystem", "shell"]
  }
}
"@ | Out-File -FilePath "$env:USERPROFILE\.openclaw\openclaw.json" -Encoding UTF8
```

### 3. 启动 Node（首次连接）

```powershell
# 启动 Node 并发送配对请求
openclaw node run --host 192.168.2.134 --port 18789 --display-name "Windows-VM" --browser

# 你会看到类似输出：
# [node] connecting to gateway ws://192.168.2.134:18789
# [node] pairing request sent, waiting for approval...
```

**保持此窗口打开，等待 Gateway 批准配对**

---

## 第三部分：批准配对（在 Linux 上操作）

### 1. 查看待批准的配对请求

```bash
openclaw nodes pending

# 输出示例：
# Pending node pair requests:
# ID: req_abc123
# Display Name: Windows-VM
# IP: 192.168.2.146
# Capabilities: browser, filesystem, shell
# Requested: 2026-02-23 10:30:15
```

### 2. 批准配对请求

```bash
# 使用上面显示的 ID 批准
openclaw nodes approve req_abc123

# 成功后显示：
# ✓ Node pair approved
# Node ID: node_xyz789
# Token generated and sent to node
```

### 3. 验证连接

```bash
# 查看已连接的 Nodes
openclaw nodes list

# 输出示例：
# Connected Nodes:
# ✓ Windows-VM (node_xyz789)
#   Status: connected
#   IP: 192.168.2.146
#   Capabilities: browser, filesystem, shell
#   Browser Proxy: enabled (port 18801)
```

---

## 第四部分：配置执行权限（在 Linux 上操作）

默认情况下，Node 不允许执行任何命令。需要配置执行权限：

```bash
# 编辑执行权限配置
openclaw approvals --node Windows-VM
```

这会打开编辑器，添加以下内容：

**测试环境配置（允许所有命令）：**
```json
{
  "nodes": {
    "Windows-VM": {
      "allowAll": true
    }
  }
}
```

**生产环境配置（限制特定命令）：**
```json
{
  "nodes": {
    "Windows-VM": {
      "allowedCommands": [
        "dir",
        "echo",
        "type",
        "powershell -Command Get-*",
        "cmd /c dir"
      ],
      "allowedPaths": [
        "C:\\Users\\*",
        "C:\\Temp\\*"
      ],
      "denyPatterns": [
        "*rm -rf*",
        "*del /f*",
        "*format*"
      ]
    }
  }
}
```

保存后权限立即生效，无需重启。

---

## 第五部分：验证配置

### 在 Windows 上检查

回到 Windows PowerShell 窗口，应该看到：

```
[node] ✓ paired successfully
[node] node id: node_xyz789
[node] connected to gateway
[node] browser proxy enabled on port 18801
```

同时会自动生成配置文件：

```powershell
# 查看自动生成的配置
cat $env:USERPROFILE\.openclaw\node.json

# 内容示例：
# {
#   "nodeId": "node_xyz789",
#   "token": "自动生成的Token",
#   "displayName": "Windows-VM",
#   "gateway": {
#     "host": "192.168.2.134",
#     "port": 18789
#   }
# }
```

### 在 Linux 上测试连接

```bash
# 测试网络连接
sudo netstat -tn | grep 18789
# 应该看到：192.168.2.134:18789 <-> 192.168.2.146:xxxxx ESTABLISHED

# 测试浏览器代理
curl http://192.168.2.146:18801/json/version
# 应该返回 Chrome 版本信息
```

### 发送测试命令

```bash
# 通过 CLI 发送命令到 Windows Node
openclaw exec --node Windows-VM --command "echo Hello from Windows"

# 预期输出：
# Hello from Windows
```

---

## 第六部分：配置为系统服务（可选）

### Windows 上配置服务

配对成功后，可以将 Node 安装为系统服务：

```powershell
# 安装为服务
openclaw node install --host 192.168.2.134 --port 18789 --display-name "Windows-VM" --browser

# 管理服务
openclaw node status    # 查看状态
openclaw node start     # 启动服务
openclaw node stop      # 停止服务
openclaw node restart   # 重启服务
openclaw node uninstall # 卸载服务
```

### Linux 上 Gateway 已配置为服务

```bash
# 管理 Gateway 服务
openclaw gateway status
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
```

---

## 配置完成检查清单

### Linux Gateway
- [x] OpenClaw 已安装
- [x] 防火墙允许 18789 端口
- [x] 配置文件已创建（`~/.openclaw/openclaw.json`）
- [x] `bind: "lan"` 已设置
- [x] Gateway 正在运行
- [x] 可以访问 Web 界面（http://192.168.2.134:18789）

### Windows Node
- [x] OpenClaw 已安装
- [x] 配置文件已创建（`%USERPROFILE%\.openclaw\openclaw.json`）
- [x] Node 已启动并发送配对请求
- [x] 配对请求已在 Gateway 上批准
- [x] Node 显示连接成功
- [x] `node.json` 文件已自动生成

### 权限和连接
- [x] 执行权限已配置
- [x] Gateway 可以看到 Node（`openclaw nodes list`）
- [x] 网络连接已建立（netstat 显示 ESTABLISHED）
- [x] 测试命令执行成功

---

## 快速测试

### 测试 1：命令执行

```bash
# 在 Linux 上执行
openclaw exec --node Windows-VM --command "hostname"
```

### 测试 2：浏览器操作（通过 Telegram）

在 Telegram 中发送：
```
@你的Bot target:Windows-VM 打开浏览器访问 example.com 并截图
```

---

## 常见问题

### Q: Node 无法连接到 Gateway
```bash
# 检查 Gateway 是否运行
openclaw gateway status

# 检查防火墙
sudo ufw status | grep 18789

# 测试网络连通性（在 Windows 上）
Test-NetConnection -ComputerName 192.168.2.134 -Port 18789
```

### Q: 配对请求未显示
```bash
# 查看 Gateway 日志
tail -f ~/.openclaw/logs/gateway.log

# 确认 Gateway 配置中 bind 设置为 lan
cat ~/.openclaw/openclaw.json | grep bind
```

### Q: 命令执行被拒绝
```bash
# 配置执行权限
openclaw approvals --node Windows-VM

# 添加 "allowAll": true 用于测试
```

### Q: 重置配对
```bash
# 在 Gateway 上删除 Node
openclaw nodes remove Windows-VM

# 在 Windows 上删除配对信息
Remove-Item $env:USERPROFILE\.openclaw\node.json

# 重新启动 Node 并配对
openclaw node run --host 192.168.2.134 --port 18789 --display-name "Windows-VM" --browser
```

---

## 下一步

配置完成后，你可以：

1. **配置 Telegram Bot** - 通过消息控制 Windows 虚拟机
2. **添加更多 Node** - 连接多个 Windows 虚拟机
3. **配置定时任务** - 自动化执行任务
4. **设置安全策略** - 限制命令执行和访问权限

参考完整文档：`openclaw-complete-setup-guide.md`
