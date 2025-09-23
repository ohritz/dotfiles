The path exports used in msys2 was

"/c/Users/sofe/AppData/Local/Microsoft/WinGet/Packages/jdx.mise_Microsoft.Winget.Source_8wekyb3d8bbwe/mise/bin"
"/c/Users/sofe/.local/share/mise/shims"

and the config exports where:

{{ if .chezmoi.config.data.ismsys2 }}
export MISE_DATA_DIR=/c/Users/sofe/.local/share/mise
export MISE_CACHE_DIR=/c/Users/sofe/.cache/mise
export MISE_GLOBAL_CONFIG_FILE=/c/Users/sofe/.config/mise/config.toml
export MISE_GLOBAL_CONFIG_ROOT=/c/Users/sofe
export MISE_OS="windows"
export MISE_WINDOWS_SHIM_MODE="hardlink"
{{ end }}
