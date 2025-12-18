function pj {
    param(
        [Parameter(Position=0, ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    $isOpen = $false
    $editor = $env:EDITOR
    $projectBasePaths = $env:PROJECT_PATHS -split ';'
    # If first argument is 'open', use editor, else use Set-Location
    if ($Args.Length -gt 0 -and $Args[0] -eq 'open') {
        $Args = $Args[1..($Args.Count - 1)]
        $isOpen = $true
    }

    $project = $Args -join ' '

    if($project -eq '') {
        Write-Host -ForegroundColor Yellow "No project specified, opening default project base path..."
        Set-Location $projectBasePaths[0]
        return
    }

    foreach ($basedir in $projectBasePaths) {
        $projectPath = Join-Path $basedir $project
        if (Test-Path $projectPath -PathType Container) {
            if ($isOpen) {
                & $editor $projectPath
            } else {
                Set-Location $projectPath
            }
            return
        }
    }

    Write-Host -ForegroundColor Red "No such project '$project'."
}

function pjo {
    param(
        [Parameter(Position=0, ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    pj open $Args
}

Register-ArgumentCompleter -CommandName pj -ParameterName Args -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $dirs = @()
    foreach ($basedir in $env:PROJECT_PATHS -split ';') {
        if (Test-Path $basedir) {
            $dirs += Get-ChildItem -Path $basedir -Directory | Select-Object -ExpandProperty Name
        }
    }
    $dirs | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName pjo -ParameterName Args -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $dirs = @()
    foreach ($basedir in $env:PROJECT_PATHS -split ';') {
        if (Test-Path $basedir) {
            $dirs += Get-ChildItem -Path $basedir -Directory | Select-Object -ExpandProperty Name
        }
    }
    $dirs | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
