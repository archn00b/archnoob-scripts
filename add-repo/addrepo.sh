#!/usr/bin/env bash

# Author: ArchNoob
# Website: https://www.github.com/ArchN00b

# Setting script PATH
installed_dir=$(dirname "$(readlink -f "$(basename "$(pwd)")")")

# Text formatting
bold=$(tput setaf 2 bold)
bolderror=$(tput setaf 3 bold)
normal=$(tput sgr0)

# Function to add ArchN00B core-repo to /etc/pacman.conf
add_repo() {
    printf "%s\n" "${bold}Adding [core-repo] to /etc/pacman.conf...${normal}"

    if ! grep -qxF "[core-repo]" /etc/pacman.conf; then
        {
            echo ""
            echo "[core-repo]"
            echo "SigLevel = Optional TrustAll"
            echo "Server = https://archn00b.github.io/\$repo/\$arch"
        } | sudo tee -a /etc/pacman.conf
    fi
}

# Update system and install necessary packages
sudo pacman -Syu --noconfirm
add_repo || { echo "${bolderror}Error adding ArchN00B repo to /etc/pacman.conf.${normal}"; exit 1; }

# Syncing the repositories
sudo pacman -Syy --noconfirm
