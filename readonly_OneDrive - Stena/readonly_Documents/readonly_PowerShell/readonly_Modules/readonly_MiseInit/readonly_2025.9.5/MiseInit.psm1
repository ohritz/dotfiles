$env:MISE_SHELL = 'pwsh'
$env:__MISE_ORIG_PATH = $env:PATH

function mise {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]  # Allow any number of arguments, including none
        [string[]] $arguments
    )

    $previous_out_encoding = $OutputEncoding
    $previous_console_out_encoding = [Console]::OutputEncoding
    $OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

    function _reset_output_encoding {
        $OutputEncoding = $previous_out_encoding
        [Console]::OutputEncoding = $previous_console_out_encoding
    }

    if ($arguments.count -eq 0) {
        & C:\Users\sohfer\AppData\Local\Microsoft\WinGet\Links\mise.exe
        _reset_output_encoding
        return
    } elseif ($arguments -contains '-h' -or $arguments -contains '--help') {
        & C:\Users\sohfer\AppData\Local\Microsoft\WinGet\Links\mise.exe @arguments
        _reset_output_encoding
        return
    }

    $command = $arguments[0]
    if ($arguments.Length -gt 1) {
        $remainingArgs = $arguments[1..($arguments.Length - 1)]
    } else {
        $remainingArgs = @()
    }

    switch ($command) {
        { $_ -in 'deactivate', 'shell', 'sh' } {
            & C:\Users\sohfer\AppData\Local\Microsoft\WinGet\Links\mise.exe $command @remainingArgs | Out-String | Invoke-Expression -ErrorAction SilentlyContinue
            _reset_output_encoding
        }
        default {
            & C:\Users\sohfer\AppData\Local\Microsoft\WinGet\Links\mise.exe $command @remainingArgs
            $status = $LASTEXITCODE
            if ($(Test-Path -Path Function:\_mise_hook)){
                _mise_hook
            }
            _reset_output_encoding
            # Pass down exit code from mise after _mise_hook
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                pwsh -NoProfile -Command exit $status
            } else {
                powershell -NoProfile -Command exit $status
            }
        }
    }
}

function Global:_mise_hook {
    if ($env:MISE_SHELL -eq "pwsh"){
        & C:\Users\sohfer\AppData\Local\Microsoft\WinGet\Links\mise.exe hook-env $args -s pwsh | Out-String | Invoke-Expression -ErrorAction SilentlyContinue
    }
}

function __enable_mise_chpwd{
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        if ($env:MISE_PWSH_CHPWD_WARNING -ne '0') {
            Write-Warning "mise: chpwd functionality requires PowerShell version 7 or higher. Your current version is $($PSVersionTable.PSVersion). You can add `$env:MISE_PWSH_CHPWD_WARNING=0` to your environment to disable this warning."
        }
        return
    }
    if (-not $__mise_pwsh_chpwd){
        $Global:__mise_pwsh_chpwd= $true
        $_mise_chpwd_hook = [EventHandler[System.Management.Automation.LocationChangedEventArgs]] {
            param([object] $source, [System.Management.Automation.LocationChangedEventArgs] $eventArgs)
            end {
                _mise_hook
            }
        };
        $__mise_pwsh_previous_chpwd_function=$ExecutionContext.SessionState.InvokeCommand.LocationChangedAction;

        if ($__mise_original_pwsh_chpwd_function) {
            $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = [Delegate]::Combine($__mise_pwsh_previous_chpwd_function, $_mise_chpwd_hook)
        }
        else {
            $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = $_mise_chpwd_hook
        }
    }
}
__enable_mise_chpwd
Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_chpwd

function __enable_mise_prompt {
    if (-not $__mise_pwsh_previous_prompt_function){
        $Global:__mise_pwsh_previous_prompt_function=$function:prompt
        function global:prompt {
            if (Test-Path -Path Function:\_mise_hook){
                _mise_hook
            }
            & $__mise_pwsh_previous_prompt_function
        }
    }
}
__enable_mise_prompt
Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_prompt

_mise_hook
if (-not $__mise_pwsh_command_not_found){
    $Global:__mise_pwsh_command_not_found= $true
    function __enable_mise_command_not_found {
        $_mise_pwsh_cmd_not_found_hook = [EventHandler[System.Management.Automation.CommandLookupEventArgs]] {
            param([object] $Name, [System.Management.Automation.CommandLookupEventArgs] $eventArgs)
            end {
                if ([Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()[-1].CommandLine -match ([regex]::Escape($Name))) {
                    if (& C:\Users\sohfer\AppData\Local\Microsoft\WinGet\Links\mise.exe hook-not-found -s pwsh -- $Name){
                        _mise_hook
                        if (Get-Command $Name -ErrorAction SilentlyContinue){
                            $EventArgs.Command = Get-Command $Name
                            $EventArgs.StopSearch = $true
                        }
                    }
                }
            }
        }
        $current_command_not_found_function = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
        if ($current_command_not_found_function) {
            $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = [Delegate]::Combine($current_command_not_found_function, $_mise_pwsh_cmd_not_found_hook)
        }
        else {
            $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $_mise_pwsh_cmd_not_found_hook
        }
    }
    __enable_mise_command_not_found
    Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_command_not_found
}


# SIG # Begin signature block
# MIIFfAYJKoZIhvcNAQcCoIIFbTCCBWkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0hQ24frZY8GtFzLYtUO5Fk5K
# CVCgggMSMIIDDjCCAfagAwIBAgIQGpfx907M75ZEx4/dMr/SCTANBgkqhkiG9w0B
# AQsFADAfMR0wGwYDVQQDDBRTb2hhbkNvZGVTaWduaW5nQ2VydDAeFw0yNTA5MTUx
# NjI4NDVaFw0yNjA5MTUxNjQ4NDVaMB8xHTAbBgNVBAMMFFNvaGFuQ29kZVNpZ25p
# bmdDZXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoWOorl75cpLp
# T+VlTnzUkurBBjiZKWQaQK8qTY+j2mpKI7jmxpZi2RBadOF5r4IQC53A+vyaSp8h
# RwHePhugedh8MWqJ871Jl2WqY1gLhFlWbvOKD34I4EmlHzeK8bAOUFGgqonlITXw
# Q1hnbey/KBhMx5nJni6qTtanhneb8/X8jK+G4KUNDIRcniB7HScAraFLg8O8iFI/
# qCVUYaw5/qPdPvSqFUw5WClYaEjDQb/Jw+kkkGJXUJRR8jXyUYNQ+5X0moeG3Spi
# VOBht5keiHcKAUumz+dsHdOSd8kx/kq+HWrB1tsWoPEiK0uMLjt2fPXyVrhgkqRe
# 4fT/EMu6PQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHQYDVR0OBBYEFIp5cBMziYhmmEJPtNx1eZW/F1VPMA0GCSqGSIb3DQEB
# CwUAA4IBAQAjAybJdJ5cFu3cpMZOq5Ghv2YtV9oNChxGhoKY7WGC+56k3eKkXsxk
# sv0IbvbaSJgVqndJrqqTnQv1BQIces9bkDWMzFMMKfxIdW/ZngjIwKhZl4KGDIXE
# Pw+tKxcilGrivLnwipvGHAYbmyFajA1wzmFeit3llt4jYhH1y2rz7ECEp9qK4Z2X
# U2w/BunwTqOqjRV5a/4SLtB1ECx8kw1QXn3rQge/UlH3a+s05GLDjmjxGxmkjExM
# SZQjj8AHlv62D5aFdewROMYkR5XsGIXSG8Sd/LajGFmZ2mcXmMDA6ZcVnC6iM3BO
# YlVDTJkWsICZf3w/B5blA/YNBUq9BvCVMYIB1DCCAdACAQEwMzAfMR0wGwYDVQQD
# DBRTb2hhbkNvZGVTaWduaW5nQ2VydAIQGpfx907M75ZEx4/dMr/SCTAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUN1NxStINV6bTtXgocJ7jErqI2BAwDQYJKoZIhvcNAQEBBQAEggEA
# QKm6cCjvpVcbERqKFQIjqSvnY28PBn/m2XkRy29Jh16nL8KFoMmJK5BpHro/OCjT
# jduSd8co1VOzJpii1TJoY0pMpLpeK8DYA9WJxSD5zKvXBcYzGzHyrp9NKa6U7IXi
# G9D9N65CA1jTaP930X7ttAUMkLM944kN7RqYV+d3z5ejfS5JZmxN2Pumaig3+XRP
# 3NV/j/DOR2wMHTtL6MZ7aomvQiVM7Ki7OfTSrIWKZPCG1wXfkgkXMV5O+JE7K1hu
# Q+geR6dg9mwkRu0UbA365/UkAWm5sVzUJCOOiRjfsW/QvWi7cH2xe2/cF95V45b+
# nu5Q77rnOrgNAc96j3eu/A==
# SIG # End signature block
