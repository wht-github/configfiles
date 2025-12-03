$env:RUSTUP_UPDATE_ROOT="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
$env:RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"
Import-Module posh-git # 引入 posh-git
$env:BAT_THEME = "Solarized (light)"
# Import-Module "D:\Workspace\GitPredictor\module\GitPredictor\GitPredictor.psd1"
Set-PSReadlineOption -EditMode vi
Set-PSReadLineKeyHandler -Chord 'Tab' -Function MenuComplete
# Syntax highlighting colors
$ISETheme = @{
    Command                  = "#268BD2"   # 柔和蓝
    Comment                  = "#859900"   # 柔和绿
    ContinuationPrompt       = "#268BD2"   # 柔和蓝
    Default                  = "#073642"   # 深蓝灰（文本默认色）
    Emphasis                 = "#2AA198"   # 青绿色
    Error                    = "#DC322F"   # 柔和红
    InlinePrediction         = "#93A1A1"   # 灰色
    Keyword                  = "#859900"   # 柔和黄绿色
    ListPrediction           = "#B58900"   # 金色 / 提示色
    Member                   = "#586E75"   # 深灰蓝
    Number                   = "#6C71C4"   # 紫色
    Operator                 = "#657B83"   # 灰色
    Parameter                = "#268BD2"   # 柔和蓝
    String                   = "#2AA198"   # 青绿色
    Type                     = "#CB4B16"   # 橙色
    Variable                 = "#D33682"   # 柔和粉紫
    ListPredictionSelected   = "#073642"   # 深蓝灰
    Selection                = "#93A1A1"   # 灰色背景选中
}

function Show-ISEThemeColors {
    
    Write-Host "=== ISE 主题颜色预览 ===" -ForegroundColor Yellow
    Write-Host ""

    foreach ($item in $ISETheme.GetEnumerator()) {
        # 输出元素名称
        Write-Host ("{0,-25}:" -f $item.Key) -NoNewline

        # 使用 RGB ANSI 转义显示前景色
        Write-Host ($PSStyle.Foreground.FromRGB($item.Value) + "示例文本" + $PSStyle.Reset)
    }

    Write-Host ""
}

function Set-LightThemeColors {
    # Set PSReadLine colors for light background
    Set-PSReadLineOption -Colors $ISETheme   
    # Set prediction colors
    
    
    Write-Host "Light theme colors applied!" -ForegroundColor Green
}
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
# Apply light theme colors
Set-LightThemeColors

function Start-Admin {
    Start-Process wt "-d $(Get-Location)" -Verb RunAs
}
function Update-Env {
    $Env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
function vsdevshell {
    & 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation
}
# 把 $HOME 压缩为 ~
function Get-PrettyPath {
    param([string]$Path)
    if (-not $Path) { $Path = (Get-Location).Path }
    if ($Path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
        return "~" + $Path.Substring($HOME.Length)
    }
    return $Path
}

function prompt {
    # 缓存上条命令状态，避免 Write-Host 影响 $? / $LASTEXITCODE
    $lastNative = $global:LASTEXITCODE
    $lastPsOk   = $?

    $fgPath  = $PSStyle.Foreground.BrightCyan
    $fgIcon  = $PSStyle.Foreground.BrightBlue
    $fgTime  = $PSStyle.Foreground.BrightBlack
    $fgOk    = $PSStyle.Foreground.BrightGreen
    $fgErr   = $PSStyle.Foreground.BrightRed
    $fgDim   = $PSStyle.Foreground.BrightBlack
    $reset   = $PSStyle.Reset

    $icon = "📁"  # 也可换成 Nerd Font 图标
    $path = Get-PrettyPath (Get-Location).Path
    $time = (Get-Date).ToString("HH:mm:ss")

    # 第一行：路径 + posh-git 状态 + 时间（不做对齐计算）
    Write-Host "$fgIcon$icon $fgPath$path$reset" -NoNewline
    $saved = $global:LASTEXITCODE
    # $posh_git = $(Get-GitSimplePrompt)
    $posh_git = Write-VcsStatus
    $global:LASTEXITCODE = $saved
    Write-Host "$posh_git $fgTime$time$reset"

    # 第二行：根据上一条命令状态变色
    $ok = $lastPsOk -and (($null -eq $lastNative) -or ($lastNative -eq 0))
    $glyphColor = if ($ok) { $fgOk } else { $fgErr }
    return "$glyphColor❯$reset "
}

function lsd {
    lsd.exe --icon-theme=unicode @Args   
}
Set-Alias -Name "ls" -Value lsd

Set-Alias -Name "wt-admin" -Value Start-Admin
Set-Alias -Name "refreshenv" -Value Update-Env
Invoke-Expression (& { (zoxide init powershell | Out-String) })

