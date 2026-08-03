[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $repoRoot 'pwsh\profile.ps1'

if (-not (Test-Path -LiteralPath $profilePath)) {
    throw "Profile not found: $profilePath"
}

$profileSource = Get-Content -LiteralPath $profilePath -Raw
foreach ($developmentSetting in @('GITPREDICTOR_MODULE_PATH', 'GITPREDICTOR_ROOT', 'siblingGitPredictor')) {
    if ($profileSource.Contains($developmentSetting)) {
        throw "Profile still contains GitPredictor development configuration: $developmentSetting"
    }
}

. $profilePath

if (-not (Get-Command Get-GitSimplePrompt -ErrorAction SilentlyContinue)) {
    throw 'GitPredictor was not loaded.'
}

if (Get-Module -Name posh-git) {
    throw 'posh-git must not be loaded.'
}

if (-not (Get-Command Get-VisualStudioInstallation -ErrorAction SilentlyContinue)) {
    throw 'Visual Studio discovery function was not defined.'
}

Write-Output 'Windows profile checks passed.'
