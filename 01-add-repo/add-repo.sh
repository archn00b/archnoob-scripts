#!/usr/bin/env bash

# Author: ArchNoob
# Website: https://www.github.com/ArchN00b

set -euo pipefail

#--------------------------------------------------------------------------------------------------
# Script directory
#--------------------------------------------------------------------------------------------------

installed_dir="$(dirname "$(readlink -f "$0")")"

#--------------------------------------------------------------------------------------------------
# Text formatting
#--------------------------------------------------------------------------------------------------

bold="$(tput setaf 2)$(tput bold)"
bolderror="$(tput setaf 3)$(tput bold)"
normal="$(tput sgr0)"

#--------------------------------------------------------------------------------------------------
# Add ArchN00B core-repo
#--------------------------------------------------------------------------------------------------

add_repo() {
    printf "%s\n" "${bold}Adding [core-repo] to /etc/pacman.conf...${normal}"

    if grep -qxF "[core-repo]" /etc/pacman.conf; then
        printf "%s\n" " [core-repo] already exists."
        return 0
    fi

    sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

[core-repo]
SigLevel = Optional TrustAll
Server = https://archn00b.github.io/$repo/$arch
EOF

    printf "%s\n" " [core-repo] added successfully."
}

#--------------------------------------------------------------------------------------------------
# Configure repositories
#--------------------------------------------------------------------------------------------------

add_repo || {
    printf "%s\n" "${bolderror}Error adding ArchN00B repository.${normal}"
    exit 1
}

#--------------------------------------------------------------------------------------------------
# Synchronize package databases
#--------------------------------------------------------------------------------------------------

printf "%s\n" "${bold}Synchronizing package databases...${normal}"

sudo pacman -Syy --noconfirm

#--------------------------------------------------------------------------------------------------
# Update system
#--------------------------------------------------------------------------------------------------

printf "%s\n" "${bold}Updating system...${normal}"

sudo pacman -Syu --noconfirm