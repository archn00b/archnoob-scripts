#!/usr/bin/env bash

set -euo pipefail

##################################################################################################################
# Author    : ArchNoob
# Website   : https://www.github.com/ArchN00b
##################################################################################################################

bold=$(tput setaf 2 bold)
yellow=$(tput setaf 3 bold)
normal=$(tput sgr0)


if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root."
    exit 1
fi


addrepo() {

    echo "Checking ArchN00B repository..."

    if ! grep -q "^\[core-repo\]" /etc/pacman.conf; then

        echo "Adding ArchN00B repo..."

        sudo tee -a /etc/pacman.conf <<EOF

[core-repo]
SigLevel = Optional TrustAll
Server = https://archn00b.github.io/\$repo/\$arch

EOF

    else
        echo "ArchN00B repo already exists."
    fi
}


addrepo


echo "Updating system..."
sudo pacman -Syu --needed


echo "Installing SDDM..."

sudo pacman -S --needed \
    sddm \
    qt5-quickcontrols2 \
    archnoob-sddm-theme


echo "Configuring SDDM..."

if [[ -L /etc/systemd/system/display-manager.service ]]; then

    current_dm=$(basename "$(readlink /etc/systemd/system/display-manager.service)")

    sudo systemctl disable "$current_dm" || true

fi


sudo systemctl enable sddm


sudo mkdir -p /etc/sddm.conf.d


sudo tee /etc/sddm.conf.d/archnoobtheme.conf <<EOF
[Theme]
Current=archnoobtheme
EOF


echo
echo "#####################################"
echo "##### SDDM HAS BEEN INSTALLED ######"
echo "#####################################"