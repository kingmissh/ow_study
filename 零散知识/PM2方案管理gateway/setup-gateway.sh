#!/bin/bash

set -e

echo "🦞 OpenClaw Gateway 自动配置脚本"
echo "================================"

OS=$(uname -s)
CONFIG_DIR="$HOME/.openclaw"
PM2_PORT=18789

install_pm2() {
    echo "[1/4] 安装 pm2..."
    npm install -g pm2
    echo "✅ pm2 安装完成"
}

create_config() {
    echo "[2/4] 创建 pm2 配置文件..."
    
    # 从配置文件中读取 token
    CONFIG_FILE="$CONFIG_DIR/openclaw.json"
    if [ -f "$CONFIG_FILE" ]; then
        TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('gateway',{}).get('auth',{}).get('token',''))" 2>/dev/null || echo "")
    else
        TOKEN=""
    fi
    
    if [ -n "$TOKEN" ]; then
        TOKEN_LINE="
      OPENCLAW_GATEWAY_TOKEN: \"$TOKEN\""
    else
        TOKEN_LINE=""
    fi
    
    cat > "$CONFIG_DIR/ecosystem.config.js" << EOF
module.exports = {
  apps: [{
    name: 'openclaw-gateway',
    script: 'openclaw',
    args: 'gateway --port $PM2_PORT',
    interpreter: 'none',
    autorestart: true,
    watch: false,
    max_restarts: 10,
    exp_backoff_restart_delay: 1000,
    env: {
      OPENCLAW_GATEWAY_PORT: $PM2_PORT,$TOKEN_LINE
    }
  }]
};
EOF

    echo "✅ 配置文件创建完成: $CONFIG_DIR/ecosystem.config.js"
}

create_startup_script() {
    echo "[3/4] 创建启动脚本..."
    
    if [[ "$OS" == "Linux" || "$OS" == "Darwin" ]]; then
        cat > "$CONFIG_DIR/start-gateway.sh" << EOF
#!/bin/bash
cd "$CONFIG_DIR"
pm2 start ecosystem.config.js
pm2 save
echo "✅ Gateway 已启动，端口: $PM2_PORT"
EOF
        chmod +x "$CONFIG_DIR/start-gateway.sh"
        echo "✅ Linux/macOS 启动脚本: $CONFIG_DIR/start-gateway.sh"
        
    elif [[ "$OS" == "CYGWIN"* || "$OS" == "MINGW"* || "$OS" == "MSYS"* ]]; then
        cat > "$CONFIG_DIR/start-gateway.bat" << EOF
@echo off
cd %USERPROFILE%\.openclaw
pm2 start ecosystem.config.js
pm2 save
echo Gateway 已启动，端口: $PM2_PORT
EOF
        echo "✅ Windows 启动脚本: $CONFIG_DIR/start-gateway.bat"
    fi
}

start_gateway() {
    echo "[4/4] 启动 Gateway..."
    cd "$CONFIG_DIR"
    
    # 清理可能存在的旧进程
    pm2 delete openclaw-gateway 2>/dev/null || true
    
    pm2 start ecosystem.config.js
    pm2 save
    
    sleep 2
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$PM2_PORT/ 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Gateway 运行正常 (HTTP $HTTP_CODE)"
    else
        echo "⚠️  Gateway 可能未就绪 (HTTP $HTTP_CODE)"
    fi
    
    echo ""
    echo "===== 完成 ====="
    echo "Gateway: http://127.0.0.1:$PM2_PORT/"
    echo "Dashboard: http://127.0.0.1:$PM2_PORT/"
    echo ""
    echo "常用命令:"
    echo "  pm2 status openclaw-gateway   # 查看状态"
    echo "  pm2 logs openclaw-gateway    # 查看日志"
    echo "  pm2 restart openclaw-gateway # 重启"
}

if command -v pm2 &> /dev/null; then
    echo "✅ pm2 已安装"
else
    install_pm2
fi

create_config
create_startup_script
start_gateway
