# Terminal Dotfiles Setup - Tool Catalog and Summary

This repository contains a sophisticated terminal setup managed by [chezmoi](https://www.chezmoi.io), featuring a highly optimized Zsh environment with modern CLI tools, development utilities, and extensive customizations for productivity.

## 🏗️ Infrastructure & Framework

### Core Shell Framework
- **zsh** - Advanced shell with extensive scripting capabilities
- **zcomet** - Ultra-lightweight Zsh plugin manager (faster than Oh My Zsh)
- **chezmoi** - Dotfiles manager with templating and multi-machine support
- **powerlevel10k** - High-performance Zsh prompt with instant prompt feature

### Package Management
- **Homebrew** - Primary package manager for macOS/Linux tools
- **asdf** - Universal version manager for development tools
- **pipx** - Isolated Python application installer

## 🎨 Shell Enhancement & Productivity

### Interactive Features
- **fast-syntax-highlighting** - Real-time syntax highlighting for commands
- **zsh-autosuggestions** - Fish-like command completion suggestions
- **zsh-history-substring-search** - Improved history search with substring matching
- **fzf** - Fuzzy finder for files, history, and command integration
- **fzf-tab** - Replace tab completion with fzf interface
- **zoxide** - Smart directory jumper (smarter `cd`)

### User Experience
- **alias-tips** - Suggests existing aliases for typed commands
- **zsh-titles** - Dynamic terminal title updates
- **eza** - Modern `ls` replacement with colors, icons, and git status
- **bat** - `cat` replacement with syntax highlighting and git integration

## 🛠️ Development Tools

### Language Runtimes (via asdf)
- **Node.js** (v22.17.0) - JavaScript runtime
- **Python** (v3.10.4) - Python interpreter
- **dotnet** (v8.0.408) - .NET SDK
- **direnv** (v2.36.0) - Environment variable management per directory

### Version Control & Git
- **git** - Version control with extensive aliases and configurations
- **gh** - GitHub CLI with custom completions
- **git-lfs** - Git Large File Storage support
- **SSH key management** - Multiple SSH keys for different contexts (personal, work)

### Code Editing & Diff Tools
- **Visual Studio Code** - Primary editor (configured as git merge/diff tool)
- **nano** - Fallback terminal editor
- Advanced git aliases for logging, branching, and workflow

## ☁️ Cloud & DevOps Tools

### Kubernetes & Container Management
- **kubectl** - Kubernetes command-line tool
- **openshift-cli** - OpenShift CLI
- **kube-score** - Kubernetes object analysis
- **docker** - Container runtime with custom aliases (`dc` for docker-compose)
- **AWS IAM Authenticator** - AWS authentication for Kubernetes

### Cloud & Infrastructure
- **AWS CLI tools** - Custom AWS helper functions
- **grpcurl** - gRPC testing tool
- **protobuf** - Protocol buffer support

### Data Processing & APIs
- **jq** - JSON processor and query tool
- **yq** - YAML processor
- **tldr** - Simplified man pages

## 🔧 Custom Functions & Automation

### AI Integration
- **ChatGPT CLI** - Custom function for OpenAI API integration with syntax highlighting
- Supports markdown highlighting via `highlight` command

### SSH & Security Tools
- **SSH agent forwarding** - WSL-specific SSH agent management
- **SSL certificate tools** - Custom SSL/TLS certificate management functions
- **GPG integration** - Commit signing with SSH keys
- **Multi-context SSH** - Separate keys for different organizations

### Development Workflow
- **Build tools integration** - Custom build and deployment helpers for Stena projects
- **Docker build automation** - Functions for building multiple project containers
- **AWS secret management** - Functions for fetching/uploading secrets
- **kubectl helpers** - Enhanced Kubernetes workflow functions

## 🖥️ System-Specific Features

### WSL (Windows Subsystem for Linux) Integration
- **SSH.exe aliases** - Use Windows SSH client from WSL
- **VPN kit support** - Network connectivity tools
- **Windows tool integration** - Access to Windows executables from WSL
- **Mount detection** - Automatic project path setup based on mounted drives

### Performance & Monitoring
- **Shell profiling** - Built-in performance monitoring with timing
- **Startup time tracking** - Measures and displays shell initialization time
- **Resource limits** - Optimized file descriptor limits
- **Lazy loading** - Efficient plugin loading strategies

## 📁 File Management & Organization

### Directory Structure
- **Custom project paths** - Organized development workspace
- **Automatic completions** - Custom completion functions
- **Color schemes** - Dracula-themed color configuration
- **File type associations** - Enhanced file handling

### Archive & Cleanup
- **Archived functions** - Historical function preservation
- **Selective file management** - `.chezmoiignore` for excluding files
- **Cleanup automation** - Automated package and dependency cleanup

## 🎯 Specialized Integrations

### Business/Work Context
- **Stena Line integration** - Custom Docker build functions for multiple microservices
- **Project-specific tooling** - Context-aware aliases and functions
- **Multi-organization git configs** - Automatic git configuration switching
- **Corporate tooling** - Integration with company-specific infrastructure

### Interactive Elements
- **Greeting system** - Welcome message with fortune and cowsay
- **Prompt messaging** - Status notifications and warnings
- **Smart aliases** - Context-aware command shortcuts
- **Help system** - Enhanced help pages with `bat` formatting

## 📊 Configuration Philosophy

This setup prioritizes:
- **Performance** - Fast startup times, efficient plugin loading
- **Modularity** - Separated concerns with individual configuration files
- **Maintainability** - Clear organization and documentation
- **Cross-platform compatibility** - Works on WSL, Linux, and macOS
- **Security** - Proper key management and signing
- **Productivity** - Extensive automation and shortcuts

## 🚀 Installation & Management

The entire setup is managed through chezmoi with:
- **Template-based configs** - Dynamic configuration based on environment
- **Automated installation** - Scripts for package installation and setup
- **Change detection** - Automatic updates when configuration changes
- **Backup & sync** - Version-controlled dotfiles across machines
- **Machine-specific customization** - Different configs for different environments

This configuration represents a professional-grade development environment optimized for DevOps workflows, container management, and multi-platform development.
