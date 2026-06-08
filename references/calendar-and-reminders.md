# Google Calendar 与主动提醒

## Google Calendar 的定位

Google Calendar 只负责把用户已确认的训练计划放进真实日程。

真实训练状态仍写在 Running Coach 工作区：

```text
~/.openclaw/workspace-running-coach
```

## 接入 Google Calendar

优先使用配套 skill：

```text
running-coach-google-calendar-setup
```

对 Running Coach 发送：

```text
请使用 running-coach-google-calendar-setup 技能，中文引导我完成 Google Calendar 接入。
```

配置成功后应记录到：

```text
data/integrations/google-calendar.md
```

## 写入日历前的确认规则

计划状态：

| 状态 | 含义 | 是否写入日历 | 是否主动提醒 |
|---|---|---:|---:|
| `draft` | 教练草稿 | 否 | 否 |
| `pending_confirmation` | 等待用户确认 | 否 | 否 |
| `confirmed` | 用户已确认 | 是 | 是 |
| `active` | 正在执行周期 | 是 | 是 |
| `completed` | 已完成 | 保留 | 否 |
| `completed_downgraded` | 降级完成 | 保留 | 否 |
| `skipped` | 跳过 | 保留 | 否 |
| `rescheduled` | 改期 | 更新 | 视新状态 |
| `cancelled_*` | 取消 | 取消或更新 | 否 |

## 主动提醒配置

优先使用配套 skill：

```text
running-coach-reminder-tone
```

对 Running Coach 发送：

```text
请使用 running-coach-reminder-tone 技能，为我的 Running Coach 安装人类教练式主动提醒规则。
```

主动提醒配置入口：

```text
data/reminders/reminder-settings.md
data/reminders/reminder-log.md
```

## cron 设计原则

不要为每次训练创建单独 cron。

长期 cron 只做一件事：

```text
定时扫描 current-week-plan.md 和 4-week-plan.md，发现已确认且进入提醒窗口的训练，再发送微信/Telegram提醒。
```

提醒前必须检查 `reminder-log.md`，避免同一训练重复提醒。

## 推荐提醒内容

每条提醒尽量包含：

- 今天训练内容。
- 训练目的。
- 强度边界。
- 降级方案。
- 安全边界。
- 跑后打卡问题。

