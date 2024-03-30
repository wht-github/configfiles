oh-my-posh init pwsh --config "~/.my_posh_theme.omp.json" | Invoke-Expression
Import-Module posh-git # 引入 posh-git
$env:POSH_GIT_ENABLED = $true
function wt_admin {
    Start-Process wt "-d $(Get-Location)" -Verb RunAs
}
function _refreshenv {
    $Env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
Set-Alias -Name "wt-admin" -Value wt_admin
Set-Alias -Name "ls" -Value lsd
Set-Alias -Name "refreshenv" -Value _refreshenv