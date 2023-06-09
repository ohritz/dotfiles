#!/bin/bash

get_version() {
    # Get Ubuntu version
    local repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
    echo "$repo_version"
}

add_microsoft_repo()
{
    local version="$(get_version)"
    # Download Microsoft signing key and repository
    wget "https://packages.microsoft.com/config/ubuntu/${version}/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
    
    # Install Microsoft signing key and repository
    sudo dpkg -i packages-microsoft-prod.deb
    
    # Clean up
    rm packages-microsoft-prod.deb
}

install_packages() {
    sudo apt-get update && \
    sudo apt-get install -y dotnet-sdk-7.0 \
    dotnet-sdk-6.0 \
    gpg-agent
}

add_microsoft_repo
install_packages
