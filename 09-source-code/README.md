# OpenClaw 源码分析

本目录用于存放 OpenClaw 相关项目的源码和分析笔记。

## 克隆源码仓库

```bash
cd 09-source-code

# 克隆主仓库
git clone https://github.com/openclaw/openclaw.git

# 克隆技能市场
git clone https://github.com/openclaw/clawhub.git

# 克隆技能仓库
git clone https://github.com/openclaw/skills.git

# 克隆 Lobster 工作流引擎
git clone https://github.com/openclaw/lobster.git
```

## 目录结构

```
09-source-code/
├── openclaw/           # 主仓库源码
├── clawhub/            # 技能市场源码
├── skills/             # 技能仓库源码
├── lobster/            # Lobster 工作流引擎源码
├── 核心模块分析.md      # 核心模块源码分析
├── Gateway分析.md       # Gateway 源码分析
├── Agent运行时分析.md   # Agent Runtime 分析
├── 消息路由分析.md      # 消息路由分析
├── Skills系统分析.md    # Skills 系统分析
└── README.md           # 本文件
```

## 源码阅读顺序

### 第一阶段：入口和配置
1. `openclaw/src/index.ts` - 程序入口
2. `openclaw/src/config/` - 配置管理
3. `openclaw/src/types/` - 类型定义

### 第二阶段：核心组件
4. `openclaw/src/gateway/` - 网关实现
5. `openclaw/src/channels/` - 通道适配器
6. `openclaw/src/router/` - 消息路由
7. `openclaw/src/agent/` - Agent 运行时

### 第三阶段：扩展系统
8. `openclaw/src/skills/` - Skills 系统
9. `openclaw/src/plugins/` - Plugins 系统
10. `openclaw/src/hooks/` - Hooks 系统

### 第四阶段：工具和实用程序
11. `openclaw/src/tools/` - 内置工具
12. `openclaw/src/utils/` - 工具函数
13. `openclaw/src/storage/` - 存储层

## 分析方法

1. **自顶向下**：从入口开始，理解整体流程
2. **关键路径**：追踪一个请求的完整生命周期
3. **接口优先**：先看接口定义，再看实现
4. **画图辅助**：绘制类图、时序图、流程图
5. **运行调试**：实际运行代码，打断点调试

## 注意事项

- 源码仓库已添加到 .gitignore，不会被提交
- 定期更新源码：`git pull` 获取最新代码
- 在源码中添加注释时，不要直接修改，而是记录在分析文档中
- 重点关注核心逻辑，不要陷入细节

## 学习目标

通过源码分析，你应该能够：
- [ ] 理解 OpenClaw 的启动流程
- [ ] 掌握消息处理的完整链路
- [ ] 理解 Agent 的工作原理
- [ ] 掌握扩展系统的实现机制
- [ ] 能够贡献代码或开发自定义扩展

---

开始源码之旅！🚀
