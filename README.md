# 个人开发配置

这个仓库是个人 Windows 开发环境配置的唯一来源。

Windows 环境的部署流程记录在 [windows.md](windows.md) 中。文档会根据明确的包
标识安装工具、部署 PowerShell profile，并从 PowerShell Gallery 安装必需的
[GitPredictor](https://www.powershellgallery.com/packages/GitPredictor) 模块
（版本不固定，默认取最新正式版）。

profile 会直接使用 GitPredictor，不会加载或 fallback 到 posh-git。如果没有安装
GitPredictor，profile 会报告所需的安装位置并停止加载。

Alacritty 终端配置（默认 pwsh + Solarized Light）由
[alacritty/alacritty.toml](alacritty/alacritty.toml) 维护，部署方式见
[windows.md](windows.md)。

Codex 的 DeepSeek profile（Windows / Linux 通用）由
[codex/](codex/README.md) 维护，安装与使用方式见
[codex/README.md](codex/README.md)。

机器专用的配置应放在 `pwsh/local.ps1` 中，该文件已被 Git 忽略。如果某台机器需要
本地覆盖配置，可以从 `pwsh/local.example.ps1` 开始创建。

Linux（bash）环境配置由 [linux/](linux/README.md) 维护，部署到 `~/.bashrc.d/`。

API token 等认证信息不写入仓库，也不提供 token 文件；用户自行在系统环境变量
（Windows）或 shell 登录配置（Linux）中设置，工具直接从环境变量读取。
