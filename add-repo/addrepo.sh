#!/usr/bin/env bash 
#set -e
##################################################################################################################
# Author    : ArchNoob 
# Website   : https://www.github.com/ArchN00b
##################################################################################################################
# ITS ALL IN YOUR HANDS. READ SCRIPT & OBSERVE. 
##################################################################################################################
#tput setaf 0 = black
#tput setaf 1 = red
#tput setaf 2 = green
#tput setaf 3 = yellow
#tput setaf 4 = dark blue
#tput setaf 5 = purple
#tput setaf 6 = cyan
#tput setaf 7 = gray
#tput setaf 8 = light blue
##################################################################################################################
# Setting script PATH 
installed_dir=$(dirname $(readlink -f $(basename `pwd`)))
##################################################################################################################

bold=$(tput setaf 2 bold)      # makes text bold and sets color to 2
bolderror=$(tput setaf 3 bold) # makes text bold and sets color to 3
normal=$(tput sgr0)            # resets text settings back to normal

# ADDING ARCHN00B CORE-REPO TO /ETC/PACMAN.CONF
sudo pacman -Syu --noconfirm

addrepo() { \ 
    # Adding Archn00B core-repo to pacman.conf
    printf "%s\033[34m Adding [core-repo] to /etc/pacman.conf"
    grep -qxF "[core-repo]" /etc/pacman.conf ||
        ( echo " "; echo "[core-repo]"; echo "SigLevel = Optional TrustAll"; \
        echo "Server = https://archn00b.github.io/\$repo/\$arch") | sudo tee -a /etc/pacman.conf
}

addrepo || error "Error adding ArchN00B repo to /etc/pacman.conf."

# SYNCING THE REPOSITORIES
sudo pacman -Syy --noconfirm
