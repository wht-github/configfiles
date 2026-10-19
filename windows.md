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

## 4. 从 PowerShell Gallery 安装 GitPredictor

安装 `packages/gitpredictor.json` 声明的 `GitPredictor` 模块在 PowerShell
Gallery（PSGallery）上的最新正式版。清单不固定版本号；安装脚本会匿名查询
Gallery 的公开 OData feed 解析最新正式版本，下载对应的 nupkg 后验证模块清单
版本与必需文件，再安装到版本化的用户模块目录；不需要 Gallery 账号、API key、
GitPredictor checkout 或本地 .NET 构建环境。

```powershell
pwsh -NoLogo -NoProfile -File .\packages\Install-GitPredictor.ps1
```

模块目录必须包含 `GitPredictor.psd1`、`GitPredictor.dll`、`GitPrompt.psm1` 和
`Register-GitTabCompletion.ps1`，并由模块导出 `Get-GitSimplePrompt`。

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

## 6. Windows Terminal

Windows Terminal 是主终端。其 settings.json 不由仓库维护，但部署新机器时按以下
契约设置（设置 -> 默认值 -> 外观，或直接编辑 settings.json）：

- 应用主题 `theme`：`light`
- 配色方案 `colorScheme`：内置 `Solarized Light`

这与 profile 调色板（`pwsh/profile.ps1` 的 `$Theme`）、bat 主题
（`Solarized (light)`）和 zellij 面板色表（`pwsh/zellij-solarized-console.ps1`）
保持同一套 Solarized Light 色板。

## 7. 验证

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

## API Token 和环境变量

API token 由用户自行配置为环境变量。仓库不保存 token，profile 也不再读取 token
配置文件或向会话注入认证变量；CLI 工具、agent 和容器直接读取用户环境中已有的变量。

需要认证信息时，在仓库之外设置用户级环境变量，然后重新启动终端：

```powershell
[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', '<your-token>', 'User')
```

Linux 上写入 shell 登录配置：

```bash
printf '\nexport DEEPSEEK_API_KEY="%s"\n' '<your-token>' >> ~/.profile
```

需要其他变量名时（例如 `ANTHROPIC_AUTH_TOKEN`），同样由用户在系统环境变量或
shell 登录配置中自行设置。token 应保存在环境变量或凭据管理器（Windows
Credential Manager、PowerShell SecretManagement）中，不要写入仓库、
`pwsh/local.ps1` 或 PowerShell profile。
