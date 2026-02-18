# Agent 运行时详解

## 概述

Agent 运行时是 OpenClaw 的核心执行引擎，基于 `pi-agent-core`，负责 AI 推理、工具调用和任务执行。

## 核心概念

### Pi Agent Core

Pi 是一个最小化的 Agent 框架，设计理念：
- **代码优先**：LLM 擅长编写和运行代码，拥抱这一点
- **最小抽象**：避免过度工程化
- **可组合性**：工具和技能可以组合使用

---

## 架构组件

### 1. Agent 实例

```typescript
class Agent {
  private id: string;
  private userId: string;
  private session: Session;
  private llm: LLMClient;
  private tools: ToolRegistry;
  private memory: MemoryManager;
  
  async processMessage(message: string): Promise<Response> {
    // 1. 加载上下文
    const context = await this.loadContext();
    
    // 2. 构建 Prompt
    const prompt = this.buildPrompt(message, context);
    
    // 3. 调用 LLM
    const response = await this.llm.generate(prompt);
    
    // 4. 解析工具调用
    const toolCalls = this.parseToolCalls(response);
    
    // 5. 执行工具
    const toolResults = await this.executeTools(toolCalls);
    
    // 6. 生成最终响应
    return this.generateFinalResponse(response, toolResults);
  }
}
```

---

## LLM 集成

### 模型管理器

```typescript
class LLMManager {
  private providers: Map<string, LLMProvider>;
  private modelCache: Map<string, Model>;
  
  async selectModel(task: Task): Promise<Model> {
    // 根据任务类型选择模型
    if (task.requiresReasoning) {
      return this.getModel('claude-opus-4');
    }
    
    if (task.isSimple) {
      return this.getModel('gemini-flash');
    }
    
    return this.getModel('default');
  }
  
  async invoke(prompt: Prompt, model: Model): Promise<Response> {
    // 添加到请求队列
    const request = this.createRequest(prompt, model);
    
    // 执行请求
    const response = await this.executeRequest(request);
    
    // 缓存响应
    this.cacheResponse(request, response);
    
    return response;
  }
}
```

### Prompt 构建

```typescript
class PromptBuilder {
  build(message: string, context: Context): Prompt {
    return {
      system: this.buildSystemPrompt(context),
      messages: [
        ...context.history,
        { role: 'user', content: message }
      ],
      tools: this.getAvailableTools(context),
      temperature: 0.7,
      maxTokens: 4096
    };
  }
  
  private buildSystemPrompt(context: Context): string {
    const parts = [];
    
    // 基础身份
    parts.push(this.getBaseIdentity());
    
    // 动态 "灵魂"（从文件系统加载）
    if (context.soulFile) {
      parts.push(fs.readFileSync(context.soulFile, 'utf-8'));
    }
    
    // 用户偏好
    if (context.userPreferences) {
      parts.push(this.formatPreferences(context.userPreferences));
    }
    
    // 当前任务上下文
    parts.push(this.formatTaskContext(context));
    
    return parts.join('\n\n');
  }
}
```

---

## 工具系统

### 工具注册表

```typescript
class ToolRegistry {
  private tools: Map<string, Tool>;
  
  register(tool: Tool): void {
    this.tools.set(tool.name, tool);
  }
  
  get(name: string): Tool | undefined {
    return this.tools.get(name);
  }
  
  getAll(): Tool[] {
    return Array.from(this.tools.values());
  }
  
  getForContext(context: Context): Tool[] {
    // 根据上下文过滤可用工具
    return this.getAll().filter(tool => {
      return tool.isAvailable(context);
    });
  }
}
```

### 工具定义

```typescript
interface Tool {
  name: string;
  description: string;
  parameters: ParameterSchema;
  
  execute(args: any, context: Context): Promise<any>;
  isAvailable(context: Context): boolean;
}

// 示例：文件读取工具
const readFileTool: Tool = {
  name: 'read_file',
  description: 'Read contents of a file',
  parameters: {
    type: 'object',
    properties: {
      path: {
        type: 'string',
        description: 'File path to read'
      }
    },
    required: ['path']
  },
  
  async execute(args, context) {
    const { path } = args;
    
    // 安全检查
    if (!this.isPathSafe(path, context)) {
      throw new SecurityError('Path not allowed');
    }
    
    // 读取文件
    return fs.readFileSync(path, 'utf-8');
  },
  
  isAvailable(context) {
    return context.permissions.includes('file:read');
  }
};
```

### 工具执行器

```typescript
class ToolExecutor {
  async execute(toolCall: ToolCall, context: Context): Promise<ToolResult> {
    const tool = this.registry.get(toolCall.name);
    
    if (!tool) {
      throw new Error(`Tool not found: ${toolCall.name}`);
    }
    
    // 验证参数
    this.validateArgs(toolCall.args, tool.parameters);
    
    // 检查权限
    if (!tool.isAvailable(context)) {
      throw new PermissionError(`Tool ${toolCall.name} not available`);
    }
    
    // 执行工具
    try {
      const result = await tool.execute(toolCall.args, context);
      
      return {
        toolCallId: toolCall.id,
        success: true,
        result
      };
    } catch (error) {
      return {
        toolCallId: toolCall.id,
        success: false,
        error: error.message
      };
    }
  }
  
  async executeChain(toolCalls: ToolCall[], context: Context): Promise<ToolResult[]> {
    const results: ToolResult[] = [];
    
    for (const toolCall of toolCalls) {
      const result = await this.execute(toolCall, context);
      results.push(result);
      
      // 如果工具失败，停止执行链
      if (!result.success && toolCall.required) {
        break;
      }
    }
    
    return results;
  }
}
```

---

## 记忆管理

### 动态 "灵魂"

OpenClaw 的创新之处在于动态注入 "灵魂"：

```typescript
class SoulManager {
  private soulPath: string;
  
  async loadSoul(userId: string): Promise<string> {
    // 从文件系统加载用户的 "灵魂"
    const soulFile = path.join(this.soulPath, `${userId}.md`);
    
    if (fs.existsSync(soulFile)) {
      return fs.readFileSync(soulFile, 'utf-8');
    }
    
    // 返回默认灵魂
    return this.getDefaultSoul();
  }
  
  async updateSoul(userId: string, updates: string): Promise<void> {
    const soulFile = path.join(this.soulPath, `${userId}.md`);
    const currentSoul = await this.loadSoul(userId);
    
    // 合并更新
    const newSoul = this.mergeSoul(currentSoul, updates);
    
    // 保存
    fs.writeFileSync(soulFile, newSoul, 'utf-8');
  }
}
```

### 会话记忆

```typescript
class MemoryManager {
  private storage: MemoryStorage;
  
  async save(userId: string, memory: Memory): Promise<void> {
    await this.storage.save({
      userId,
      timestamp: Date.now(),
      type: memory.type,
      content: memory.content,
      metadata: memory.metadata
    });
  }
  
  async retrieve(userId: string, query: string): Promise<Memory[]> {
    // 向量搜索相关记忆
    const relevant = await this.storage.search(userId, query, {
      limit: 10,
      threshold: 0.7
    });
    
    return relevant;
  }
  
  async getRecent(userId: string, limit: number = 20): Promise<Memory[]> {
    return this.storage.getRecent(userId, limit);
  }
}
```

### 长期记忆

```typescript
interface LongTermMemory {
  // 事实记忆
  facts: Map<string, Fact>;
  
  // 偏好记忆
  preferences: Map<string, Preference>;
  
  // 技能记忆
  skills: Map<string, SkillUsage>;
  
  // 关系记忆
  relationships: Map<string, Relationship>;
}

class LongTermMemoryManager {
  async consolidate(userId: string): Promise<void> {
    // 从短期记忆中提取重要信息
    const recentMemories = await this.getRecentMemories(userId);
    
    // 识别模式和重要事实
    const facts = await this.extractFacts(recentMemories);
    const preferences = await this.extractPreferences(recentMemories);
    
    // 更新长期记忆
    await this.updateLongTermMemory(userId, { facts, preferences });
  }
}
```

---

## 上下文管理

### 上下文窗口

```typescript
class ContextManager {
  private maxTokens: number = 128000;
  
  async buildContext(userId: string, message: string): Promise<Context> {
    // 加载会话历史
    const history = await this.loadHistory(userId);
    
    // 加载相关记忆
    const memories = await this.loadRelevantMemories(userId, message);
    
    // 加载灵魂
    const soul = await this.loadSoul(userId);
    
    // 计算 token 使用
    const tokens = this.calculateTokens({ history, memories, soul, message });
    
    // 如果超出限制，压缩上下文
    if (tokens > this.maxTokens) {
      return this.compressContext({ history, memories, soul, message });
    }
    
    return { history, memories, soul, message };
  }
  
  private compressContext(context: RawContext): Context {
    // 保留最近的消息
    const recentHistory = context.history.slice(-10);
    
    // 总结旧消息
    const summary = this.summarizeHistory(context.history.slice(0, -10));
    
    // 过滤记忆
    const topMemories = this.rankMemories(context.memories).slice(0, 5);
    
    return {
      history: [summary, ...recentHistory],
      memories: topMemories,
      soul: context.soul,
      message: context.message
    };
  }
}
```

---

## 流式响应

### 流式生成

```typescript
class StreamingAgent {
  async *processMessageStream(message: string): AsyncGenerator<Token> {
    const context = await this.loadContext();
    const prompt = this.buildPrompt(message, context);
    
    // 流式调用 LLM
    for await (const token of this.llm.stream(prompt)) {
      yield token;
      
      // 检测工具调用
      if (this.isToolCall(token)) {
        const toolResult = await this.executeTool(token);
        yield this.formatToolResult(toolResult);
      }
    }
  }
}
```

### 部分响应

```typescript
class PartialResponseHandler {
  async handlePartialResponse(userId: string, tokens: Token[]): Promise<void> {
    // 累积 tokens
    const accumulated = this.accumulate(tokens);
    
    // 每 N 个 tokens 发送一次更新
    if (accumulated.length % 10 === 0) {
      await this.sendUpdate(userId, accumulated);
    }
  }
}
```

---

## 错误恢复

### 重试策略

```typescript
class AgentRetryManager {
  async executeWithRetry(fn: () => Promise<any>): Promise<any> {
    const maxRetries = 3;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (error) {
        if (this.isRetryable(error) && i < maxRetries - 1) {
          await this.sleep(Math.pow(2, i) * 1000);
          continue;
        }
        throw error;
      }
    }
  }
  
  private isRetryable(error: Error): boolean {
    return error instanceof NetworkError ||
           error instanceof TimeoutError ||
           error instanceof RateLimitError;
  }
}
```

### 状态恢复

```typescript
class StateRecoveryManager {
  async saveCheckpoint(agentId: string, state: AgentState): Promise<void> {
    await this.storage.save(`checkpoint:${agentId}`, state);
  }
  
  async recoverFromCheckpoint(agentId: string): Promise<AgentState | null> {
    return this.storage.load(`checkpoint:${agentId}`);
  }
}
```

---

## 性能优化

### 并发控制

```typescript
class ConcurrencyController {
  private maxConcurrent: number = 4;
  private activeAgents: Set<string> = new Set();
  
  async acquire(agentId: string): Promise<void> {
    while (this.activeAgents.size >= this.maxConcurrent) {
      await this.waitForSlot();
    }
    
    this.activeAgents.add(agentId);
  }
  
  release(agentId: string): void {
    this.activeAgents.delete(agentId);
  }
}
```

### 缓存策略

```typescript
class ResponseCache {
  async get(prompt: string): Promise<Response | null> {
    const hash = this.hashPrompt(prompt);
    return this.cache.get(hash);
  }
  
  async set(prompt: string, response: Response): void {
    const hash = this.hashPrompt(prompt);
    await this.cache.set(hash, response, { ttl: 3600 });
  }
}
```

---

## 学习检查点

完成本节后，你应该能够：
- [ ] 理解 Agent 的执行流程
- [ ] 掌握工具系统的设计
- [ ] 了解记忆管理机制
- [ ] 理解动态 "灵魂" 的概念
- [ ] 掌握流式响应的实现

---

## 下一步

继续学习：[04-消息路由.md](./04-消息路由.md)
