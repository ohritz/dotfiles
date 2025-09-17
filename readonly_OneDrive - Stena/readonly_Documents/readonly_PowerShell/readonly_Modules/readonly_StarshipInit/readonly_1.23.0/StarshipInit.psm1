#!/usr/bin/env pwsh

# Create a new dynamic module so we don't pollute the global namespace with our functions and
# variables
$null = New-Module starship {
    function Get-Cwd {
        $cwd = Get-Location
        $provider_prefix = "$($cwd.Provider.ModuleName)\$($cwd.Provider.Name)::"
        return @{
            # Resolve the actual/physical path
            # NOTE: ProviderPath is only a physical filesystem path for the "FileSystem" provider
            # E.g. `Dev:\` -> `C:\Users\Joe Bloggs\Dev\`
            Path = $cwd.ProviderPath;
            # Resolve the provider-logical path
            # NOTE: Attempt to trim any "provider prefix" from the path string.
            # E.g. `Microsoft.PowerShell.Core\FileSystem::Dev:\` -> `Dev:\`
            LogicalPath =
                if ($cwd.Path.StartsWith($provider_prefix)) {
                    $cwd.Path.Substring($provider_prefix.Length)
                } else {
                    $cwd.Path
                };
        }
    }

    function Invoke-Native {
        param($Executable, $Arguments)
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo -ArgumentList $Executable -Property @{
            StandardOutputEncoding = [System.Text.Encoding]::UTF8;
            RedirectStandardOutput = $true;
            RedirectStandardError = $true;
            CreateNoWindow = $true;
            UseShellExecute = $false;
        };
        if ($startInfo.ArgumentList.Add) {
            # PowerShell 6+ uses .NET 5+ and supports the ArgumentList property
            # which bypasses the need for manually escaping the argument list into
            # a command string.
            foreach ($arg in $Arguments) {
                $startInfo.ArgumentList.Add($arg);
            }
        }
        else {
            # Build an arguments string which follows the C++ command-line argument quoting rules
            # See: https://docs.microsoft.com/en-us/previous-versions//17w5ykft(v=vs.85)?redirectedfrom=MSDN
            $escaped = $Arguments | ForEach-Object {
                $s = $_ -Replace '(\\+)"','$1$1"'; # Escape backslash chains immediately preceding quote marks.
                $s = $s -Replace '(\\+)$','$1$1';  # Escape backslash chains immediately preceding the end of the string.
                $s = $s -Replace '"','\"';         # Escape quote marks.
                "`"$s`""                           # Quote the argument.
            }
            $startInfo.Arguments = $escaped -Join ' ';
        }
        $process = [System.Diagnostics.Process]::Start($startInfo)

        # Read the output and error streams asynchronously
        # Avoids potential deadlocks when the child process fills one of the buffers
        # https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process.standardoutput?view=net-6.0#remarks
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        [System.Threading.Tasks.Task]::WaitAll(@($stdout, $stderr))

        # stderr isn't displayed with this style of invocation
        # Manually write it to console
        if ($stderr.Result.Trim() -ne '') {
            # Write-Error doesn't work here
            $host.ui.WriteErrorLine($stderr.Result)
        }

        $stdout.Result;
    }

    function Enable-TransientPrompt {
        Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
            $previousOutputEncoding = [Console]::OutputEncoding
            try {
                $parseErrors = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$null, [ref]$null, [ref]$parseErrors, [ref]$null)
                if ($parseErrors.Count -eq 0) {
                    $script:TransientPrompt = $true
                    [Console]::OutputEncoding = [Text.Encoding]::UTF8
                    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
                }
            } finally {
                if ($script:DoesUseLists) {
                    # If PSReadline is set to display suggestion list, this workaround is needed to clear the buffer below
                    # before accepting the current commandline. The max amount of items in the list is 10, so 12 lines
                    # are cleared (10 + 1 more for the prompt + 1 more for current commandline).
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`n" * [math]::Min($Host.UI.RawUI.WindowSize.Height - $Host.UI.RawUI.CursorPosition.Y - 1, 12))
                    [Microsoft.PowerShell.PSConsoleReadLine]::Undo()
                }
                [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
                [Console]::OutputEncoding = $previousOutputEncoding
            }
        }
    }

    function Disable-TransientPrompt {
        Set-PSReadLineKeyHandler -Key Enter -Function AcceptLine
        $script:TransientPrompt = $false
    }

    function global:prompt {
        $origDollarQuestion = $global:?
        $origLastExitCode = $global:LASTEXITCODE

        # Invoke precmd, if specified
        try {
            if (Test-Path function:Invoke-Starship-PreCommand) {
                Invoke-Starship-PreCommand
            }
        } catch {}

        # @ makes sure the result is an array even if single or no values are returned
        $jobs = @(Get-Job | Where-Object { $_.State -eq 'Running' }).Count

        $cwd = Get-Cwd
        $arguments = @(
            "prompt"
            "--path=$($cwd.Path)",
            "--logical-path=$($cwd.LogicalPath)",
            "--terminal-width=$($Host.UI.RawUI.WindowSize.Width)",
            "--jobs=$($jobs)"
        )

        # We start from the premise that the command executed correctly, which covers also the fresh console.
        $lastExitCodeForPrompt = 0
        if ($lastCmd = Get-History -Count 1) {
            # In case we have a False on the Dollar hook, we know there's an error.
            if (-not $origDollarQuestion) {
                # We retrieve the InvocationInfo from the most recent error using $global:error[0]
                $lastCmdletError = try { $global:error[0] |  Where-Object { $_ -ne $null } | Select-Object -ExpandProperty InvocationInfo } catch { $null }
                # We check if the last command executed matches the line that caused the last error, in which case we know
                # it was an internal Powershell command, otherwise, there MUST be an error code.
                $lastExitCodeForPrompt = if ($null -ne $lastCmdletError -and $lastCmd.CommandLine -eq $lastCmdletError.Line) { 1 } else { $origLastExitCode }
            }
            $duration = [math]::Round(($lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime).TotalMilliseconds)

            $arguments += "--cmd-duration=$($duration)"
        }

        $arguments += "--status=$($lastExitCodeForPrompt)"

        if ([Microsoft.PowerShell.PSConsoleReadLine]::InViCommandMode()) {
            $arguments += "--keymap=vi"
        }

        # Invoke Starship
        $promptText = if ($script:TransientPrompt) {
            $script:TransientPrompt = $false
            if (Test-Path function:Invoke-Starship-TransientFunction) {
                Invoke-Starship-TransientFunction
            } else {
                "$([char]0x1B)[1;32mÔØ»$([char]0x1B)[0m "
            }
        } else {
            Invoke-Native -Executable 'starship.EXE' -Arguments $arguments
        }

        # Set the number of extra lines in the prompt for PSReadLine prompt redraw.
        Set-PSReadLineOption -ExtraPromptLineCount ($promptText.Split("`n").Length - 1)

        # Return the prompt
        $promptText

        # Propagate the original $LASTEXITCODE from before the prompt function was invoked.
        $global:LASTEXITCODE = $origLastExitCode

        # Propagate the original $? automatic variable value from before the prompt function was invoked.
        #
        # $? is a read-only or constant variable so we can't directly override it.
        # In order to propagate up its original boolean value we will take an action
        # which will produce the desired value.
        #
        # This has to be the very last thing that happens in the prompt function
        # since every PowerShell command sets the $? variable.
        if ($global:? -ne $origDollarQuestion) {
            if ($origDollarQuestion) {
                 # Simple command which will execute successfully and set $? = True without any other side affects.
                1+1
            } else {
                # Write-Error will set $? to False.
                # ErrorAction Ignore will prevent the error from being added to the $Error collection.
                Write-Error '' -ErrorAction 'Ignore'
            }
        }

    }

    # Disable virtualenv prompt, it breaks starship
    $ENV:VIRTUAL_ENV_DISABLE_PROMPT=1

    $script:TransientPrompt = $false
    $script:DoesUseLists = (Get-PSReadLineOption).PredictionViewStyle -eq 'ListView'

    if ($PSVersionTable.PSVersion.Major -gt 5) {
        $ENV:STARSHIP_SHELL = "pwsh"
    } else {
        $ENV:STARSHIP_SHELL = "powershell"
    }

    # Set up the session key that will be used to store logs
    $ENV:STARSHIP_SESSION_KEY = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })

    # Invoke Starship and set continuation prompt
    Set-PSReadLineOption -ContinuationPrompt (
        Invoke-Native -Executable 'starship.EXE' -Arguments @(
            "prompt",
            "--continuation"
        )
    )

    try {
        # Combine user defined ViModeChangeHandler if it exists
        if((Get-PSReadLineOption).ViModeChangeHandler){
            # &{...} to limit the scope of the GetNewClosure
            & {
                $originalHandler = (Get-PSReadLineOption).ViModeChangeHandler
                Set-PSReadLineOption -ViModeChangeHandler {
                    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
                    & $originalHandler @args
                }.GetNewClosure()
            }
        } else {
            Set-PSReadLineOption -ViModeIndicator script -ViModeChangeHandler {
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            }
        }
    } catch {}

    Export-ModuleMember -Function @(
        "Enable-TransientPrompt"
        "Disable-TransientPrompt"
    )
}

# SIG # Begin signature block
# MIIFfAYJKoZIhvcNAQcCoIIFbTCCBWkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUF362rPzTnzmdEfxjWpVlq26/
# NLCgggMSMIIDDjCCAfagAwIBAgIQGpfx907M75ZEx4/dMr/SCTANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUfnC+iOTwPlgkyi1FBa4Lwjt8xEgwDQYJKoZIhvcNAQEBBQAEggEA
# JQ5Krw+VsbdICYwycXspnhh0QmNXcMyY5Qsd8rAN2+3QFq5FYMxlWlHWJWW7RPu+
# /VPVhUFPqaMo2O8VSNh15bf9s4gCUChohMZMZYgazdFmiIPAhI8M8UG/ODFjBeM8
# wlNJw8HGyvUH5GTbGejE/dDTEficD3GIHp+2eZ9D4li8knF5syHh1fd9MW+0v4vh
# R/5MUwZ7Ee0HLBpg7iYv4uORI2L+zsl5aeWKRGs5EgJjboeLwSOkRkrVx0fVyt55
# cckl3E8uxnXYQSxtg8CrLWcV4akqZVi7ctPXsGtqJLJyzefalJi2wY/IkUH0qEYW
# 9/do2+oPIZONQfjkM+pfkw==
# SIG # End signature block
