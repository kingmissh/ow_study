# Telegram 群组配置完整指南

本文档记录了如何在 OpenClaw 中配置 Telegram 群组，实现机器人自动回复。

## 目录

1. [群组配置结构](#群组配置结构)
2. [快速添加新群组](#快速添加新群组)
3. [完整配置示例](#完整配置示例)
4. [配置字段说明](#配置字段说明)
5. [常见问题排查](#常见问题排查)

---

## 群组配置结构

OpenClaw 的 Telegram 群组配置位于 `~/.openclaw/openclaw.json` 中的 `channels.telegram` 字段：

```json5
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "你的BotToken",
      "groups": {
        "群组ID": {
          "requireMention": false  // 是否需要@才能回复
        }
      },
      "groupPolicy": "allowlist",  // 群组策略
      "groupAllowFrom": [],        // 允许的群组ID列表（可选）
      "streamMode": "partial"
    }
  }
}
```

---

## 快速添加新群组

### 步骤 1: 把机器人拉进群组

在 Telegram 中将机器人 `@你的机器人用户名` 拉入群组。

### 步骤 2: 让机器人在群里发消息

在群里发一条消息（可以 @机器人 或发任何内容）。

### 步骤 3: 获取群组 ID

查看 OpenClaw 日志获取群组 ID：

```bash
tail -30 /tmp/openclaw/openclaw-2026-02-25.log | grep -i "telegram"
```

日志中会显示：
```
{"chatId":-1003811467888,"title":"临时2","reason":"not-allowed"},"skipping group message"
```

- `chatId`: 群组 ID（如 `-1003811467888`）
- `title`: 群组名称
- `reason`: 如果是 `not-allowed`，说明需要添加到配置

### 步骤 4: 添加到配置

```bash
# 添加群组（不需要 @ 也能回复）
jq '.channels.telegram.groups["-1003811467888"] = {"requireMention": false}' ~/.openclaw/openclaw.json > /tmp/openclaw.json && mv /tmp/openclaw.json ~/.openclaw/openclaw.json

# 重启 Gateway
openclaw gateway restart
```

---

## 完整配置示例

```json5
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "open",
      "botToken": "8210848222:AAFL5mlmjwdHqdjftnw4ebY7astf44nqwzw",
      "groups": {
        "-1003554523788": {
          "requireMention": false
        },
        "-1003811467888": {
          "requireMention": false
        },
        "-1003702654859": {
          "requireMention": false
        }
      },
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  }
}
```

---

## 配置字段说明

| 字段 | 类型 | 说明 | 可选值 |
|------|------|------|--------|
| `enabled` | boolean | 是否启用 Telegram 频道 | `true` / `false` |
| `dmPolicy` | string | 私聊消息策略 | `pairing` / `allowlist` / `open` / `disabled` |
| `botToken` | string | Telegram 机器人 Token | - |
| `groups` | object | 允许的群组列表 | - |
| `groups[].requireMention` | boolean | 是否需要 @机器人才回复 | `true` / `false` |
| `groupPolicy` | string | 群组策略 | `allowlist` / `open` / `disabled` |
| `streamMode` | string | 消息流模式 | `partial` / `full` |

### groupPolicy 说明

| 值 | 说明 |
|-----|------|
| `allowlist` | 只响应 `groups` 中配置的群组 |
| `open` | 响应所有群组（测试用，不推荐） |
| `disabled` | 禁用群组功能 |

### requireMention 说明

| 值 | 说明 |
|-----|------|
| `false` | 群内任何消息都会自动回复 |
| `true` | 只有 @机器人 或回复机器人消息时才会回复 |

---

## 常见问题排查

### Q1: 机器人没有回应

**检查日志**：
```bash
tail -30 /tmp/openclaw/openclaw-2026-02-25.log | grep -i "telegram"
```

如果看到 `"reason":"not-allowed"`，说明群组未被允许。

**解决方案**：
1. 确认群组已添加到 `groups` 配置
2. 重启 Gateway：`openclaw gateway restart`

### Q2: Privacy Mode 限制

Telegram 机器人默认开启 Privacy Mode，可能导致无法收到群组消息。

**解决方法**（二选一）：
1. 在 @BotFather 中执行 `/setprivacy`，选择 Disable
2. 在群组设置中把机器人设为**管理员**

### Q3: 群组 ID 格式

Telegram 群组 ID 格式：
- 普通群组：`-100XXXXXXXXX`（超级群组）
- 旧格式群组：`-XXXXXXXXX`

**注意**：OpenClaw 的 `groups` 配置会自动识别这些格式，不需要额外处理。

### Q4: 需要每次 @ 才能回复

检查 `requireMention` 设置：
- `false`: 不需要 @，自动回复
- `true`: 需要 @ 才能回复

---

## 群组迁移说明

Telegram 群组有时会从旧 ID 迁移到新 ID（超级群组升级）。日志中会显示：
```
[telegram] Group migrated: "群名" 旧ID → 新ID
```

**处理方式**：
- 如果旧 ID 已在配置中，需要用新 ID 替换
- 自动迁移信息会记录在日志中

---

## 总结

| 操作 | 命令/步骤 |
|------|----------|
| 查看日志 | `tail -30 /tmp/openclaw/openclaw-2026-02-25.log \| grep -i "telegram"` |
| 添加群组 | `jq '.channels.telegram.groups["群组ID"] = {"requireMention": false}'` |
| 重启服务 | `openclaw gateway restart` |
| 查看配置 | `jq '.channels.telegram.groups' ~/.openclaw/openclaw.json` |
