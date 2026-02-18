# Gateway 网关详解

## 概述

Gateway 是 OpenClaw 的核心控制平面，是一个长期运行的 Node.js 进程，负责统一管理所有 Agent 操作。

## 核心职责

### 1. 统一控制平面

Gateway 作为单一的控制点：
- 管理所有消息通道的连接
- 协调 Agent 实例的生命周期
- 处理工具调用和权限控制
- 维护内存和会话持久化

### 2. 消息路由

```typescript
interface Gateway {
  // 接收来自各个通道的消息
  receiveMessage(channel: string, message: RawMessage): Promise<void>;
  
  // 路由到合适的 Agent
  routeToAgent(message: ParsedMessage): Promise<Agent>;
  
  // 返回响应
  sendResponse(channel: string, response: Response): Promise<void>;
}
```

---

## 架构设计

### 长期运行进程

Gateway 采用长期运行的设计，而不是无状态的请求-响应模式：

**优势**：
- ✅ 保持通道连接活跃
- ✅ 缓存会话状态
- ✅ 减少冷启动时间
- ✅ 支持主动推送消息

**挑战**：
- ⚠️ 需要处理进程崩溃
- ⚠️ 内存管理更复杂
- ⚠️ 需要优雅的重启机制

### 进程管理

```typescript
class Gateway {
  private channels: Map<string, Channel>;
  private agents: Map<string, Agent>;
  private isShuttingDown: boolean = false;
  
  async start(): Promise<void> {
    // 初始化所有通道
    await this.initializeChannels();
    
    // 启动 HTTP 服务器
    await this.startHttpServer();
    
    // 注册信号处理
    this.registerSignalHandlers();
    
    // 启动心跳检测
    this.startHeartbeat();
  }
  
  async shutdown(): Promise<void> {
    this.isShuttingDown = true;
    
    // 停止接收新消息
    await this.stopAcceptingMessages();
    
    // 等待当前任务完成
    await this.waitForPendingTasks();
    
    // 关闭所有连接
    await this.closeAllConnections();
    
    // 保存状态
    await this.persistState();
  }
}
```

---

## HTTP 服务器

### 端点设计

```typescript
// 健康检查
GET /health
Response: { status: "ok", version: "2026.2.14" }

// 消息接收（Webhook）
POST /webhook/:channel
Body: { message: "...", userId: "..." }

// 主动发送消息
POST /api/message
Headers: { Authorization: "Bearer token" }
Body: { userId: "...", message: "..." }

// 会话管理
GET /api/sessions/:userId
DELETE /api/sessions/:userId

// 配置管理
GET /api/config
PUT /api/config
```

### 中间件栈

```typescript
const app = express();

// 1. 日志中间件
app.use(requestLogger);

// 2. 认证中间件
app.use(authenticate);

// 3. 速率限制
app.use(rateLimit({
  windowMs: 60000,
  max: 100
}));

// 4. 请求解析
app.use(express.json());

// 5. 路由处理
app.use('/webhook', webhookRouter);
app.use('/api', apiRouter);

// 6. 错误处理
app.use(errorHandler);
```

---

## 认证和授权

### Token 认证

```typescript
interface AuthConfig {
  mode: 'token' | 'oauth' | 'none';
  token?: string;
  oauthProviders?: OAuthProvider[];
}

class TokenAuthenticator {
  verify(token: string): Promise<User> {
    // 验证 token 有效性
    if (token !== this.config.token) {
      throw new UnauthorizedError();
    }
    
    return { id: 'system', role: 'admin' };
  }
}
```

### OAuth 集成

```typescript
class OAuthAuthenticator {
  async verify(token: string): Promise<User> {
    // 调用 OAuth 提供者验证
    const userInfo = await this.provider.verifyToken(token);
    
    return {
      id: userInfo.sub,
      email: userInfo.email,
      role: this.determineRole(userInfo)
    };
  }
}
```

---

## 速率限制

### 基于用户的限流

```typescript
class RateLimiter {
  private limits: Map<string, RateLimit>;
  
  async checkLimit(userId: string): Promise<boolean> {
    const limit = this.limits.get(userId) || this.createLimit(userId);
    
    if (limit.count >= limit.max) {
      const resetIn = limit.resetAt - Date.now();
      throw new RateLimitError(`Rate limit exceeded. Reset in ${resetIn}ms`);
    }
    
    limit.count++;
    return true;
  }
  
  private createLimit(userId: string): RateLimit {
    return {
      userId,
      count: 0,
      max: 100,
      window: 60000,
      resetAt: Date.now() + 60000
    };
  }
}
```

### 配置示例

```json
{
  "gateway": {
    "rateLimit": {
      "enabled": true,
      "window": 60000,
      "maxRequests": 100,
      "perUser": true
    }
  }
}
```

---

## 连接管理

### WebSocket 支持

```typescript
class WebSocketManager {
  private connections: Map<string, WebSocket>;
  
  handleConnection(ws: WebSocket, userId: string): void {
    // 存储连接
    this.connections.set(userId, ws);
    
    // 处理消息
    ws.on('message', (data) => {
      this.handleMessage(userId, data);
    });
    
    // 处理断开
    ws.on('close', () => {
      this.connections.delete(userId);
    });
    
    // 心跳检测
    this.startPing(ws);
  }
  
  sendToUser(userId: string, message: any): void {
    const ws = this.connections.get(userId);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(message));
    }
  }
}
```

---

## 心跳机制

### 健康检查

```typescript
class HeartbeatManager {
  private interval: NodeJS.Timeout;
  
  start(): void {
    this.interval = setInterval(() => {
      this.performHealthCheck();
    }, 30000); // 每 30 秒
  }
  
  private async performHealthCheck(): Promise<void> {
    // 检查通道连接
    for (const [name, channel] of this.channels) {
      if (!await channel.isHealthy()) {
        console.warn(`Channel ${name} is unhealthy, reconnecting...`);
        await channel.reconnect();
      }
    }
    
    // 检查内存使用
    const memUsage = process.memoryUsage();
    if (memUsage.heapUsed > this.maxMemory) {
      console.warn('High memory usage, triggering GC');
      global.gc?.();
    }
    
    // 检查 Agent 状态
    await this.checkAgentHealth();
  }
}
```

---

## 错误处理

### 全局错误捕获

```typescript
class ErrorHandler {
  handle(error: Error, context: Context): Response {
    // 记录错误
    logger.error('Gateway error', {
      error: error.message,
      stack: error.stack,
      context
    });
    
    // 分类处理
    if (error instanceof ValidationError) {
      return { status: 400, message: error.message };
    }
    
    if (error instanceof UnauthorizedError) {
      return { status: 401, message: 'Unauthorized' };
    }
    
    if (error instanceof RateLimitError) {
      return { status: 429, message: error.message };
    }
    
    // 默认错误
    return { status: 500, message: 'Internal server error' };
  }
}
```

### 重试机制

```typescript
class RetryManager {
  async executeWithRetry<T>(
    fn: () => Promise<T>,
    options: RetryOptions = {}
  ): Promise<T> {
    const maxRetries = options.maxRetries || 3;
    const delay = options.delay || 1000;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (error) {
        if (i === maxRetries - 1) throw error;
        
        console.warn(`Retry ${i + 1}/${maxRetries} after error:`, error);
        await this.sleep(delay * Math.pow(2, i));
      }
    }
    
    throw new Error('Max retries exceeded');
  }
}
```

---

## 性能优化

### 连接池

```typescript
class ConnectionPool {
  private pool: Connection[];
  private maxSize: number = 10;
  
  async acquire(): Promise<Connection> {
    // 从池中获取空闲连接
    const conn = this.pool.find(c => !c.inUse);
    
    if (conn) {
      conn.inUse = true;
      return conn;
    }
    
    // 创建新连接
    if (this.pool.length < this.maxSize) {
      const newConn = await this.createConnection();
      this.pool.push(newConn);
      return newConn;
    }
    
    // 等待连接释放
    return this.waitForConnection();
  }
  
  release(conn: Connection): void {
    conn.inUse = false;
  }
}
```

### 缓存策略

```typescript
class CacheManager {
  private cache: Map<string, CacheEntry>;
  
  async get<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
    const cached = this.cache.get(key);
    
    if (cached && !this.isExpired(cached)) {
      return cached.value as T;
    }
    
    const value = await fetcher();
    this.cache.set(key, {
      value,
      expiresAt: Date.now() + 300000 // 5 分钟
    });
    
    return value;
  }
}
```

---

## 监控和日志

### 指标收集

```typescript
class MetricsCollector {
  private metrics: Metrics = {
    requestCount: 0,
    errorCount: 0,
    avgResponseTime: 0,
    activeConnections: 0
  };
  
  recordRequest(duration: number): void {
    this.metrics.requestCount++;
    this.updateAvgResponseTime(duration);
  }
  
  recordError(): void {
    this.metrics.errorCount++;
  }
  
  getMetrics(): Metrics {
    return { ...this.metrics };
  }
}
```

### 结构化日志

```typescript
logger.info('Message received', {
  channel: 'telegram',
  userId: 'user123',
  messageId: 'msg456',
  timestamp: Date.now()
});

logger.error('Agent execution failed', {
  agentId: 'agent789',
  error: error.message,
  stack: error.stack,
  context: { userId, messageId }
});
```

---

## 配置管理

### 动态配置

```typescript
class ConfigManager {
  private config: Config;
  private watchers: Set<ConfigWatcher>;
  
  async reload(): Promise<void> {
    const newConfig = await this.loadConfig();
    
    // 验证配置
    this.validate(newConfig);
    
    // 应用配置
    this.config = newConfig;
    
    // 通知观察者
    this.notifyWatchers();
  }
  
  watch(watcher: ConfigWatcher): void {
    this.watchers.add(watcher);
  }
}
```

---

## 学习检查点

完成本节后，你应该能够：
- [ ] 理解 Gateway 的核心职责
- [ ] 了解长期运行进程的设计考虑
- [ ] 掌握认证和授权机制
- [ ] 理解速率限制的实现
- [ ] 了解错误处理和重试策略

---

## 下一步

继续学习：[03-Agent运行时.md](./03-Agent运行时.md)
