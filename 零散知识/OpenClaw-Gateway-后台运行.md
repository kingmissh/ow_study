# OpenClaw Gateway 后台运行方案

在 Codespace 环境中，systemd 不可用，gateway 停止后不会自动重启。以下是三种解决方案：

## 方案1: nohup 后台运行

```bash
nohup openclaw gateway run --port 18789 > /tmp/gateway.log 2>&1 &
```

停止方法：
```bash
pkill -f "openclaw gateway"
```

## 方案2: auto-restart 后台运行（推荐）

```bash
nohup bash -c 'while true; do openclaw gateway run --port 18789; echo "Gateway stopped, restarting in 5s..."; sleep 5; done' > /tmp/gateway.log 2>&1 &
```

停止方法：
```bash
pkill -f "openclaw gateway"
```

## 方案3: tmux/screen 运行

```bash
tmux new -d -s gateway "openclaw gateway run --port 18789"
```

查看 tmux 会话：
```bash
tmux attach -t gateway
```

停止方法：
```bash
tmux kill-session -t gateway
```

---

## 查看 gateway 状态

```bash
# 检查端口
ss -tlnp | grep 18789

# 检查健康状态
openclaw health

# 查看日志
tail -f /tmp/gateway.log
```
