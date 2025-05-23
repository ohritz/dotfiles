#!/bin/bash

get_version() {
  # Get Ubuntu version
  local repo_version=$(if command -v lsb_release &>/dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
  echo "$repo_version"
}

add_microsoft_repo() {
  # todo: make it conditional
  # check that repo is not already added

  local version="$(get_version)"
  # Download Microsoft signing key and repository
  wget "https://packages.microsoft.com/config/ubuntu/${version}/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb

  # Install Microsoft signing key and repository
  sudo dpkg -i packages-microsoft-prod.deb

  # Clean up
  rm packages-microsoft-prod.deb

  ## https://learn.microsoft.com/en-us/dotnet/core/install/linux-package-mixup?pivots=os-linux-ubuntu#i-need-a-version-of-net-that-isnt-provided-by-my-linux-distribution
  # touch /etc/apt/preferences
  # echo "Package: *dotnet* \nPin: origin "archive.ubuntu.com" \nPin-Priority: 1000" >>/etc/apt/preferences
}

install_packages() {
  sudo apt-get update &&
    sudo apt-get install -y \
      gpg-agent \
      python3 \
      python3-pip \
      pipx \
      python3-pygments \
      keychain \
      socat \
      subversion
}

add_microsoft_repo
install_packages
