#!/usr/bin/env bash
#set -e
##################################################################################################################
# Author    : ArchNoob 
# Website   : https://www.github.com/ArchN00b
##################################################################################################################
# PLEASE READ SCRIPT TO KNOW WHAT'S BEING INSTALLED. REBOOT AFTER INSTALL.                                      #
##################################################################################################################

# Setting script PATH 
installed_dir=$(dirname "$(readlink -f "$(basename "$(pwd)")")")

sudo pacman -Syu


# SETTING DEFAULT BACKGROUND
git clone https://github.com/archn00b/wallpapers.git
rm -rf wallpapers/.git wallpapers/pushit2git.sh
sudo cp -r wallpapers/* /usr/share/backgrounds/xfce/
rm -rf wallpapers

# COMMAND TO SET BACKGROUND
xfconf-query -c xfce4-desktop -p /backdrop/screen0/None-1/workspace0/last-image -s /usr/share/backgrounds/xfce/bg3.jpg

echo "##########################################"
echo "##### INSTALLATION DONE, REBOOTING... #####"
echo "##########################################"
sleep 5
