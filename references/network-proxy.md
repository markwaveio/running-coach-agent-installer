# 网络代理与 Channel 连通性

## 为什么要先处理网络

Running Coach 安装会依赖多个外部服务：

- 微信 / Telegram / 飞书 / Discord 等聊天 channel。
- Google Calendar OAuth。
- GitHub 拉取 skill。
- OpenAI / Claude / Gemini / OpenRouter / ZenMux 等模型 API。

如果学员网络不能稳定访问这些服务，表现会是：

- channel 绑定失败。
- 模型授权卡住。
- Google Calendar 登录或回调失败。
- OpenClaw gateway 日志里出现 TLS、socket disconnect、timeout。

## 核心坑

只在终端里执行：

```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
```

通常不够。

原因是 OpenClaw gateway 是后台 Node 进程，未必继承当前终端环境。必须让 gateway 运行时也获得代理环境，或把代理写入 OpenClaw channel 配置。

## 首选脚本

运行：

```bash
bash scripts/network-proxy-preflight.sh
```

脚本会：

1. 自动检测常见本地代理端口。
2. 测试 GitHub、Google、Feishu、模型 API 等外部服务连通性。
3. 询问是否写入代理。
4. 写入 `~/.openclaw/openclaw.json`：
   - `network.proxy`
   - `channels.*.proxy`
   - `channels.*.accounts.*.proxy`
5. 写入 gateway 环境文件：
   - `HTTP_PROXY`
   - `HTTPS_PROXY`
   - `ALL_PROXY`
   - `NO_PROXY`
6. 记录到：

```text
~/.openclaw/workspace-running-coach/data/integrations/network-proxy.md
```

## 手动指定代理

如果用户知道自己的代理地址：

```bash
RUNNING_COACH_PROXY_URL="http://127.0.0.1:7890" bash scripts/network-proxy-preflight.sh
```

## 跳过代理预检查

如果用户确定网络正常：

```bash
RUNNING_COACH_SKIP_NETWORK_PREFLIGHT=1 bash scripts/install-running-coach-agent.sh
```

## 配置后验证

```bash
openclaw status --all
openclaw channels status --probe
openclaw models status
```

如果 channel 仍失败，优先检查代理软件是否正在运行、端口是否变化、系统防火墙是否拦截。

