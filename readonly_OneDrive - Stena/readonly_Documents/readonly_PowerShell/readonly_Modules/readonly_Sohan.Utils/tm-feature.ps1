# Characters to be replaced: '/', space, '\', '*', '?', '|'
# These are often problematic in filenames or paths.
$script:TM_FEATURE_TO_REPLACE = if ($env:TM_FEATURE_TO_REPLACE) { $env:TM_FEATURE_TO_REPLACE } else { '[\/\s\\\*\?\|]' }

# Characters to be removed: '.', '"', "'", ':', '<', '>'
# These are commonly restricted in file names.
$script:TM_FEATURE_TO_REMOVE = if ($env:TM_FEATURE_TO_REMOVE) { $env:TM_FEATURE_TO_REMOVE } else { '[\.\x22\x27:<>]' }

function New-TmFeatureBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PbiId
    )

    if (-not (Test-GitRepository)) {
        Write-Error "Not a Git repo"
        return
    }

    # Script-scoped variables (similar to bash global variables)
    $script:selected_id = $null
    $script:selected_title = $null

    try {
        Write-Host "logging in to az devops"
        Connect-AzDevOps

        if ([string]::IsNullOrEmpty($PbiId)) {
            Write-Host "Getting assigned PBIs that are in progress"
            $selectionResult = Select-PbiFromAssignedBoardItems
            if (-not $selectionResult) {
                return
            }
            # selected_id and selected_title are set by Select-PbiFromAssignedBoardItems
        } else {
            $script:selected_id = $PbiId
            $script:selected_title = Get-BoardItemTitle -PbiId $PbiId
        }

        if ($script:selected_id -notmatch '^\d+$') {
            Write-MessageError "Selected PBI ID is not a number"
            return
        }

        if (-not (Test-TmFeatureTitle -PbiId $script:selected_id -Title $script:selected_title)) {
            return
        }

        if ($script:selected_id -and $script:selected_title) {
            New-GitFeatureBranch -PbiId $script:selected_id -Description $script:selected_title
        } else {
            Write-Host 'No selection'
        }
    } finally {
        # Cleanup script-scoped variables
        $script:selected_id = $null
        $script:selected_title = $null
    }
}

function Test-TmFeatureTitle {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PbiId,

        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    $valid = $false
    $selected_title = $Title
    $suffixMaxLength = 41
    $prefix = "feature_"
    $maxLength = 128

    while (-not $valid) {
        # Build docker tag: prefix + id + title, then sanitize
        $dockerTag = "$prefix$PbiId-$selected_title"
        $dockerTag = $dockerTag.TrimEnd()
        $dockerTag = $dockerTag -replace $script:TM_FEATURE_TO_REPLACE, '-'
        $dockerTag = $dockerTag -replace $script:TM_FEATURE_TO_REMOVE, ''
        $dockerTag = $dockerTag.ToLower()

        $validationResult = Test-DockerRepositoryTag -Tag $dockerTag -MaxLength $maxLength -SuffixMaxLength $suffixMaxLength

        if ($validationResult -ne 0) {
            Write-DockerRepositoryErrorMessage -ReturnCode $validationResult -Tag $dockerTag -MaxLength $maxLength -SuffixMaxLength $suffixMaxLength
            Write-MessageInfo "Do you want to edit the title of the PBI manually? [y/N]"
            $response = Read-Host
            if ($response -match '^([yY][eE][sS]|[yY])$') {
                Write-Host ""
                Write-MessageInfo "Please enter the new title for the PBI"
                $selected_title = Read-Host
            } else {
                Write-MessageError "No changes made, aborting"
                return $false
            }
        } else {
            Write-MessageSuccess "Tag is valid, will render a docker tag as '$dockerTag-<commit-id>'"
            $valid = $true
        }
    }
    return $true
}

function Test-DockerRepositoryTag {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag,

        [Parameter(Mandatory = $true)]
        [int]$MaxLength,

        [Parameter(Mandatory = $true)]
        [int]$SuffixMaxLength
    )

    $returnCode = 0

    if ($Tag.Length -ge ($MaxLength - $SuffixMaxLength)) {
        $returnCode = 1
    }

    if ($Tag -notmatch '^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$') {
        if ($returnCode -gt 0) {
            $returnCode = 3
        } else {
            $returnCode = 2
        }
    }

    return $returnCode
}

function Write-DockerRepositoryErrorMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ReturnCode,

        [Parameter(Mandatory = $true)]
        [string]$Tag,

        [Parameter(Mandatory = $true)]
        [int]$MaxLength,

        [Parameter(Mandatory = $true)]
        [int]$SuffixMaxLength
    )

    if ($ReturnCode -ne 0) {
        Write-MessageWarning "This title will render an invalid docker tag."
        Write-MessageInfo "  Tag: '$Tag'"
        Write-MessageStandard ""

        if ($ReturnCode -eq 1 -or $ReturnCode -eq 3) {
            $maxAllowedLength = $MaxLength - $SuffixMaxLength
            Write-MessageWarning "It must be no longer than '$maxAllowedLength' characters"
            Write-MessageInfo "  Tag is '$($Tag.Length)' characters long."
            Write-MessageStandard ""
        }
        if ($ReturnCode -eq 2 -or $ReturnCode -eq 3) {
            Write-MessageWarning 'Invalid characters in tag'
            Write-MessageStandard '  Disallowed characters are:'
            Write-MessageError '  * Start with a period or hyphen'
            Write-MessageStandard '  Allowed characters are:'
            Write-MessageSuccess '  * lowercase and uppercase letters'
            Write-MessageSuccess '  * digits'
            Write-MessageSuccess '  * underscores'
            Write-MessageSuccess '  * periods'
            Write-MessageSuccess '  * hyphens'
        }
        Write-MessageStandard ""
    }
}

# Export only the public function
Export-ModuleMember -Function New-TmFeatureBranch
