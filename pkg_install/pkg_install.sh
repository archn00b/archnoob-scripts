#!/usr/bin/env bash
set -euo pipefail

##################################################################################################################
# Author     : ArchN00B
# Website    : https://www.github.com/archn00b
##################################################################################################################
#
#   ITS ALL IN YOUR HANDS. READ & OBSERVE SCRIPT ESPECIALLY COMMENTS
#
##################################################################################################################

# tput setaf 0 = black
# tput setaf 1 = red
# tput setaf 2 = green
# tput setaf 3 = yellow
# tput setaf 4 = dark blue
# tput setaf 5 = purple
# tput setaf 6 = cyan
# tput setaf 7 = gray
# tput setaf 8 = light blue
# tput sgr0    = default
##################################################################################################################

E_NOTROOT=87

# ------------------------------------------------------------------------------------------------
# ROOT CHECK
# ------------------------------------------------------------------------------------------------

if [[ "$UID" -ne 0 ]]; then
    tput setaf 1
    echo "###################################"
    echo "Must be root to run this script."
    echo "###################################"
    tput sgr0
    echo ""
    exit "$E_NOTROOT"
fi

# ------------------------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------------------------

logfile="/var/log/install_packages.log"

packages=(
    sddm
    alacritty
    starship
    lsd
)

# ------------------------------------------------------------------------------------------------
# CHECK IF PACKAGE IS ALREADY INSTALLED
# ------------------------------------------------------------------------------------------------

check_pkg() {
    pacman -Qi "$1" &>/dev/null
}

# ------------------------------------------------------------------------------------------------
# INSTALL PACKAGES
# ------------------------------------------------------------------------------------------------

install_packages() {

    echo "Installing packages..." | tee -a "$logfile"
    echo ""

    for pkg in "${packages[@]}"; do

        if check_pkg "$pkg"; then

            tput setaf 1
            echo "$pkg is already installed." | tee -a "$logfile"
            tput sgr0
            echo ""

        else

            echo "Installing $pkg..." | tee -a "$logfile"

            if pacman -S --noconfirm --needed "$pkg"; then

                tput setaf 2
                echo "$pkg installed successfully." | tee -a "$logfile"
                tput sgr0

            else

                tput setaf 1
                echo "Error installing $pkg." | tee -a "$logfile"
                tput sgr0

                return 1
            fi

            echo ""
        fi

    done
}

# ------------------------------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------------------------------

main() {

    install_packages

    echo ""
    echo "Package installation complete." | tee -a "$logfile"
}

main
