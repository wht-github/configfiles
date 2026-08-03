# Windows 开发环境

本文档是 agent 或新 Windows 机器的安装与修复契约。请按顺序执行各章节，不要使用
没有由本仓库维护的本地副本替换 profile。

## 使用约定

- 仓库可以放在任意位置，但必须将 `DEV_CONFIG_ROOT` 设置为其绝对路径。
- `GitPredictor` 是必需依赖，也是唯一的 Git prompt/补全集成。
- 不要安装或导入 `posh-git`。
- 不要提交 PowerShell 历史、凭据、API Key、机器路径或构建产物。
- 不要删除已有配置；切换 profile 前先创建备份。

## 1. 检查机器环境

确认 PowerShell 7、Git、WinGet 和 .NET 10 SDK 可用：

```powershell
$PSVersionTable.PSVersion
Get-Command pwsh, git, winget, dotnet
```

查看 `packages/windows-winget.json` 中声明的工具 ID。使用 `Get-Command` 检查命令是否
可发现；仅仅存在于 PATH 中的包目录不够，必须确认对应的可执行文件能被 PowerShell
找到。

## 2. 安装命令行工具

安装 `packages/windows-winget.json` 中 `required` 为 `true` 的所有包，并使用精确的
WinGet ID：

```powershell
winget install --id <PACKAGE_ID> --exact --source winget
```

必需的 CLI 工具包括：

```text
fzf, rg, bat, fd, zoxide, lsd, just, uv, zellij
```

这些预编译 Windows 二进制文件统一以 WinGet 作为标准来源。已有的 Cargo 安装不必
删除，但必须报告重复来源，并确保计划使用的 WinGet 可执行文件在 PATH 中优先。

可选包只在机器确实需要时安装。Rustup 用于 Rust 开发；Podman 用于支持现有容器
工作流。

## 3. 配置 PowerShell

将用户级配置根目录设置为当前仓库：

```powershell
[Environment]::SetEnvironmentVariable('DEV_CONFIG_ROOT', '<absolute configfiles path>', 'User')
```

修改用户环境变量后，请重新启动一个 PowerShell 进程。

将当前 `$PROFILE` 复制为带时间戳的备份，然后用 `pwsh/profile-loader.ps1` 的内容
替换 profile。loader 通过 `DEV_CONFIG_ROOT` 查找仓库，不包含机器专用的 checkout
路径。如果环境变量要到下一个终端进程才可见，loader 会发出 warning 并返回，不会
加载任何替代 Git 集成。

不要导入 `posh-git`。`pwsh/profile.ps1` 使用 `-ErrorAction Stop` 导入 GitPredictor；
如果必需模块缺失，会明确失败。

## 4. 构建并安装 GitPredictor

如果本机已有 GitPredictor checkout，直接使用它；否则将
`packages/gitpredictor.json` 中声明的仓库克隆到当前仓库旁边，或放到
`$HOME/src/GitPredictor`。

```powershell
Set-Location '<GitPredictor checkout>'
just pack-release
$moduleRoot = Join-Path $HOME 'Documents\PowerShell\Modules\GitPredictor\0.1.0'
New-Item -ItemType Directory -Force -Path $moduleRoot | Out-Null
Copy-Item -Recurse -Force -Path '.\module\GitPredictor\*' -Destination $moduleRoot
```

模块目录必须包含 `GitPredictor.psd1`、`GitPredictor.dll`、`GitPrompt.psm1` 和
`Register-GitTabCompletion.ps1`。

如果开发 checkout 尚未安装到用户模块目录，将 `GITPREDICTOR_MODULE_PATH` 设置为
`<checkout>\module\GitPredictor`。

## 5. Visual Studio DevShell

profile 不假设 Visual Studio 的版本、Community edition 或固定盘符。

`Get-VisualStudioInstallation` 按以下顺序发现 Visual Studio：

1. PATH 中的 `vswhere.exe`。
2. `Program Files (x86)` 下的 Visual Studio Installer 目录。
3. `Program Files` 下的 Visual Studio Installer 目录。
4. 在两个 Program Files 根目录下扫描 `Common7\Tools\Launch-VsDevShell.ps1`。

当 `vswhere.exe` 可用时，只选择包含 C++ workload 的安装。普通命令会选择发现到的
第一个安装：

```powershell
vsdevshell
```

查看所有候选安装：

```powershell
vsdevshell -List
```

当同时安装多个版本时，可以显式选择安装路径：

```powershell
vsdevshell -InstallationPath 'C:\Program Files\Microsoft Visual Studio\18\Community'
```

选中的 `Launch-VsDevShell.ps1` 会使用 dot-source 执行，使环境变量变更保留在当前
PowerShell 进程中。

## 6. 验证

打开新的 PowerShell 会话并验证：

```powershell
Get-Command fzf, rg, bat, fd, zoxide, lsd, just, uv, zellij
Get-Module GitPredictor
Get-Command Get-GitSimplePrompt
Get-Command -Syntax vsdevshell
vsdevshell -List
```

在 Git 仓库中验证 prompt 状态和补全：

```powershell
git status
git c<Tab>
git commit -<Tab>
```

如果 GitPredictor 无法导入，请停止并修复模块安装，不要替换成其他 Git 集成。

## 本地覆盖配置

只在需要配置机器专用值时，复制 `pwsh/local.example.ps1` 为 `pwsh/local.ps1`。
该文件已被 Git 忽略。

## Auth Token 和环境变量

需要为 CLI 工具、agent 或容器提供认证信息时，复制：

```powershell
Copy-Item .\pwsh\secrets.example.ps1 .\pwsh\secrets.local.ps1
```

将实际的环境变量写入 `pwsh/secrets.local.ps1`。profile 每次启动时会自动加载该
文件，例如：

```powershell
$env:DEEPSEEK_API_KEY = 'your-token'
$env:ANTHROPIC_AUTH_TOKEN = $env:DEEPSEEK_API_KEY
```

`pwsh/secrets.local.ps1` 已被 Git 忽略，绝不能提交。对于重要 token，优先使用
Windows 用户环境变量、Windows Credential Manager 或 PowerShell SecretManagement；
本地 secrets 文件是明文存储，只适合风险可接受的个人机器。
