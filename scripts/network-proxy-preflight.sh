#!/usr/bin/env bash
set -euo pipefail

CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
WORKSPACE="${RUNNING_COACH_WORKSPACE:-$HOME/.openclaw/workspace-running-coach}"
SERVICE_ENV="${OPENCLAW_GATEWAY_ENV:-$HOME/.openclaw/service-env/ai.openclaw.gateway.env}"
PROXY_URL="${RUNNING_COACH_PROXY_URL:-}"

say() { printf "\n\033[1;36m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m%s\033[0m\n" "$*"; }
die() { printf "\n\033[1;31m%s\033[0m\n" "$*" >&2; exit 1; }

[ -f "$CONFIG" ] || die "找不到 OpenClaw 配置：$CONFIG"
command -v node >/dev/null 2>&1 || die "未找到 node，无法执行网络代理配置。"

detect_proxy() {
  node <<'NODE'
const net = require("net");
const ports = [7890, 7897, 7899, 1087, 1080, 20171, 6152];
function check(port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: "127.0.0.1", port, timeout: 350 });
    socket.on("connect", () => { socket.destroy(); resolve(port); });
    socket.on("timeout", () => { socket.destroy(); resolve(null); });
    socket.on("error", () => resolve(null));
  });
}
(async () => {
  for (const port of ports) {
    const ok = await check(port);
    if (ok) {
      console.log(`http://127.0.0.1:${ok}`);
      return;
    }
  }
})();
NODE
}

test_urls() {
  local proxy="$1"
  if ! command -v curl >/dev/null 2>&1; then
    warn "未找到 curl，跳过外网连通性测试。"
    return 0
  fi

  say "网络连通性测试"
  local urls=(
    "https://api.openai.com/v1/models"
    "https://generativelanguage.googleapis.com"
    "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
    "https://api.github.com"
  )
  for url in "${urls[@]}"; do
    printf "直连测试 %-62s " "$url"
    if curl -I -L --connect-timeout 4 --max-time 8 -sS "$url" >/dev/null 2>&1; then
      printf "OK\n"
    else
      printf "失败/超时\n"
    fi
    if [ -n "$proxy" ]; then
      printf "代理测试 %-62s " "$url"
      if curl -I -L --proxy "$proxy" --connect-timeout 4 --max-time 8 -sS "$url" >/dev/null 2>&1; then
        printf "OK\n"
      else
        printf "失败/超时\n"
      fi
    fi
  done
}

write_proxy_config() {
  local proxy="$1"
  local no_proxy="localhost,127.0.0.1,::1,0.0.0.0,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,.local"
  local backup="${CONFIG}.pre-running-coach-proxy-$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG" "$backup"
  printf "已备份 OpenClaw 配置：%s\n" "$backup"

  node <<NODE
const fs = require("fs");
const path = "$CONFIG";
const proxy = "$proxy";
const noProxy = "$no_proxy";
const json = JSON.parse(fs.readFileSync(path, "utf8"));
json.network ||= {};
json.network.proxy = proxy;
json.network.noProxy = noProxy;
json.channels ||= {};
for (const channel of Object.values(json.channels)) {
  if (!channel || typeof channel !== "object") continue;
  channel.proxy = proxy;
  channel.network ||= {};
  channel.network.autoSelectFamily = false;
  if (channel.accounts && typeof channel.accounts === "object") {
    for (const account of Object.values(channel.accounts)) {
      if (!account || typeof account !== "object") continue;
      account.proxy = proxy;
      account.network ||= {};
      account.network.autoSelectFamily = false;
    }
  }
}
fs.writeFileSync(path, JSON.stringify(json, null, 2) + "\\n");
console.log(JSON.stringify({ network: json.network }, null, 2));
NODE

  mkdir -p "$(dirname "$SERVICE_ENV")"
  touch "$SERVICE_ENV"
  local env_backup="${SERVICE_ENV}.pre-running-coach-proxy-$(date +%Y%m%d-%H%M%S)"
  cp "$SERVICE_ENV" "$env_backup"
  printf "已备份 Gateway 环境文件：%s\n" "$env_backup"

  node <<NODE
const fs = require("fs");
const path = "$SERVICE_ENV";
const proxy = "$proxy";
const noProxy = "$no_proxy";
let text = fs.existsSync(path) ? fs.readFileSync(path, "utf8") : "";
text = text.replace(/\\n?# BEGIN RUNNING_COACH_PROXY[\\s\\S]*?# END RUNNING_COACH_PROXY\\n?/g, "\\n");
const block = [
  "# BEGIN RUNNING_COACH_PROXY",
  "export HTTP_PROXY='" + proxy + "'",
  "export HTTPS_PROXY='" + proxy + "'",
  "export ALL_PROXY='" + proxy + "'",
  "export http_proxy='" + proxy + "'",
  "export https_proxy='" + proxy + "'",
  "export all_proxy='" + proxy + "'",
  "export NO_PROXY='" + noProxy + "'",
  "export no_proxy='" + noProxy + "'",
  "# END RUNNING_COACH_PROXY",
  ""
].join("\\n");
fs.writeFileSync(path, text.trimEnd() + "\\n" + block);
NODE

  mkdir -p "$WORKSPACE/data/integrations"
  cat > "$WORKSPACE/data/integrations/network-proxy.md" <<EOF
# Running Coach 网络代理配置

更新时间：$(date '+%Y-%m-%d %H:%M:%S')

## 当前代理

\`\`\`text
$proxy
\`\`\`

## 已写入位置

- OpenClaw 配置：$CONFIG
- Gateway 环境文件：$SERVICE_ENV

## 作用

- OpenClaw gateway Node 进程
- 聊天 channel 网络请求
- 模型授权和外部 API 访问
- Google Calendar / GitHub / Feishu 等外部服务

## 注意

如果更换代理端口，请重新运行：

\`\`\`bash
RUNNING_COACH_PROXY_URL="http://127.0.0.1:7890" bash scripts/network-proxy-preflight.sh
\`\`\`

配置后需要重启 OpenClaw gateway。
EOF
}

say "网络与代理预检查"
cat <<'EOF'
如果学员所在网络无法直连 Telegram、Google、GitHub、模型 API，channel 绑定、模型授权、Google Calendar 都可能失败。
这个步骤会检测本机代理，并可把代理写入 OpenClaw 配置和 gateway 环境，避免“终端有代理但 OpenClaw gateway 没有代理”的问题。
EOF

detected="$(detect_proxy || true)"
if [ -n "$PROXY_URL" ]; then
  printf "使用环境变量指定代理：%s\n" "$PROXY_URL"
elif [ -n "$detected" ]; then
  printf "检测到本地代理：%s\n" "$detected"
  printf "是否将它写入 OpenClaw 和 gateway 环境？[Y/n/manual/skip] "
  read -r answer
  case "${answer:-Y}" in
    Y|y|yes|YES|"") PROXY_URL="$detected" ;;
    manual|m|M)
      printf "请输入代理 URL，例如 http://127.0.0.1:7890："
      read -r PROXY_URL
      ;;
    skip|s|S|n|N|no|NO)
      PROXY_URL=""
      ;;
    *)
      PROXY_URL="$detected"
      ;;
  esac
else
  warn "未自动检测到常见本地代理端口。"
  printf "是否手动输入代理 URL？[y/N] "
  read -r answer
  case "${answer:-N}" in
    y|Y|yes|YES)
      printf "请输入代理 URL，例如 http://127.0.0.1:7890："
      read -r PROXY_URL
      ;;
    *) PROXY_URL="" ;;
  esac
fi

test_urls "$PROXY_URL"

if [ -n "$PROXY_URL" ]; then
  write_proxy_config "$PROXY_URL"
  say "代理配置已写入。稍后安装脚本会重启 OpenClaw gateway。"
else
  warn "已跳过代理写入。如果后续 channel 或模型授权失败，请重新运行本脚本并配置代理。"
fi

