# Running Coach 故障排查

## 模型不够聪明

症状：

- 回复空泛。
- 不会追问。
- 计划不理解用户真实日程。
- 复盘像流水账。

处理：

1. 检查 `~/.openclaw/openclaw.json` 中 `running-coach` 是否单独配置模型。
2. 不要静默继承全局默认模型。安装脚本会读取用户本机可用模型并要求用户选择。
3. 如果本机没有合适模型，先配置 Claude / GPT / Gemini 等高阶模型，再运行安装脚本。
4. 常见高阶模型示例：

```text
zenmux/anthropic/claude-sonnet-4.6
openai/gpt-5.4
zenmux/openai/gpt-5.4
zenmux/google/gemini-3.1-pro-preview
```

5. 修改后重启 gateway。

## 安装时没有合适模型

处理：

1. 先在 OpenClaw 里配置新的模型 provider 或 API key。
2. 确认 `~/.openclaw/openclaw.json` 的 `models.providers` 下能看到新模型。
3. 重新运行安装脚本。
4. 也可以用环境变量显式指定模型：

```bash
RUNNING_COACH_MODEL="provider/model-id" bash scripts/install-running-coach-agent.sh
```

## 微信或聊天工具收不到回复

高优先级排查：

- 是否 channel 已绑定到 `running-coach`。
- OpenClaw gateway 是否在线。
- 微信/Telegram/飞书 channel 是否 OK。
- 是否出现 `sessions_send current` 自循环。

防自循环硬规则：

```json
{
  "tools": {
    "deny": ["sessions_send", "sessions_spawn"]
  }
}
```

如果 session 已被污染，备份并隔离对应 direct session，让下一条用户消息重建干净会话。

## 提醒不触发

先检查：

- 计划是否是 `confirmed` 或 `active`。
- 是否已经同步 Google Calendar。
- 是否有 `calendar_event_id`。
- 当前时间是否进入提醒窗口。
- `reminder-log.md` 是否已有同一训练提醒记录。
- cron 是否启用。

常用命令：

```bash
openclaw cron list --json
openclaw cron show "Running Coach pre-training reminder scanner"
openclaw cron runs --id <job-id>
```

## 日历没有更新

先检查：

- Google Calendar OAuth 是否完成。
- 用户是否明确确认计划。
- `gog auth list` 是否能看到账号。
- 是否写入正确 calendar。
- 是否把 `calendar_event_id` 回填到计划文件。

## 数据写错目录

正确运行时目录：

```text
~/.openclaw/workspace-running-coach
```

开发项目目录只用于维护模板、课件、脚本和方法论，不作为学员运行时数据目录。

## 记忆越来越乱

规则：

- 单次异常不要写长期记忆。
- 候选规律先写 `memory/review-candidates.md`。
- 用户确认后再写 `memory/runner-profile.md`。
- 周/月复盘只保存摘要到长期画像，不保存所有原始细节。
