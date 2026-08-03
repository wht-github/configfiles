# 个人开发配置

这个仓库是个人 Windows 开发环境配置的唯一来源。

Windows 环境的部署流程记录在 [windows.md](windows.md) 中。文档会根据明确的包
标识安装工具、部署 PowerShell profile，并从经过 SHA-256 校验的
[GitPredictor](https://github.com/wht-github/GitPredictor/releases) GitHub Release
安装必需的 PowerShell 模块。

profile 会直接使用 GitPredictor，不会加载或 fallback 到 posh-git。如果没有安装
GitPredictor，profile 会报告所需的安装位置并停止加载。

机器专用的配置应放在 `pwsh/local.ps1` 中，该文件已被 Git 忽略。如果某台机器需要
本地覆盖配置，可以从 `pwsh/local.example.ps1` 开始创建。
