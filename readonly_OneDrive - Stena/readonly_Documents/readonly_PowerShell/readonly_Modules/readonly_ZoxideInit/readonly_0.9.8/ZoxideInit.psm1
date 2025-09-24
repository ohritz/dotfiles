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
# MIIFoQYJKoZIhvcNAQcCoIIFkjCCBY4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDwZ2jOKV0deNcA
# 0/mPmWY3bQWaYcBSJIaj50x5ctprWqCCAxIwggMOMIIB9qADAgECAhAal/H3Tszv
# lkTHj90yv9IJMA0GCSqGSIb3DQEBCwUAMB8xHTAbBgNVBAMMFFNvaGFuQ29kZVNp
# Z25pbmdDZXJ0MB4XDTI1MDkxNTE2Mjg0NVoXDTI2MDkxNTE2NDg0NVowHzEdMBsG
# A1UEAwwUU29oYW5Db2RlU2lnbmluZ0NlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQChY6iuXvlykulP5WVOfNSS6sEGOJkpZBpArypNj6PaakojuObG
# lmLZEFp04XmvghALncD6/JpKnyFHAd4+G6B52HwxaonzvUmXZapjWAuEWVZu84oP
# fgjgSaUfN4rxsA5QUaCqieUhNfBDWGdt7L8oGEzHmcmeLqpO1qeGd5vz9fyMr4bg
# pQ0MhFyeIHsdJwCtoUuDw7yIUj+oJVRhrDn+o90+9KoVTDlYKVhoSMNBv8nD6SSQ
# YldQlFHyNfJRg1D7lfSah4bdKmJU4GG3mR6IdwoBS6bP52wd05J3yTH+Sr4dasHW
# 2xag8SIrS4wuO3Z89fJWuGCSpF7h9P8Qy7o9AgMBAAGjRjBEMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUinlwEzOJiGaYQk+0
# 3HV5lb8XVU8wDQYJKoZIhvcNAQELBQADggEBACMDJsl0nlwW7dykxk6rkaG/Zi1X
# 2g0KHEaGgpjtYYL7nqTd4qRezGSy/Qhu9tpImBWqd0muqpOdC/UFAhx6z1uQNYzM
# Uwwp/Eh1b9meCMjAqFmXgoYMhcQ/D60rFyKUauK8ufCKm8YcBhubIVqMDXDOYV6K
# 3eWW3iNiEfXLavPsQISn2orhnZdTbD8G6fBOo6qNFXlr/hIu0HUQLHyTDVBefetC
# B79SUfdr6zTkYsOOaPEbGaSMTExJlCOPwAeW/rYPloV17BE4xiRHlewYhdIbxJ38
# tqMYWZnaZxeYwMDplxWcLqIzcE5iVUNMmRawgJl/fD8HluUD9g0FSr0G8JUxggHl
# MIIB4QIBATAzMB8xHTAbBgNVBAMMFFNvaGFuQ29kZVNpZ25pbmdDZXJ0AhAal/H3
# TszvlkTHj90yv9IJMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN3R7wnoxZ9uYtXHuqm5
# aH3J30sOEkQC5vr/4RSaYVNRMA0GCSqGSIb3DQEBAQUABIIBAAb/+KN2o5V3eYjG
# tUa+H9yMa8vUgAycJPjlYshQMcXTlikRXEYmQqQv+oX8azkwuh6Xma/cq0IF1REe
# /PrMD5ks4CGeZxgSDHcw4SLLO2tnrsCrezrsWx0JzuiHNSJfQk9cCxGR9mEdgSic
# JoNbzZ/mjtQjQZ4o7gsjIONMmYVggwsYQQL8gdNwD5BSJxTL7JTLKtaXkDlLQ2Wr
# +Pc+WG9WFAhHNgU1MoLDylrGXqC8XyZADjSoDWUs+L8MLIOjltotXloFYBr1NI6D
# oIXlgAL9NZBwsfS+bF5A4c6p32NeYb0A0Ze3GyGlyuvxXH+rFcicOcmgShERKiBp
# XEukbtQ=
# SIG # End signature block
