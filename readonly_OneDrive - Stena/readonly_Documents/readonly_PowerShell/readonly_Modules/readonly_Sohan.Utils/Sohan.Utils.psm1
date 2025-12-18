# Dot-source nested modules to import their functions
. $PSScriptRoot\tm-az-devops.ps1
. $PSScriptRoot\tm-git-helpers.ps1
. $PSScriptRoot\messages.ps1
. $PSScriptRoot\tm-feature.ps1

# Re-export all functions from nested modules
Export-ModuleMember -Function Connect-AzDevOps, Select-PbiFromAssignedBoardItems, Get-BoardItemTitle, Set-BoardItemState, New-GitPullRequest, New-GitFeatureBranch, Test-GitRepository, New-TmFeatureBranch

