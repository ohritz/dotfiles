# =============================================================================
#
# Utility functions for zoxide.
#

# Call zoxide binary, returning the output as UTF-8.
function global:__zoxide_bin {
    $encoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
        $result = zoxide @args
        return $result
    } finally {
        [Console]::OutputEncoding = $encoding
    }
}

# pwd based on zoxide's format.
function global:__zoxide_pwd {
    $cwd = Get-Location
    if ($cwd.Provider.Name -eq "FileSystem") {
        $cwd.ProviderPath
    }
}

# cd + custom logic based on the value of _ZO_ECHO.
function global:__zoxide_cd($dir, $literal) {
    $dir = if ($literal) {
        Set-Location -LiteralPath $dir -Passthru -ErrorAction Stop
    } else {
        if ($dir -eq '-' -and ($PSVersionTable.PSVersion -lt 6.1)) {
            Write-Error "cd - is not supported below PowerShell 6.1. Please upgrade your version of PowerShell."
        }
        elseif ($dir -eq '+' -and ($PSVersionTable.PSVersion -lt 6.2)) {
            Write-Error "cd + is not supported below PowerShell 6.2. Please upgrade your version of PowerShell."
        }
        else {
            Set-Location -Path $dir -Passthru -ErrorAction Stop
        }
    }
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
$global:__zoxide_oldpwd = __zoxide_pwd
function global:__zoxide_hook {
    $result = __zoxide_pwd
    if ($result -ne $global:__zoxide_oldpwd) {
        if ($null -ne $result) {
            zoxide add "--" $result
        }
        $global:__zoxide_oldpwd = $result
    }
}

# Initialize hook.
$global:__zoxide_hooked = (Get-Variable __zoxide_hooked -ErrorAction Ignore -ValueOnly)
if ($global:__zoxide_hooked -ne 1) {
    $global:__zoxide_hooked = 1
    $global:__zoxide_prompt_old = $function:prompt

    function global:prompt {
        if ($null -ne $__zoxide_prompt_old) {
            & $__zoxide_prompt_old
        }
        $null = __zoxide_hook
    }
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function global:__zoxide_z {
    if ($args.Length -eq 0) {
        __zoxide_cd ~ $true
    }
    elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
        __zoxide_cd $args[0] $false
    }
    elseif ($args.Length -eq 1 -and (Test-Path -PathType Container -LiteralPath $args[0])) {
        __zoxide_cd $args[0] $true
    }
    elseif ($args.Length -eq 1 -and (Test-Path -PathType Container -Path $args[0] )) {
        __zoxide_cd $args[0] $false
    }
    else {
        $result = __zoxide_pwd
        if ($null -ne $result) {
            $result = __zoxide_bin query --exclude $result "--" @args
        }
        else {
            $result = __zoxide_bin query "--" @args
        }
        if ($LASTEXITCODE -eq 0) {
            __zoxide_cd $result $true
        }
    }
}

# Jump to a directory using interactive search.
function global:__zoxide_zi {
    $result = __zoxide_bin query -i "--" @args
    if ($LASTEXITCODE -eq 0) {
        __zoxide_cd $result $true
    }
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

Set-Alias -Name cd -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name cdi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# =============================================================================
#
# To initialize zoxide, add this to your configuration (find it by running
# `echo $profile` in PowerShell):
#
# Invoke-Expression (& { (zoxide init powershell | Out-String) })


# SIG # Begin signature block
# MIIFfAYJKoZIhvcNAQcCoIIFbTCCBWkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP0l/2CwMVMNl5azn16aGP4dI
# gu+gggMSMIIDDjCCAfagAwIBAgIQGpfx907M75ZEx4/dMr/SCTANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUg4U2DnjZfv2fujHW+Cc1EQEeOOYwDQYJKoZIhvcNAQEBBQAEggEA
# nY3/g1Bym2t54r4ow4vQuvH1B/MKcP/92R6xzKYd3/n4nTk4oCo1ispRuLu0Be/f
# MCQRd766CexlVZGWMLHwndcqe9rLnilfExiOuyMBnAhxKu3SXha4WjBVL+6G5xev
# cHPS8aER747TcmK4Sg098z32teIFVXuV4hI370EzQ5h9LfUWedbol6EQFHympmWg
# g/CMAI9neSTXrpG8CXJgLrnmo/6M4eD6ZkRtvu1fV7b4/9B7Vcy8Vx5WplQh/YBv
# S+zK9ukk6JQcx/7uKs4xW/SfU5iu5azWw239Otv7QS1CTFu8aMj3xGvdN8yeQctc
# TNSmTnTTxeJSDAkC3v1r9w==
# SIG # End signature block
