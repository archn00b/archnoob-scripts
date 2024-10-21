#!/usr/bin/env bash 
#set -e
##################################################################################################################
# Author    : ArchNoob 
# Website   : https://www.github.com/ArchN00b
##################################################################################################################

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
sudo pacman -Syu

addrepo() { \
    printf "%s\n" "## Adding repositories to /etc/pacman.conf."

    # Adding Archn00B core-repo to pacman.conf
    printf "%s" "Adding repo " && printf "%s" "${bold}[core-repo] " && printf "%s\n" "${normal}to /etc/pacman.conf."
    grep -qxF "[core-repo]" /etc/pacman.conf ||
        ( echo " "; echo "[core-repo]"; echo "SigLevel = Optional TrustAll"; \
        echo "Server = https://archn00b.github.io/\$repo/\$arch") | sudo tee -a /etc/pacman.conf
}

addrepo || error "Error adding ArchN00B repo to /etc/pacman.conf."

# INSTALLING SDDM AND DEPENDICIES 
sudo pacman -S sddm qt5-quickcontrols2 archnoob-sddm-theme

# MAKING SDDM DEFAULT DISPLAY MANAGER
# Disable the current login manager
sudo systemctl disable "$(grep '/usr/s\?bin' /etc/systemd/system/display-manager.service | awk -F / '{print $NF}')" || echo "Cannot disable current display manager."
# Enable sddm as login manager
sudo systemctl enable sddm
printf "%s\n" "Enabling and configuring ${bold}SDDM ${normal}as the login manager."

## Make archnoob-sddm-theme the default sddm theme ##
# This is the sddm system configuration file.
[ -f "/usr/lib/sddm/sddm.conf.d/default.conf" ] && \
    sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /usr/lib/sddm/sddm.conf.d/archnoobtheme.conf && \
    [ -d "/etc/sddm.conf.d/" ] || sudo mkdir -p /etc/sddm.conf.d/ && \
    [ -f "/usr/lib/sddm/sddm.conf.d/archnoobtheme.conf" ] && \
    sudo mv /usr/lib/sddm/sddm.conf.d/archnoobtheme.conf /etc/sddm.conf.d/ && \
    sudo sed -i 's/^Current=*.*/Current=archnoobtheme/g' /etc/sddm.conf.d/archnoobtheme.conf

echo "#####################################"
echo "####### SDDM HAS BEEN INSTALLED "
echo "#####################################"