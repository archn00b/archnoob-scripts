#!/usr/bin/env bash 
#set -e
##################################################################################################################
# Author    : ArchNoob 
# Website   : https://www.github.com/ArchN00b
##################################################################################################################
### ITS ALL IN YOUR HANDS. PLEASE READ SCRIPT SO YOU KNOW WHATS BEING INSTALLED. REBOOT AFTER INSTALL            #
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

# INSTALLING PKG'S FOR DESKTOP ENVIORMENT

file="x86_64.txt"

for pkg in $(awk '{print $1}' $file)
do
	if pacman -Qi $pkg &> /dev/null; then
        tput setaf 1
        echo "#################################################################"
        echo "######### $pkg already installed. "
        echo "#################################################################"
        echo
        tput sgr0
    else
        tput setaf 3
        echo "#################################################################"
        echo "######### $pkg is being installed. "
        echo "#################################################################"
        sudo pacman -Syu --noconfirm --needed $pkg
        echo
        tput sgr0        
    fi
done

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

# INSTALL ALACRITTY TERMINAL WITH THEME
[ -d $HOME/.config/alacritty/ ] || mkdir -p $HOME/.config/alacrity/ && \
[ -d $HOME/.conf/alacritty/ ] && sudo cp -r /etc/skel/.config/alacritty/alacritty.toml $HOME/.config/alacritty/

# INSTALLING STARSHIP

printf "%s\n" " Installing Starship." 

[ -d $HOME/.config/ ] && sudo cp -r /etc/skel/.config/starship.toml $HOME/.config/
[ -f ~/.bashrc ] && cp  ~/.bashrc ~/.bashrc.bak."$(date +"%Y%m%d_%H%M%S")"
[ -f ~/.bashrc ] && \
echo '
#including starship
eval "$(starship init bash)" ' >> ~/.bashrc && source ~/.bashrc
sleep 3

# INSTALLING ICON THEME
git clone https://github.com/L4ki/Magna-Plasma-Themes.git
sudo mv Magna-Plasma-Themes/'Magna Icons Themes'/Magna-Dark-Icons /usr/share/icons/
sudo rm -rf Magna-Plasma-Themes
sleep 1

# USING XFCONF-QUERY TO ADJUST DEFAULT THEME
icon=/Net/IconThemeName
iconname="Magna-Dark-Icons"                                

xfconf-query -c xsettings -p $icon -s $iconname

# CHANGING THE DEFAULT THEME ON XFCE4 USING XFCONF-QUERY
theme=/Net/ThemeName
themename="Adwaita-dark"                  

xfconf-query -c xsettings -p $theme -s $themename

# SETTING DEFAULT BACKGROUND
git clone https://github.com/archn00b/wallpapers.git
rm -rf wallpapers/.git
rm -rf wallpapers/pushit2git.sh
cp -r wallpapers/* /usr/share/backgrounds/xfce/
rm -rf wallpapers
# CHANNEL THAT NEEDS TO BE CHANGED
bgpath=/backdrop/screen0/monitorDP-4/workspace0/last-image

# PATH TO BACKGROUND IMAGE 
bg=/usr/share/backgrounds/xfce/bg3.jpg

# COMMAND TO SET BACKGROUND
xfconf-query -c xfce4-desktop -p $bgpath -s $bg 

echo "##########################################"
echo "##### INSTALLATION DONE REBOOTING "
echo "##########################################"
sleep 5
reboot 








 
