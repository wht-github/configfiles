# Personal PowerShell 7 profile.
# GitPredictor is a required dependency. There is deliberately no posh-git fallback.

$script:DevConfigRoot = Split-Path -Parent $PSScriptRoot
$script:IsInteractive = $Host.Name -eq 'ConsoleHost' -and
    -not [Console]::IsInputRedirected -and
    -not [Console]::IsOutputRedirected

# Machine-local settings are loaded first so the tracked defaults below can be
# overridden without putting machine paths or credentials in Git.
$localSettingsPath = Join-Path $PSScriptRoot 'local.ps1'
if (Test-Path -LiteralPath $localSettingsPath) {
    . $localSettingsPath
}

# Authentication values are kept separately from ordinary machine settings.
# This file is ignored by Git and is loaded in every session so CLI tools and
# agent/container commands can read the same environment variables.
$secretsPath = Join-Path $PSScriptRoot 'secrets.local.ps1'
if (Test-Path -LiteralPath $secretsPath) {
    . $secretsPath
}

if ($script:IsInteractive -and $env:ZELLIJ_SESSION_NAME) {
    $zellijThemePath = Join-Path $PSScriptRoot 'zellij-solarized-console.ps1'
    if (Test-Path -LiteralPath $zellijThemePath) {
        . $zellijThemePath
    }
}

if (-not $env:RUSTUP_UPDATE_ROOT) {
    $env:RUSTUP_UPDATE_ROOT = 'https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup'
}
if (-not $env:RUSTUP_DIST_SERVER) {
    $env:RUSTUP_DIST_SERVER = 'https://mirrors.tuna.tsinghua.edu.cn/rustup'
}
$env:BAT_THEME = 'Solarized (light)'

function Resolve-GitPredictorManifest {
    $candidateManifests = @()

    if ($env:GITPREDICTOR_MODULE_PATH) {
        $candidateManifests += Join-Path $env:GITPREDICTOR_MODULE_PATH 'GitPredictor.psd1'
    }

    if ($env:GITPREDICTOR_ROOT) {
        $candidateManifests += Join-Path $env:GITPREDICTOR_ROOT 'module\GitPredictor\GitPredictor.psd1'
    }

    # Keeping the two repositories side by side works on every drive and does
    # not encode D:\Workspace into the profile.
    $siblingGitPredictor = Join-Path (Split-Path -Parent $script:DevConfigRoot) 'GitPredictor'
    $candidateManifests += Join-Path $siblingGitPredictor 'module\GitPredictor\GitPredictor.psd1'

    $candidateManifests += @(
        Join-Path $HOME 'src\GitPredictor\module\GitPredictor\GitPredictor.psd1',
        Join-Path $HOME 'Documents\PowerShell\Modules\GitPredictor\GitPredictor.psd1'
    )

    foreach ($manifest in ($candidateManifests | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $manifest) {
            return (Resolve-Path -LiteralPath $manifest).ProviderPath
        }
    }

    $available = @(
        Get-Module -ListAvailable -Name GitPredictor -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
    )
    if ($available) {
        return $available.Path
    }

    throw @"
GitPredictor is required by this profile but was not found.
Build/install it by following windows.md, or set GITPREDICTOR_MODULE_PATH to its module directory.
The profile intentionally does not load posh-git as a fallback.
"@
}

$gitPredictorManifest = Resolve-GitPredictorManifest
Import-Module $gitPredictorManifest -Force -ErrorAction Stop

if (-not (Get-Command Get-GitSimplePrompt -ErrorAction SilentlyContinue)) {
    throw 'GitPredictor loaded without Get-GitSimplePrompt; the installed module is incomplete.'
}

$ISETheme = @{
    Command                  = '#268BD2'
    Comment                  = '#859900'
    ContinuationPrompt       = '#268BD2'
    Default                  = '#073642'
    Emphasis                 = '#2AA198'
    Error                    = '#DC322F'
    InlinePrediction         = '#93A1A1'
    Keyword                  = '#859900'
    ListPrediction           = '#B58900'
    Member                   = '#586E75'
    Number                   = '#6C71C4'
    Operator                 = '#657B83'
    Parameter                = '#268BD2'
    String                   = '#2AA198'
    Type                     = '#CB4B16'
    Variable                 = '#D33682'
    ListPredictionSelected   = '#073642'
    Selection                = '#93A1A1'
}

function Show-ISEThemeColors {
    Write-Host '=== ISE 主题颜色预览 ===' -ForegroundColor Yellow
    Write-Host ''

    foreach ($item in $ISETheme.GetEnumerator()) {
        Write-Host ('{0,-25}:' -f $item.Key) -NoNewline
        if ($PSStyle) {
            Write-Host ($PSStyle.Foreground.FromRGB($item.Value) + '示例文本' + $PSStyle.Reset)
        }
        else {
            Write-Host '示例文本'
        }
    }

    Write-Host ''
}

function Set-LightThemeColors {
    if (-not $script:IsInteractive) { return }
    Set-PSReadLineOption -Colors $ISETheme
    Write-Host 'Light theme colors applied!' -ForegroundColor Green
}

function Set-HighContrastLightTheme {
    if ($Host.UI.RawUI) {
        $Host.UI.RawUI.BackgroundColor = 'White'
        $Host.UI.RawUI.ForegroundColor = 'Black'
    }
    Set-PSReadLineOption -Colors @{
        Command                  = '#00008B'
        Comment                  = '#006400'
        ContinuationPrompt       = '#00008B'
        Default                  = '#000000'
        Emphasis                 = '#008080'
        Error                    = '#FF0000'
        InlinePrediction         = '#696969'
        Keyword                  = '#800080'
        ListPrediction           = '#B8860B'
        Member                   = '#000000'
        Number                   = '#000000'
        Operator                 = '#000000'
        Parameter                = '#000080'
        String                   = '#8B0000'
        Type                     = '#008080'
        Variable                 = '#A52A2A'
        ListPredictionSelected   = '#000000'
        Selection                = '#ADD8E6'
    }
    Clear-Host
    Write-Host 'High Contrast Light Theme applied!' -ForegroundColor Green
}

if ($script:IsInteractive) {
    Set-PSReadLineOption -EditMode vi
    Set-PSReadLineKeyHandler -Chord 'Tab' -Function MenuComplete
    Set-LightThemeColors

    $psrl = Get-Module PSReadLine
    if ($psrl -and $psrl.Version -ge [version]'2.2.0') {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}

function Start-Admin {
    if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
        Write-Error 'Windows Terminal (wt.exe) 未找到，无法以管理员身份启动'
        return
    }
    Start-Process wt.exe -ArgumentList '-d', (Get-Location).Path -Verb RunAs
}

function Update-Env {
    $paths = @(
        [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        [System.Environment]::GetEnvironmentVariable('Path', 'User')
    ) -split ';' | Where-Object { $_ } | Select-Object -Unique
    $Env:PATH = $paths -join ';'
}

function Get-VisualStudioInstallation {
    [CmdletBinding()]
    param(
        [switch]$All
    )

    $vswhereCandidates = @(
        (Get-Command vswhere.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    $records = @()
    $vswhere = $vswhereCandidates | Select-Object -First 1
    if ($vswhere) {
        $paths = & $vswhere -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format value -property installationPath 2>$null
        foreach ($path in $paths) {
            if ($path) {
                $records += [pscustomobject]@{
                    InstallationPath = $path
                    LaunchScript = Join-Path $path 'Common7\Tools\Launch-VsDevShell.ps1'
                    Discovery = 'vswhere'
                }
            }
        }
    }

    # vswhere is the preferred discovery mechanism. The filesystem scan keeps
    # this usable on machines where Visual Studio Installer is not on PATH.
    $roots = @(
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $launchScript = Join-Path $_.FullName 'Common7\Tools\Launch-VsDevShell.ps1'
                if (Test-Path -LiteralPath $launchScript) {
                    $records += [pscustomobject]@{
                        InstallationPath = $_.FullName
                        LaunchScript = $launchScript
                        Discovery = 'filesystem'
                    }
                }
            }
        }
    }

    $records = @(
        $records |
            Where-Object { Test-Path -LiteralPath $_.LaunchScript } |
            Sort-Object InstallationPath -Unique
    )

    if ($All) {
        return $records
    }

    return $records | Select-Object -First 1
}

function vsdevshell {
    [CmdletBinding()]
    param(
        [string]$InstallationPath,
        [switch]$List
    )

    if ($List) {
        Get-VisualStudioInstallation -All
        return
    }

    $installation = if ($InstallationPath) {
        $launchScript = Join-Path $InstallationPath 'Common7\Tools\Launch-VsDevShell.ps1'
        if (-not (Test-Path -LiteralPath $launchScript)) {
            throw "Visual Studio DevShell not found under: $InstallationPath"
        }
        [pscustomobject]@{ InstallationPath = $InstallationPath; LaunchScript = $launchScript }
    }
    else {
        Get-VisualStudioInstallation
    }

    if (-not $installation) {
        throw 'No Visual Studio installation with a C++ DevShell was found. Run vsdevshell -List to inspect discovery.'
    }

    . $installation.LaunchScript -SkipAutomaticLocation
}

function Get-PrettyPath {
    param([string]$Path)
    if (-not $Path) { $Path = (Get-Location).Path }
    if ($Path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
        return '~' + $Path.Substring($HOME.Length)
    }
    return $Path
}

function prompt {
    $lastNative = $global:LASTEXITCODE
    $lastPsOk = $?

    $fgPath = $PSStyle.Foreground.FromRGB('#268BD2')
    $fgIcon = $PSStyle.Foreground.BrightBlue
    $fgTime = $PSStyle.Foreground.FromRGB('#586E75')
    $fgOk = $PSStyle.Foreground.BrightGreen
    $fgErr = $PSStyle.Foreground.BrightRed
    $reset = $PSStyle.Reset

    $icon = '📁'
    $path = Get-PrettyPath (Get-Location).Path
    $time = (Get-Date).ToString('HH:mm:ss')

    Write-Host "$fgIcon$icon $fgPath$path$reset" -NoNewline
    $saved = $global:LASTEXITCODE
    $gitStatus = Get-GitSimplePrompt
    $global:LASTEXITCODE = $saved
    Write-Host "$gitStatus $fgTime$time$reset"

    $ok = $lastPsOk -and (($null -eq $lastNative) -or ($lastNative -eq 0))
    $glyphColor = if ($ok) { $fgOk } else { $fgErr }
    return "$glyphColor❯$reset "
}

function lsd {
    lsd.exe --icon-theme=unicode @Args
}
Set-Alias -Name 'ls' -Value lsd
Set-Alias -Name 'wt-admin' -Value Start-Admin
Set-Alias -Name 'refreshenv' -Value Update-Env

function Get-Full-History {
    param([int]$Tail = 0)
    $option = Get-PSReadLineOption -ErrorAction SilentlyContinue
    if ($option -and $option.HistorySavePath) {
        if ($Tail -gt 0) {
            Get-Content $option.HistorySavePath -Tail $Tail
        }
        else {
            Get-Content $option.HistorySavePath
        }
    }
}
Set-Alias -Name 'history' -Value Get-Full-History
Set-Alias -Name 'h' -Value Get-Full-History

if ($script:IsInteractive -and (Get-Command zoxide -ErrorAction SilentlyContinue)) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
