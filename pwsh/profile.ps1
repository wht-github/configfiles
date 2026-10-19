# Personal PowerShell 7 profile.
# GitPredictor is a required dependency. There is deliberately no posh-git fallback.

$script:DevConfigRoot = Split-Path -Parent $PSScriptRoot
$script:IsInteractive = $Host.Name -eq 'ConsoleHost' -and
    -not [Console]::IsInputRedirected -and
    -not [Console]::IsOutputRedirected

# Optional per-section load timing: set PROFILE_TRACE to a report file path in
# a fresh session to append a section breakdown (zero cost when unset).
$script:TraceEnabled = -not [string]::IsNullOrWhiteSpace($env:PROFILE_TRACE)
$script:TraceMarks = [System.Collections.Generic.List[object]]::new()
$script:TraceSw = [System.Diagnostics.Stopwatch]::StartNew()
function Trace-ProfileMark {
    param([Parameter(Mandatory)][string]$Label)
    if (-not $script:TraceEnabled) { return }
    $script:TraceSw.Stop()
    $script:TraceMarks.Add([pscustomobject]@{
        Label = $Label
        Ms    = [math]::Round($script:TraceSw.Elapsed.TotalMilliseconds, 1)
    })
    $script:TraceSw.Restart()
}

# Machine-local settings are loaded first so the tracked defaults below can be
# overridden without putting machine paths or credentials in Git.
$localSettingsPath = Join-Path $PSScriptRoot 'local.ps1'
if (Test-Path -LiteralPath $localSettingsPath) {
    . $localSettingsPath
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
Trace-ProfileMark 'local+zellij+env'

function Resolve-GitPredictorManifest {
    $packagePath = Join-Path $script:DevConfigRoot 'packages\gitpredictor.json'
    $package = Get-Content -LiteralPath $packagePath -Raw | ConvertFrom-Json
    $installer = Join-Path $script:DevConfigRoot ([string]$package.installScript)
    $installRoot = [Environment]::ExpandEnvironmentVariables([string]$package.installRoot)

    # No version is pinned in the manifest; load the highest installed version.
    $versionedDir = @(Get-ChildItem -LiteralPath $installRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Name } -Descending |
            Select-Object -First 1)

    if ($versionedDir) {
        $manifest = Join-Path $versionedDir.FullName 'GitPredictor.psd1'
        if (Test-Path -LiteralPath $manifest -PathType Leaf) {
            return (Resolve-Path -LiteralPath $manifest).ProviderPath
        }
    }

    throw @"
GitPredictor is required by this profile but no Gallery version is installed under:
$installRoot
Install the latest PowerShell Gallery release by running: pwsh -File "$installer"
The profile intentionally does not load posh-git as a fallback.
"@
}

$gitPredictorManifest = Resolve-GitPredictorManifest
Import-Module $gitPredictorManifest -Force -ErrorAction Stop

if (-not (Get-Command Get-GitSimplePrompt -ErrorAction SilentlyContinue)) {
    throw 'GitPredictor loaded without Get-GitSimplePrompt; the installed module is incomplete.'
}
Trace-ProfileMark 'gitpredictor'

# Single source of truth for the Solarized Light palette. Everything in this
# profile derives its colors from this table (PSReadLine tokens, the prompt),
# and the terminal-side layers use the same palette:
#   - Windows Terminal: built-in "Solarized Light" scheme (see windows.md)
#   - bat: BAT_THEME = 'Solarized (light)'
#   - zellij panes: pwsh/zellij-solarized-console.ps1 (ConPTY color table)
$script:Theme = @{
    Base00  = '#657B83'
    Base01  = '#586E75'
    Base02  = '#93A1A1'
    Dark    = '#073642'
    LightBg = '#EEE8D5'
    Yellow  = '#B58900'
    Orange  = '#CB4B16'
    Red     = '#DC322F'
    Magenta = '#D33682'
    Violet  = '#6C71C4'
    Blue    = '#268BD2'
    Cyan    = '#2AA198'
    Green   = '#859900'
}

# PSReadLine token colors, derived from the shared palette.
$ISETheme = @{
    Command                  = $script:Theme.Blue
    Comment                  = $script:Theme.Green
    ContinuationPrompt       = $script:Theme.Blue
    Default                  = $script:Theme.Dark
    Emphasis                 = $script:Theme.Cyan
    Error                    = $script:Theme.Red
    InlinePrediction         = $script:Theme.Base02
    Keyword                  = $script:Theme.Green
    ListPrediction           = $script:Theme.Yellow
    Member                   = $script:Theme.Base01
    Number                   = $script:Theme.Violet
    Operator                 = $script:Theme.Base00
    Parameter                = $script:Theme.Blue
    String                   = $script:Theme.Cyan
    Type                     = $script:Theme.Orange
    Variable                 = $script:Theme.Magenta
    ListPredictionSelected   = $script:Theme.Dark
    Selection                = $script:Theme.Base02
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
}

if ($script:IsInteractive) {
    Set-PSReadLineOption -EditMode vi
    Set-PSReadLineKeyHandler -Chord 'Tab' -Function MenuComplete
    Set-LightThemeColors

    $psrl = Get-Module PSReadLine
    if ($psrl -and $psrl.Version -ge [version]'2.2.0') {
        # History only: GitPredictor 0.2.0 dropped its PSReadLine predictor
        # plugin, so the Plugin source has nothing left to consume.
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}
Trace-ProfileMark 'functions+psreadline'

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

    $fgPath = $PSStyle.Foreground.FromRGB($script:Theme.Blue)
    $fgIcon = $PSStyle.Foreground.BrightBlue
    $fgTime = $PSStyle.Foreground.FromRGB($script:Theme.Base01)
    $fgOk = $PSStyle.Foreground.BrightGreen
    $fgErr = $PSStyle.Foreground.BrightRed
    $reset = $PSStyle.Reset

    $icon = '📁'
    $path = Get-PrettyPath (Get-Location).Path
    $time = (Get-Date).ToString('HH:mm:ss')

    Write-Host "$fgIcon$icon $fgPath$path$reset" -NoNewline
    $saved = $global:LASTEXITCODE
    # -Color: the module colors branch/untracked/conflict/stash with ANSI
    # codes, which the terminal's Solarized Light table renders consistently.
    $gitStatus = Get-GitSimplePrompt -Color
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

# Shell integration scripts emitted by external tools (zoxide init, jj
# completion) are cached on disk, keyed by the owning executable's last-write
# time. Dot-sourcing the cache avoids spawning the tool and regenerating its
# script in every session; a tool upgrade rewrites the executable and
# invalidates the key automatically.
$script:InitCacheRoot = Join-Path $env:LOCALAPPDATA ('devconfig' + [IO.Path]::DirectorySeparatorChar + 'shell-init')

function Get-ShellInitCachePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ToolPath,
        [Parameter(Mandatory)][scriptblock]$Generator
    )

    # Rust tools (zoxide, jj) ship no version resources, so the file's
    # modification time is the cheapest reliable key.
    $toolVersion = [System.IO.File]::GetLastWriteTimeUtc($ToolPath).Ticks.ToString()
    $safeVersion = $toolVersion -replace '[^A-Za-z0-9._-]', '_'
    $cachePath = Join-Path $script:InitCacheRoot "$Name.$safeVersion.ps1"
    if (Test-Path -LiteralPath $cachePath -PathType Leaf) {
        return $cachePath
    }

    $text = & $Generator
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    New-Item -ItemType Directory -Force -Path $script:InitCacheRoot | Out-Null
    # Write via a staging file so concurrent sessions never read a partial cache.
    $staging = "$cachePath.$([guid]::NewGuid().ToString('N')).tmp"
    Set-Content -LiteralPath $staging -Value $text
    Move-Item -LiteralPath $staging -Destination $cachePath -Force
    Get-ChildItem -LiteralPath $script:InitCacheRoot -Filter "$Name.*.ps1" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -ne $cachePath } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    return $cachePath
}

$zoxideCommand = Get-Command zoxide -ErrorAction SilentlyContinue
if ($script:IsInteractive -and $zoxideCommand) {
    $zoxideInit = Get-ShellInitCachePath -Name 'zoxide' -ToolPath $zoxideCommand.Source -Generator { zoxide init powershell | Out-String }
    if ($zoxideInit) { . $zoxideInit }
}
Trace-ProfileMark 'zoxide'

# jj's generated completion script is ~0.5 MB and compiling it in a cold
# process costs >100 ms, so it is NOT dot-sourced at startup. A bootstrap
# completer loads the cached script on the first jj Tab completion; that load
# re-registers the real completer, and the bootstrap re-runs the completion so
# even the first press returns real results.
$jjCommand = Get-Command jj -ErrorAction SilentlyContinue
if ($script:IsInteractive -and $jjCommand) {
    $jjInit = Get-ShellInitCachePath -Name 'jj' -ToolPath $jjCommand.Source -Generator { jj util completion power-shell | Out-String }
    if ($jjInit) {
        $script:JjInitPath = $jjInit
        $script:JjBootstrapActive = $false
        Register-ArgumentCompleter -Native -CommandName jj, jj.exe -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)
            if ($script:JjBootstrapActive) { return }
            $script:JjBootstrapActive = $true
            try {
                . $script:JjInitPath
            }
            finally {
                $script:JjBootstrapActive = $false
            }
            # Re-run the completion that triggered the bootstrap. The command
            # extent drops a trailing space, so restore it when the original
            # cursor sat beyond the extent; otherwise this would complete the
            # command name itself instead of its arguments.
            $inputText = $commandAst.Extent.Text
            $cursor = [Math]::Min($cursorPosition, $inputText.Length)
            if ($cursorPosition -gt $inputText.Length) {
                $inputText = $inputText + ' '
                $cursor = $inputText.Length
            }
            (TabExpansion2 -InputScript $inputText -CursorColumn $cursor).CompletionMatches
        }
    }
}
Trace-ProfileMark 'jj'

if ($script:TraceEnabled) {
    $script:TraceSw.Stop()
    Add-Content -LiteralPath $env:PROFILE_TRACE -Value (
        $script:TraceMarks | Format-Table -AutoSize | Out-String)
}
