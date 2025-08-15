# Multi-Environment Dotfiles Setup

This dotfiles repository provides a reproducible and sophisticated setup across multiple environments, managed by [chezmoi](https://www.chezmoi.io) with extensive templating and environment-specific configurations.

## Supported Environments

- **Windows bare** (PowerShell, CMD) - *Planned*
- **Windows MSYS2** (zsh) - *Active*
- **Windows WSL2 Ubuntu** (zsh) - *Active*
- **Linux base** (zsh) - *Active*
- **macOS** (zsh) - *Planned*

## Environment Architecture Overview

### Linux and macOS
These environments follow a straightforward approach where all software is installed and executed from the same location, providing a unified development experience.

### Windows Multi-Layer Architecture
The Windows setup is more intricate, featuring three interconnected layers:

1. **Windows Host** - Native Windows applications and tools
2. **MSYS2** - Unix-like environment with Git for Windows integration
3. **WSL2** - Full Linux environment with Windows interop

Software distribution across these layers is carefully managed to avoid conflicts while maximizing functionality.

## Environment-Specific Configurations

### WSL2 (Windows Subsystem for Linux)

#### Package Management Stack
- **Homebrew** - Primary package manager for development tools
- **apt** - System package manager for Ubuntu
- **asdf** - Universal version manager for language runtimes
- **zcomet** - Zsh plugin manager
- **pipx** - Isolated Python application installer

#### Key Tools and Runtimes
**Language Runtimes (via asdf):**
- Node.js 22.17.0
- Python 3.10.4
- .NET 8.0.408
- direnv 2.36.0

**Development Tools (via Homebrew):**
- AWS CLI and IAM Authenticator
- Kubernetes tools (kubectl, openshift-cli, kube-score)
- Git tools (gh, git-delta, git-extras)
- Text processing (jq, yq, bat, eza)
- Navigation (zoxide, fzf)
- Documentation (tldr, bat-extras)

**System Tools (via apt):**
- Core utilities (curl, wget, procps, file)
- Development tools (build-essential, gcc)
- Python ecosystem (python3, python3-pip, pipx)
- Security tools (gpg-agent, dirmngr, gpg)
- Network tools (socat for WSL-specific SSH forwarding)

#### Windows Integration
- **1Password CLI** - Accessed via Windows interop (`op.exe`)
- **Keeper SSL Agent** - Windows-based with Linux socket forwarding
- **SSH Agent Forwarding** - Custom relay system using `npiperelay.exe`

### MSYS2 (Minimal SYStem 2)

#### Package Management
- **pacman** - MSYS2 package manager

#### Windows PATH Integration
MSYS2 integrates with Windows through these PATH entries:
```
C:\msys64\cmd
C:\msys64\usr\bin
C:\msys64\usr\local\bin
```

#### Git for Windows Integration
Following the [official guide](https://gitforwindows.org/install-inside-msys2-proper.html), Git for Windows is installed within MSYS2, making it available to both MSYS2 and Windows host.

#### MSYS2-Specific Packages
**Core System:**
- base, filesystem, msys2-runtime
- openssh, unzip, zsh

**Development Tools:**
- git-for-windows-keyring
- mingw-w64-x86_64-git (with credential manager and documentation)
- mingw-w64-x86_64-make

**Unix Utilities:**
- mingw-w64-x86_64-bat
- mingw-w64-x86_64-bc
- mingw-w64-x86_64-eza
- mingw-w64-x86_64-fzf
- mingw-w64-x86_64-jq
- mingw-w64-x86_64-python
- mingw-w64-x86_64-uchardet

**Additional Tools:**
- mingw-w64-x86_64-delta (via separate install script)

#### Environment Configuration
- **XDG Directories** - Configured in `/etc/zshenv` for chezmoi compatibility
- **Keeper Integration** - Uses Windows Keeper Commander via chezmoi config
- **Build Tools** - Stena-specific aliases and completions

### Windows Host (Planned)

#### Package Management Strategy
- **winget** - Windows package manager (currently tracking 50+ packages)
- **mise** - Universal tool manager (planned replacement for multiple version managers)
- **Chocolatey** - Alternative package manager (if needed)

#### Current Windows Applications (via winget)
**Development Tools:**
- Visual Studio 2022 (Professional/Enterprise)
- Visual Studio Code, Cursor
- .NET SDKs (6, 7, 8)
- Docker Desktop
- GitHub CLI
- Azure CLI

**Cloud & DevOps:**
- AWS CLI
- kubectl
- 1Password CLI
- Keeper Commander

**System Tools:**
- PowerShell
- Starship (cross-shell prompt)
- Windows Terminal
- Git for Windows

**Development Utilities:**
- Node.js (via NVM for Windows)
- Python
- Various database tools (MongoDB Compass, SQL Server Management Studio)

#### Planned Improvements
- **mise.jdx.dev** integration for unified tool management
- PowerShell profile management under chezmoi control
- Enhanced Windows-native development workflow

## Cross-Environment Tool Management

### Version Management Strategy
**Current:**
- **asdf** - Primary version manager in WSL/Linux
- **NVM for Windows** - Node.js version management in Windows
- **Multiple SDK installers** - .NET, Python, etc.

**Planned:**
- **mise** - Universal tool manager across all environments
- Unified version management strategy
- Simplified tool installation and updates

### Package Synchronization
**Shared Tools (installed in multiple environments):**
- Git (Windows host uses MSYS2 version)
- Docker (Windows host, accessible from WSL)
- kubectl (Windows host, accessible from WSL/MSYS2)
- Development SDKs (.NET, Node.js, Python)

**Environment-Specific Tools:**
- Unix utilities (bat, eza, fzf) - MSYS2 and WSL
- Shell-specific tools (zsh plugins) - WSL and Linux
- Windows-specific tools (PowerShell modules) - Windows host

## Security and Integration

### SSH Key Management
- **WSL**: Custom SSH relay system with Windows agent forwarding
- **MSYS2**: Direct SSH agent integration
- **Windows**: Native SSH client integration

### Password Management
- **1Password**: Windows-based with CLI interop
- **Keeper**: Windows-based with SSL agent forwarding to WSL

### GPG Integration
- **Commit Signing**: SSH key-based signing across environments
- **Key Management**: Centralized GPG configuration

## Environment Detection and Configuration

### chezmoi Templating
The setup uses sophisticated templating to detect and configure environments:

```toml
[data]
iswsl = {{ $iswsl }}
islinux = {{ $islinux }}
iswindows = {{ $iswindows }}
ismsys2 = {{ $ismsys2 }}
```

### Conditional Loading
- **WSL-specific**: SSH relay, build tools, Windows interop
- **MSYS2-specific**: Homebrew integration, Stena aliases
- **Linux-specific**: Standard Unix tooling
- **Windows-specific**: PowerShell configuration (planned)

## Setup and Maintenance

### Initial Setup
1. **WSL**: `setup.sh` script for automated environment preparation
2. **MSYS2**: Manual chezmoi installation with XDG configuration
3. **Windows**: Planned automated setup with winget and mise

### Package Updates
- **WSL**: `run_onchange_after_brew-list-load.sh.tmpl` for Homebrew updates
- **MSYS2**: `run_onchange_install_msys2_packages.sh.tmpl` for pacman updates
- **Windows**: Planned winget update automation

### Environment Synchronization
- **chezmoi**: Cross-environment configuration management
- **XDG Directories**: Consistent file organization
- **Version Files**: `.tool-versions` for asdf compatibility

## Future Enhancements

### Planned Improvements
1. **mise Integration**: Unified tool management across all environments
2. **Windows Native Support**: Full PowerShell and CMD configuration
3. **macOS Support**: Complete environment parity
4. **Enhanced Automation**: Automated environment detection and setup
5. **Performance Optimization**: Lazy loading and startup time improvements

### Tool Consolidation
- **Package Managers**: Reduce redundancy across environments
- **Version Management**: Unified approach with mise
- **Configuration**: Single source of truth for all environments

## Troubleshooting

### Common Issues
1. **PATH Conflicts**: Careful management of Windows/MSYS2 PATH integration
2. **Tool Duplication**: Avoid installing same tools in multiple environments
3. **SSH Forwarding**: WSL-specific relay system requires proper Windows interop
4. **Build Tools**: Environment-specific paths and configurations

### Environment Isolation
- **XDG Directories**: Proper isolation for chezmoi operations
- **Package Managers**: Environment-specific package lists
- **Configuration**: Conditional loading based on environment detection

---

*Last Updated: 2025-01-15*
*Status: Production Ready with Planned Enhancements*
