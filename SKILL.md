---
name: running-coach-agent-installer
description: 中文一键部署 OpenClaw Running Coach 个人跑步教练 Agent；创建/修复 agent、初始化工作区文件、配置强模型、防微信自循环、引导绑定聊天 channel、Google Calendar、主动提醒、数据目录和验收测试。
---

# Running Coach Agent Installer

用于把 Running Coach 个人跑步教练 Agent 交付给学员，并用中文一步步引导完成安装、配置和验收。

触发场景：

- 用户要“一键部署 Running Coach / 跑步教练 Agent”。
- 用户要把 Running Coach 交付给学员安装。
- 用户要创建 OpenClaw agent、绑定微信/Telegram/飞书等聊天工具。
- 用户要配置模型、Google Calendar、主动提醒、训练数据目录和长期记忆。
- 用户要排查 Running Coach 不回复、乱回、提醒不触发、模型不聪明等问题。

## 快速执行

优先运行安装脚本：

```bash
bash scripts/install-running-coach-agent.sh
```

脚本会做这些事：

1. 检查 `openclaw` 是否可用。
2. 先做网络与代理预检查：检测本机代理、测试外部服务连通性，并可把代理写入 OpenClaw 配置和 gateway 环境。
3. 创建或修复 `running-coach` agent。
4. 初始化工作区：

```text
~/.openclaw/workspace-running-coach
```

5. 写入核心文件：`BOOTSTRAP.md`、`SOUL.md`、`IDENTITY.md`、`AGENTS.md`、`USER.md`、`TOOLS.md`、`HEARTBEAT.md`。
6. 创建数据目录：`data/raw`、`data/processed`、`data/plans`、`data/checkins`、`data/reviews`、`data/reminders`、`data/integrations`、`memory`。
7. 读取用户本机 OpenClaw 已配置模型，让用户显式选择 Running Coach 使用的模型；如果没有合适模型，会引导用户先配置/授权新模型；不会使用作者本机默认模型，也不会静默继承全局默认模型。

8. 给 agent 加硬规则，禁止 `sessions_send` / `sessions_spawn`，避免聊天工具自循环。
9. 写入计划确认规则：只有用户确认后的 `confirmed` / `active` 计划才允许同步日历和触发提醒。
10. 输出下一步：channel 绑定、Google Calendar、主动提醒、验收测试。

## 必须讲清楚的核心规则

安装和教学时必须强调：

- Running Coach 的运行时数据目录是 `~/.openclaw/workspace-running-coach`，不是项目开发目录。
- 网络不通时先修代理，再配置 channel、模型和 Google Calendar。只在终端 export 代理不够，必须让 OpenClaw gateway 进程也拿到代理环境。
- 安装时必须让用户选择本机可用模型；如果没有合适模型，先用 `openclaw models auth add` 引导用户配置/授权新模型，再继续部署。
- 便宜模型适合测试；正式长期教练建议使用 Claude / GPT / Gemini 等高阶模型。
- 普通聊天回复不要使用 `sessions_send current`，否则会把回复发回同一个 session，造成“模型自己回复自己”。
- 计划草稿不触发提醒。只有用户确认后的 `confirmed` / `active` 计划才同步 Google Calendar 和主动提醒。
- Google Calendar 只负责日程事件；训练计划、执行状态、打卡、复盘和长期画像仍以 Running Coach 工作区文件为准。
- 主动提醒 cron 只扫描已确认计划，不为每个训练单独创建 cron。
- 长期记忆只写入已确认规律，不把单次异常当长期偏好。

## 安装后的推荐验证

让学员在聊天工具中发送：

```text
我们开始首次建档。请按照 BOOTSTRAP.md 的流程逐项询问我，并把确认后的信息写入用户档案和长期训练画像。
```

再测试：

```text
请告诉我你的运行时数据根目录，以及当前周训练计划、长期画像和最近复盘分别存放在哪里。
```

计划确认测试：

```text
这是我下周的真实日程：周二早上 45 分钟，周四晚上 60 分钟，周六上午适合长距离。请生成下周训练计划草稿，不要同步日历，等我确认。
```

确认后再发送：

```text
我确认这份计划。请保存为当前周计划，并同步到日程提醒。
```

## 需要时读取的参考文件

- Google Calendar 和主动提醒配置细节：`references/calendar-and-reminders.md`
- 网络代理和 channel 连通性：`references/network-proxy.md`
- 故障排查和我们踩过的坑：`references/troubleshooting.md`
