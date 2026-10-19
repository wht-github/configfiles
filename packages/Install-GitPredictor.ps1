[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'gitpredictor.json'),
    [string]$InstallRoot
)

$ErrorActionPreference = 'Stop'

$package = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$name = [string]$package.name
if ($name -notmatch '^[A-Za-z0-9_.-]+$') {
    throw "Invalid GitPredictor module name: $name"
}
$gallery = [string]$package.gallery
if ($gallery -ne 'PSGallery') {
    throw "Unsupported gallery in manifest: $gallery"
}

# Resolve the latest stable version from the public PowerShell Gallery OData
# feed. No version is pinned in the manifest; the current latest stable
# Gallery version is the default install target.
$feedUri = "https://www.powershellgallery.com/api/v2/FindPackagesById()?id='$name'"
$entries = @(Invoke-RestMethod -Uri $feedUri -Headers @{ 'User-Agent' = 'GitPredictor-installer' })
if (-not $entries) {
    throw "PowerShell Gallery has no package named $name."
}

$stable = @($entries | Where-Object { [string]$_.properties.IsPrerelease -ne 'true' })
$packageEntry = @($stable | Where-Object { [string]$_.properties.IsLatestVersion -eq 'true' }) |
    Select-Object -First 1
if (-not $packageEntry -and $stable) {
    $packageEntry = $stable |
        Sort-Object { [version][string]$_.properties.NormalizedVersion } -Descending |
        Select-Object -First 1
}
if (-not $packageEntry) {
    throw "PowerShell Gallery has no stable release of $name."
}

$version = [string]$packageEntry.properties.NormalizedVersion
if (-not $version) { $version = [string]$packageEntry.properties.Version }
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "GitPredictor latest Gallery version has an unexpected format: $version"
}

# The package payload is served by the Gallery itself over HTTPS.
$downloadUri = [uri][string]$packageEntry.content.src
if ($downloadUri.Scheme -ne 'https' -or $downloadUri.Host -ne 'www.powershellgallery.com') {
    throw "GitPredictor package must be downloaded from https://www.powershellgallery.com: $downloadUri"
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
$archive = Join-Path $tempRoot "$name-$version.zip"
$expanded = Join-Path $tempRoot 'expanded'

try {
    New-Item -ItemType Directory -Force -Path $tempRoot, $expanded, $InstallRoot | Out-Null

    # The Gallery distributes PowerShell modules as NuGet packages (.nupkg),
    # which are plain zip archives.
    Invoke-WebRequest -Uri $downloadUri -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $expanded

    # Module files sit at the package root; NuGet packaging metadata is not
    # part of the module.
    $moduleSource = $expanded
    $requiredFiles = @(
        'GitPredictor.psd1',
        'GitPredictor.dll',
        'GitPrompt.psm1',
        'Register-GitTabCompletion.ps1'
    )
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $moduleSource $file) -PathType Leaf)) {
            throw "GitPredictor package is incomplete: missing $file"
        }
    }

    $module = Test-ModuleManifest -Path (Join-Path $moduleSource 'GitPredictor.psd1')
    if ($module.Version.ToString() -ne $version) {
        throw "GitPredictor module version $($module.Version) does not match Gallery version $version."
    }

    New-Item -ItemType Directory -Force -Path $staging | Out-Null
    Get-ChildItem -LiteralPath $moduleSource -Force |
        Where-Object { $_.Name -notin @('_rels', 'package', '[Content_Types].xml') } |
        Copy-Item -Destination $staging -Recurse

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
    Write-Output "Installed GitPredictor $version (latest PowerShell Gallery release) to $destination"

    # Best effort: the replaced version's GitPredictor.dll can stay locked by
    # already running PowerShell sessions, which must not fail the install.
    if (Test-Path -LiteralPath $backup) {
        try {
            Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not remove the replaced version at $backup ($($_.Exception.Message)). Remove it manually after closing sessions that loaded GitPredictor."
        }
    }
}
finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
