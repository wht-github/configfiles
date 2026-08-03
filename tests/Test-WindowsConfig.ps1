[CmdletBinding()]
param(
    [string]$GitPredictorModulePath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $repoRoot 'pwsh\profile.ps1'

if (-not (Test-Path -LiteralPath $profilePath)) {
    throw "Profile not found: $profilePath"
}

if ($GitPredictorModulePath) {
    $env:GITPREDICTOR_MODULE_PATH = $GitPredictorModulePath
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
