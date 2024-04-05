oh-my-posh init pwsh --config "~/.my_posh_theme.omp.json" | Invoke-Expression
Import-Module posh-git # 引入 posh-git
$env:POSH_GIT_ENABLED = $true
function Start-Admin {
    Start-Process wt "-d $(Get-Location)" -Verb RunAs
}
function Update-Env {
    $Env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
function vsdevshell {
    & 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation
}
Set-Alias -Name "ls" -Value lsd
Set-Alias -Name "wt-admin" -Value Start-Admin
Set-Alias -Name "refreshenv" -Value Update-Env
Invoke-Expression (& { (zoxide init powershell | Out-String) })