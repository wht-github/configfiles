# Dev Box Docker 容器

基于 Debian Trixie Slim 镜像。

## 1. 设置清华 Debian 软件源

> apt install apt-transport-https ca-certificates

```bash
echo "Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: http://mirrors.tuna.tsinghua.edu.cn/debian
# Suites: trixie trixie-updates trixie-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: https://security.debian.org/debian-security
# Suites: trixie-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" > /etc/apt/sources.list.d/debian.sources
```

> apt update && apt upgrade -y

## 2. 安装常用工具

> apt-get install -y vim git curl build-essential iproute2
> curl -LsSf https://astral.sh/uv/install.sh | sh

```bash
echo "[[index]]
url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/"
default = true" > ~/.config/uv/uv.toml
```

> curl -O https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb
> dpkg -i packages-microsoft-prod.deb
> rm packages-microsoft-prod.deb
> apt-get update && apt-get install -y dotnet-sdk-10.0

> uv python install 3.12
> uv tool install auto-coder --python 3.12

## 3. 安装 Claude Code 并配置环境变量

```bash
curl -fsSL https://claude.ai/install.sh | bash

export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=${DEEPSEEK_API_KEY}
export API_TIMEOUT_MS=600000
export ANTHROPIC_MODEL="deepseek-reasoner"                # 自定义模型名称
export ANTHROPIC_SMALL_FAST_MODEL="deepseek-chat"         # 快速小模型
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export ANTHROPIC_MODEL="deepseek-reasoner"                # 自定义模型名称
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-reasoner" # 默认 Sonnet 模型别名
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-reasoner"   # 默认 Opus 模型别名
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-reasoner"   # 默认 Opus 模型别名
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-chat"      # 默认 Haiku 模型别名
export TERM=xterm-256color
export COLORTERM=truecolor
```
