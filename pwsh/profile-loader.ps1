# Thin loader copied to $PROFILE by windows.md.
# Keep this file independent of the repository's physical location.

$candidateRoots = @()
if ($env:DEV_CONFIG_ROOT) {
    $candidateRoots += $env:DEV_CONFIG_ROOT
}

$candidateRoots += @(
    (Join-Path $HOME 'src\configfiles'),
    (Join-Path $HOME 'Documents\configfiles')
)

$profilePath = $candidateRoots |
    Where-Object { $_ } |
    ForEach-Object { Join-Path $_ 'pwsh\profile.ps1' } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if (-not $profilePath) {
    Write-Warning "Personal profile not found. Set DEV_CONFIG_ROOT to the configfiles checkout, then start a new PowerShell session."
    return
}

. $profilePath
