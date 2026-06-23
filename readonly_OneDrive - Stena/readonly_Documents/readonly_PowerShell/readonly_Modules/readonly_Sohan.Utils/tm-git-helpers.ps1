function Get-GitPbiIdFromBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $branchName = git rev-parse --abbrev-ref HEAD
    if ($branchName -match '^feature/(\d+)-') {
        return $matches[1]
    }

    Write-Error "Could not parse PBI Id from branch name. Please make sure you are on a feature branch."
    return $null
}

function New-GitPullRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TaskId,
        [Parameter(Mandatory = $false)]
        [switch]$Draft
    )

    if ([string]::IsNullOrEmpty($TaskId)) {
        $TaskId = Get-GitPbiIdFromBranch
        if ($null -eq $TaskId) {
            return
        }
    }

    Write-Host "logging in to az devops"
    Connect-AzDevOps

    $pbiTitle = Get-BoardItemTitle -PbiId $TaskId
    Write-Host "Title of task $TaskId is $pbiTitle"

    $prTitle = "Task $TaskId`: $pbiTitle (AB#$TaskId)"
    Write-Host "Creating PR with title: `"$prTitle`""
    if ($Draft) {
        gh pr create -d --title $prTitle --fill
        return
    }
    gh pr create --title $prTitle --fill
}

function New-GitFeatureBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PbiId,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    # Get environment variables for character replacement (regex patterns)
    # Default: replace /, space, |, *, ? with dash
    $replacePattern = if ($env:TM_FEATURE_TO_REPLACE) { $env:TM_FEATURE_TO_REPLACE } else { '[\/\s\|\*\?]' }
    # Default: remove ., ", ', :, <, >
    # Using character class with proper escaping: \x22 is double quote, \x27 is single quote
    $removePattern = if ($env:TM_FEATURE_TO_REMOVE) { $env:TM_FEATURE_TO_REMOVE } else { '[\.\x22\x27:<>]' }

    # Trim trailing whitespace
    $desc = $Description.TrimEnd()

    # Replace characters matching the pattern with dash
    $desc = $desc -replace $replacePattern, '-'

    # Remove characters matching the pattern
    $desc = $desc -replace $removePattern, ''

    # Convert to lowercase
    $desc = $desc.ToLower()

    $branchName = "feature/$PbiId-$desc"
    Write-Host "Creating new branch `"$branchName`" from master"
    git fetch -a
    git checkout -b $branchName --no-track origin/master
}

function Test-GitRepository {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $null = git -C . rev-parse --is-inside-work-tree 2>$null
    return $?
}
