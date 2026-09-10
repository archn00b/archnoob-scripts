#!/bin/bash

set -e

packages_file="/tmp/archlive/packages.x86_64"

rm -rf /tmp/archlive
mkdir -p /tmp/archlive

# INSTALLING ARCHISO
pacman --noconfirm -S archiso



cp -r /usr/share/archiso/configs/releng/* /tmp/archlive/

addrepo() {  
    # Adding Archn00B core-repo to pacman.conf
    printf "%s\033[34m Adding [core-repo] to /tmp/archlive/etc/pacman.conf"
    grep -qxF "[core-repo]" /tmp/archlive/pacman.conf ||
        ( echo " "; echo "[core-repo]"; echo "SigLevel = Optional TrustAll"; \
          echo "Server = https://archn00b.github.io/\$repo/\$arch") | sudo tee -a /tmp/archlive/pacman.conf
}
addrepo

# install starship
mkdir -p /tmp/archlive/airootfs/usr/share/fonts/
cp -rf FiraCode /tmp/archlive/airootfs/usr/share/fonts/ 


# ADDING USER FILES TO ARCHISO
cp -rf users/* /tmp/archlive/airootfs/etc/
cp -rf sddm.conf.d /tmp/archlive/airootfs/etc/
cp -rf sudoers.d /tmp/archlive/airootfs/etc/
cp -rf profiledef.sh /tmp/archlive/ 
cp -rf pam.d /tmp/archlive/airootfs/etc/
mkdir -p /tmp/archlive/airootfs/etc/skel/.config/
cp -rf starship.toml /tmp/archlive/airootfs/etc/skel/.config/
cp -rf .bashrc /tmp/archlive/airootfs/etc/skel/.bashrc
sudo ln -s /usr/lib/systemd/system/sddm.service /tmp/archlive/airootfs/etc/systemd/system/display-manager.service

# Packages to add to the archiso profile packages
packages=(
	xfce4
	xfce4-goodies
	xorg
	sddm
	alacritty
	archnoob-alacritty
	archnoob-sddm-theme
	firefox
	lsd
	starship
)

# Add packages to the archiso profile packages
for package in "${packages[@]}"; do
	echo "$package" >> "$packages_file"
done

find /tmp/archlive
cd /tmp/archlive


rm -rf /tmp/archlive/work/*


mkarchiso -v -w work/ -o out/ ./
