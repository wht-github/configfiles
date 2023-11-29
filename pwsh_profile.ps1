# Import-Module oh-my-posh # 引入 oh-my-posh
oh-my-posh init pwsh --config "~/.my_posh_theme.omp.json" | Invoke-Expression
Import-Module posh-git # 引入 posh-git
$env:POSH_GIT_ENABLED = $true
function wt_admin {
    Start-Process wt "-d $(Get-Location)" -Verb RunAs
}
Set-Alias -Name "wt-admin" -Value wt_admin
# function Set-PoshGitStatus {
#     $global:GitStatus = Get-GitStatus
#     $env:POSH_GIT_STRING = $(Write-GitStatus -Status $global:GitStatus).Trim()
# }
# New-Alias -Name 'Set-PoshContext' -Value 'Set-PoshGitStatus' -Scope Global -Force
# Set-Theme Powerlevel10k-Lean 
# Set-PSReadlineKeyHandler -Key Tab -Function Complete # 设置 Tab 键补全
# Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward # 设置向上键为后向搜索历史记录
# Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward # 设置向下键为前向搜索历史纪录
