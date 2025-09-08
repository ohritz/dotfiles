function Invoke-Starship-TransientFunction {
    &starship module character
}

mise activate pwsh | Out-String | Invoke-Expression

$env:XDG_CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { "$HOME/.config" }
$env:XDG_CACHE_HOME = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { "$HOME/.cache" }
$env:XDG_DATA_HOME = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { "$HOME/.local/share" }
$env:XDG_STATE_HOME = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { "$HOME/.local/state" }

Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

Set-Alias -Name g -Value git

Invoke-Expression (&starship init powershell)

Enable-TransientPrompt
