# Skills 系统概述

## 什么是 Skills？

Skills 是 OpenClaw 的扩展功能模块，允许你为 AI 助手添加特定领域的能力。

## 核心概念

### Skill 的组成

```
my-skill/
├── skill.json          # 技能元数据
├── index.js/index.py   # 入口文件
├── tools/              # 工具定义
├── prompts/            # Prompt 模板
├── package.json        # 依赖（JS）
├── requirements.txt    # 依赖（Python）
└── README.md           # 文档
```

---

## Skill 元数据

### skill.json

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "My custom skill",
  "author": "Your Name",
  "license": "MIT",
  "runtime": "node",
  "entry": "index.js",
  "tools": [
    {
      "name": "my_tool",
      "description": "Does something useful",
      "parameters": {
        "type": "object",
        "properties": {
          "input": {
            "type": "string",
            "description": "Input parameter"
          }
        },
        "required": ["input"]
      }
    }
  ],
  "permissions": [
    "network",
    "filesystem:read"
  ],
  "config": {
    "apiKey": {
      "type": "string",
      "required": true,
      "description": "API key for the service"
    }
  }
}
```

---

## 技能类型

### 1. API 集成技能

连接第三方服务：
- Notion
- GitHub
- Gmail
- Calendar
- Weather API

**示例**：
```javascript
// notion-skill/index.js
export default {
  async createPage(args, context) {
    const { title, content } = args;
    const { config } = context;
    
    const response = await fetch('https://api.notion.com/v1/pages', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        parent: { database_id: config.databaseId },
        properties: {
          title: { title: [{ text: { content: title } }] }
        },
        children: [
          { paragraph: { rich_text: [{ text: { content } }] } }
        ]
      })
    });
    
    return response.json();
  }
};
```

### 2. 数据处理技能

处理和分析数据：
- CSV 解析
- JSON 转换
- 数据可视化
- 统计分析

**示例**：
```python
# data-analysis-skill/index.py
import pandas as pd
import json

def analyze_csv(args, context):
    file_path = args['file_path']
    
    # 读取 CSV
    df = pd.read_csv(file_path)
    
    # 基础统计
    stats = {
        'rows': len(df),
        'columns': len(df.columns),
        'summary': df.describe().to_dict()
    }
    
    return json.dumps(stats)
```

### 3. 自动化技能

执行自动化任务：
- 文件批处理
- 定时任务
- 工作流自动化

### 4. 工具技能

提供实用工具：
- 文本处理
- 图片处理
- PDF 操作
- 加密解密

---

## 技能开发

### JavaScript 技能

```javascript
// index.js
export default {
  // 工具定义
  tools: {
    async myTool(args, context) {
      const { input } = args;
      const { config, user } = context;
      
      // 实现逻辑
      const result = await processInput(input);
      
      return result;
    }
  },
  
  // 初始化
  async init(config) {
    // 初始化代码
    this.client = createClient(config.apiKey);
  },
  
  // 清理
  async cleanup() {
    // 清理资源
    await this.client.close();
  }
};
```

### Python 技能

```python
# index.py
class MySkill:
    def __init__(self, config):
        self.config = config
        self.client = create_client(config['api_key'])
    
    def my_tool(self, args, context):
        """工具实现"""
        input_data = args['input']
        
        # 处理逻辑
        result = self.process(input_data)
        
        return result
    
    def cleanup(self):
        """清理资源"""
        self.client.close()

# 导出
skill = MySkill
```

---

## 技能安装

### 从 ClawHub 安装

```bash
# 搜索技能
openclaw skill search notion

# 安装技能
openclaw skill install notion

# 列出已安装技能
openclaw skill list

# 更新技能
openclaw skill update notion

# 卸载技能
openclaw skill uninstall notion
```

### 从本地安装

```bash
# 从目录安装
openclaw skill install ./my-skill

# 从 Git 仓库安装
openclaw skill install https://github.com/user/my-skill.git
```

---

## 技能配置

### 在 openclaw.json 中配置

```json
{
  "skills": {
    "entries": {
      "notion": {
        "enabled": true,
        "apiKey": "secret_xxx",
        "databaseId": "xxx"
      },
      "github": {
        "enabled": true,
        "token": "ghp_xxx",
        "defaultRepo": "user/repo"
      }
    }
  }
}
```

### 环境变量

```bash
# .env
NOTION_API_KEY=secret_xxx
GITHUB_TOKEN=ghp_xxx
```

---

## 技能权限

### 权限类型

```json
{
  "permissions": [
    "network",              // 网络访问
    "filesystem:read",      // 读取文件
    "filesystem:write",     // 写入文件
    "shell:execute",        // 执行命令
    "env:read",            // 读取环境变量
    "database:read",       // 读取数据库
    "database:write"       // 写入数据库
  ]
}
```

### 权限检查

```javascript
// 在技能中检查权限
if (!context.hasPermission('filesystem:write')) {
  throw new Error('Permission denied: filesystem:write');
}
```

---

## 技能测试

### 单元测试

```javascript
// test/my-tool.test.js
import { describe, it, expect } from 'vitest';
import skill from '../index.js';

describe('MyTool', () => {
  it('should process input correctly', async () => {
    const result = await skill.tools.myTool(
      { input: 'test' },
      { config: { apiKey: 'test-key' } }
    );
    
    expect(result).toBeDefined();
  });
});
```

### 集成测试

```bash
# 在 OpenClaw 中测试
openclaw skill test my-skill --input '{"input": "test"}'
```

---

## 技能发布

### 发布到 ClawHub

```bash
# 登录
openclaw login

# 发布技能
openclaw skill publish ./my-skill

# 更新版本
openclaw skill publish ./my-skill --version 1.1.0
```

### 发布到 npm/PyPI

```bash
# JavaScript
npm publish

# Python
python setup.py sdist bdist_wheel
twine upload dist/*
```

---

## 最佳实践

### 1. 错误处理

```javascript
export default {
  async myTool(args, context) {
    try {
      // 验证输入
      if (!args.input) {
        throw new Error('Input is required');
      }
      
      // 执行逻辑
      const result = await process(args.input);
      
      return result;
    } catch (error) {
      // 记录错误
      context.logger.error('Tool execution failed', error);
      
      // 返回友好的错误消息
      throw new Error(`Failed to process: ${error.message}`);
    }
  }
};
```

### 2. 日志记录

```javascript
context.logger.info('Processing input', { input: args.input });
context.logger.debug('API response', { response });
context.logger.error('Error occurred', { error });
```

### 3. 配置验证

```javascript
async init(config) {
  if (!config.apiKey) {
    throw new Error('API key is required');
  }
  
  // 验证 API key
  await this.validateApiKey(config.apiKey);
}
```

### 4. 资源清理

```javascript
async cleanup() {
  // 关闭连接
  await this.client.close();
  
  // 清理临时文件
  await this.cleanupTempFiles();
  
  // 释放资源
  this.cache.clear();
}
```

---

## 常见技能示例

### 1. 天气查询

```javascript
export default {
  async getWeather(args, context) {
    const { location } = args;
    const { config } = context;
    
    const response = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${location}&appid=${config.apiKey}`
    );
    
    const data = await response.json();
    
    return {
      temperature: data.main.temp,
      description: data.weather[0].description,
      humidity: data.main.humidity
    };
  }
};
```

### 2. 文件搜索

```python
import os
import fnmatch

def search_files(args, context):
    pattern = args['pattern']
    directory = args.get('directory', '.')
    
    matches = []
    for root, dirs, files in os.walk(directory):
        for filename in fnmatch.filter(files, pattern):
            matches.append(os.path.join(root, filename))
    
    return {'files': matches, 'count': len(matches)}
```

---

## 学习检查点

完成本节后，你应该能够：
- [ ] 理解 Skills 的结构和组成
- [ ] 知道如何安装和配置技能
- [ ] 了解不同类型的技能
- [ ] 掌握技能开发的基础
- [ ] 理解权限和安全机制

---

## 下一步

继续学习：
- [02-开发第一个Skill.md](./02-开发第一个Skill.md)
- [03-Skills最佳实践.md](./03-Skills最佳实践.md)
