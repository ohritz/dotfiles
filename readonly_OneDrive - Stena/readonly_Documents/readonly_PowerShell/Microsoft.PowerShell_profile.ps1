
function Invoke-Starship-TransientFunction {
    &starship module character
}

function Invoke-Starship-PreCommand {
  $host.ui.RawUI.WindowTitle = "$pwd `a"
}

$env:XDG_CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { "$HOME/.config" }
$env:XDG_CACHE_HOME = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { "$HOME/.cache" }
$env:XDG_DATA_HOME = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { "$HOME/.local/share" }
$env:XDG_STATE_HOME = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { "$HOME/.local/state" }

Set-Alias -Name g -Value git

$ENV:EDITOR = 'code'
$env:PROJECT_PATHS = "C:\stenadev\;C:\stenadev\nemo\;C:\stenadev\freight-ca\;C:\stenadev\lab\"
Import-Module PoshPj

op completion powershell | Out-String | Invoke-Expression

Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Import-Module posh-git

Import-Module PSFzf
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -TabExpansion

Import-Module StarshipInit

# Enable-TransientPrompt

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

Import-Module Sohan.Utils

Import-Module ZoxideInit
##Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

# SIG # Begin signature block
# MIIFfAYJKoZIhvcNAQcCoIIFbTCCBWkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUysAleikgFT8uDmS5i9NhWCq4
# AFigggMSMIIDDjCCAfagAwIBAgIQGpfx907M75ZEx4/dMr/SCTANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUEwtWgEaVpmG6rY/ZUEvK8ZJ/tTEwDQYJKoZIhvcNAQEBBQAEggEA
# fsL9J9+1Io3hgdxQ0AlvQoKRO1Hc/9OGvZT8UKxbVr0dKEp4b2P73JroggnS4K+P
# qisoYHmEpEz6snayABKChZxX1yxIfer0yMEacwPHW5wVE6ri6+ESDWmZn0ovTEVq
# Cdih3XCtBCOljBa9TuItU3fHc3t7mdF8u0UIju9KgiNUtEKW/RfS3GQ9Wk1XJ/k2
# F1pbm4pu8wQA4Rc1Ii9b3Zq8ThrYWHIogFI/eC3lW3/hTDdE1qWEKBxPDn++sxG4
# SC7D0hoPWcdoVT53KXzrGN3ykRtP0PwzP/anF151YgeGdYLbH/z1wozkX3T/GEme
# nkqQcvnGTHLbHW3R92iNEg==
# SIG # End signature block

