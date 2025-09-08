#Requires -Version 5.1

<#
.SYNOPSIS
    Ensures essential directories for chezmoi dotfile management exist.
.DESCRIPTION
    Creates the necessary directory structure for chezmoi dotfile management under the user's home directory.
#>

$ErrorActionPreference = 'Stop'

function Ensure-DirectoryExists {
    param(
        [string]$Path,
        [string]$Description
    )
    if (Test-Path -Path $Path -PathType Container) {
        Write-Host "$Description already exists: $Path" -ForegroundColor Green
    } else {
        Write-Host "Creating directory: $Path" -ForegroundColor Cyan
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Host "Successfully created: $Description" -ForegroundColor Green
    }
}

$directories = @(
    @{ Path = "$HOME\.local"; Description = "Local user directory" },
    @{ Path = "$HOME\.local\bin"; Description = "Local user bin directory" },
    @{ Path = "$HOME\.local\state"; Description = "Local state directory" },
    @{ Path = "$HOME\.config"; Description = "Configuration directory" },
    @{ Path = "$HOME\.config\git"; Description = "Git configuration directory" }
)

foreach ($dir in $directories) {
    Ensure-DirectoryExists -Path $dir.Path -Description $dir.Description
}
