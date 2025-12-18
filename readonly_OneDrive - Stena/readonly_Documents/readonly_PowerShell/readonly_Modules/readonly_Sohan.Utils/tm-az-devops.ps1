function Connect-AzDevOps {
    if ([string]::IsNullOrEmpty($env:AZURE_DEVOPS_EXT_PAT)) {
        $env:TM_NUGET_FEED_TOKEN | az devops login --only-show-errors --organization https://stenait.visualstudio.com/
        $env:AZURE_DEVOPS_EXT_PAT = $env:TM_NUGET_FEED_TOKEN
    }
}

function Select-PbiFromAssignedBoardItems {
    $fromAz = az boards query --detect --wiql "SELECT [System.Id],[System.Title] FROM WorkItems WHERE [System.State] != 'Done' AND [System.State] != 'New' AND [System.State] != 'Removed' AND [System.BoardColumn] != 'Peering' AND [Assigned to] = @Me" | ConvertFrom-Json

    $idTitleArray = @()
    $idHash = @{}
    $titleHash = @{}

    foreach ($item in $fromAz) {
        $id = $item.fields.'System.Id'
        $title = $item.fields.'System.Title'
        $idTitle = "$id`: $title"

        $idTitleArray += $idTitle
        $idHash[$idTitle] = $id
        $titleHash[$idTitle] = $title
    }

    if ($idTitleArray.Count -eq 0) {
        Write-Warning "No work items found."
        return $false
    }

    # Display menu
    Write-Host "`nSelect the number [1-$($idTitleArray.Count + 1)] of the PBI you want to create a branch for:"
    for ($i = 0; $i -lt $idTitleArray.Count; $i++) {
        Write-Host "$($i + 1). $($idTitleArray[$i])"
    }
    Write-Host "$($idTitleArray.Count + 1). Cancel..."

    do {
        $selection = Read-Host "Enter your choice"
        $selectionNum = [int]::TryParse($selection, [ref]$null) ? [int]$selection : 0

        # Check if Cancel was selected
        if ($selectionNum -eq ($idTitleArray.Count + 1)) {
            Write-Host ":("
            return $false
        }

        # Validate selection
        if ($selectionNum -lt 1 -or $selectionNum -gt ($idTitleArray.Count + 1)) {
            Write-Host "Select a number between 1 and $($idTitleArray.Count + 1)"
            continue
        }

        # Set script-scoped variables (similar to bash global variables)
        $script:selected_id = $idHash[$idTitleArray[$selectionNum - 1]]
        $script:selected_title = $titleHash[$idTitleArray[$selectionNum - 1]]

        if ($null -ne $script:selected_id -or $null -ne $script:selected_title) {
            Write-Host "You selected $($idTitleArray[$selectionNum - 1])"
            return $true
        }
    } while ($true)
}

function Get-BoardItemTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PbiId
    )

    $result = az boards work-item show --id $PbiId | ConvertFrom-Json
    return $result.fields.'System.Title'
}

function Set-BoardItemState {
    param(
        [Parameter(Mandatory = $false)]
        [string]$TaskId,
        [Parameter(Mandatory = $false)]
        [string]$State = 'Ready to pull'
    )

    # If TaskId not provided, try to get it from git branch (assuming helper function exists)
    if ([string]::IsNullOrEmpty($TaskId)) {
        if (Get-Command -Name 'Get-GitPbiIdFromBranch' -ErrorAction SilentlyContinue) {
            $TaskId = Get-GitPbiIdFromBranch
        } else {
            throw "TaskId parameter is required or Get-GitPbiIdFromBranch function must be available"
        }
    }

    $result = az boards work-item update --id $TaskId --state $State | ConvertFrom-Json
    return $result.fields.'System.State'
}

# Export functions
Export-ModuleMember -Function Connect-AzDevOps, Select-PbiFromAssignedBoardItems, Get-BoardItemTitle, Set-BoardItemState
