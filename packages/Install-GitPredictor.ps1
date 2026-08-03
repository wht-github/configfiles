[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'gitpredictor.json'),
    [string]$InstallRoot
)

$ErrorActionPreference = 'Stop'

$package = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$version = [string]$package.release.version
$downloadUri = [uri]$package.release.downloadUrl
$expectedHash = [string]$package.release.sha256

if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid GitPredictor release version: $version"
}
if ($downloadUri.Scheme -ne 'https' -or $downloadUri.Host -ne 'github.com') {
    throw "GitPredictor release must be downloaded from https://github.com: $downloadUri"
}
if ($expectedHash -notmatch '^[A-Fa-f0-9]{64}$') {
    throw 'GitPredictor release SHA-256 is missing or invalid.'
}

if (-not $InstallRoot) {
    $InstallRoot = [Environment]::ExpandEnvironmentVariables([string]$package.installRoot)
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
$destination = Join-Path $InstallRoot $version
$transactionId = [guid]::NewGuid().ToString('N')
$staging = Join-Path $InstallRoot ".install-$transactionId"
$backup = Join-Path $InstallRoot ".backup-$transactionId"
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) "gitpredictor-$transactionId"
$archive = Join-Path $tempRoot ([string]$package.release.asset)
$expanded = Join-Path $tempRoot 'expanded'

try {
    New-Item -ItemType Directory -Force -Path $tempRoot, $expanded, $InstallRoot | Out-Null
    Invoke-WebRequest -Uri $downloadUri -OutFile $archive

    $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        throw "GitPredictor release checksum mismatch. Expected $expectedHash, got $actualHash."
    }

    Expand-Archive -LiteralPath $archive -DestinationPath $expanded
    $moduleSource = Join-Path $expanded 'GitPredictor'
    $requiredFiles = @(
        'GitPredictor.psd1',
        'GitPredictor.dll',
        'GitPrompt.psm1',
        'Register-GitTabCompletion.ps1',
        'LICENSE'
    )
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $moduleSource $file) -PathType Leaf)) {
            throw "GitPredictor release is incomplete: missing $file"
        }
    }

    $module = Test-ModuleManifest -Path (Join-Path $moduleSource 'GitPredictor.psd1')
    if ($module.Version.ToString() -ne $version) {
        throw "GitPredictor module version $($module.Version) does not match release $version."
    }

    Copy-Item -LiteralPath $moduleSource -Destination $staging -Recurse
    if (Test-Path -LiteralPath $destination) {
        Move-Item -LiteralPath $destination -Destination $backup
    }
    try {
        Move-Item -LiteralPath $staging -Destination $destination
    }
    catch {
        if ((Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $destination)) {
            Move-Item -LiteralPath $backup -Destination $destination
        }
        throw
    }
    if (Test-Path -LiteralPath $backup) {
        Remove-Item -LiteralPath $backup -Recurse -Force
    }

    Write-Output "Installed GitPredictor $version to $destination"
}
finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
