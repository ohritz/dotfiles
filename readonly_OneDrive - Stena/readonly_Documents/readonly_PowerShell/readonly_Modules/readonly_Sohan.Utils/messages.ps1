function Write-MessageWarning {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    Write-Message -Type Warning -Message $Message
}

function Write-MessageWarningDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    Test-CommandDependency -Command $Command -Type Warning -Message $Message
}

function Write-MessageError {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    Write-Message -Type Error -Message $Message
}

function Write-MessageInfo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    Write-Message -Type Info -Message $Message
}

function Write-MessageSuccess {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    Write-Message -Type Success -Message $Message
}

function Write-MessageStandard {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    Write-Message -Type Standard -Message $Message
}

function Test-CommandDependency {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Warning', 'Error', 'Info', 'Success', 'Standard')]
        [string]$Type,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    $commandExists = Get-Command -Name $Command -ErrorAction SilentlyContinue
    if (-not $commandExists) {
        Write-Message -Type $Type -Message $Message
        return $false
    }

    return $true
}

function Write-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Warning', 'Error', 'Info', 'Success', 'Standard')]
        [string]$Type = 'Standard',

        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    foreach ($msg in $Message) {
        switch ($Type) {
            'Warning' {
                Write-Host $msg -ForegroundColor Yellow
            }
            'Error' {
                Write-Error $msg
            }
            'Info' {
                Write-Host $msg -ForegroundColor White
            }
            'Success' {
                Write-Host $msg -ForegroundColor Green
            }
            'Standard' {
                Write-Host $msg
            }
        }
    }
}
