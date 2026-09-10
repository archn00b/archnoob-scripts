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

# ADDING ARCHN00B CORE-REPO TO /ETC/PACMAN.CONF
sudo pacman -Syu

add_repo() {
    echo "## Adding repositories to /etc/pacman.conf."
    
    if ! grep -qxF "[core-repo]" /etc/pacman.conf; then
        echo "[core-repo]" | sudo tee -a /etc/pacman.conf
        echo "SigLevel = Optional TrustAll" | sudo tee -a /etc/pacman.conf
        echo "Server = https://archn00b.github.io/\$repo/\$arch" | sudo tee -a /etc/pacman.conf
    fi
}

add_repo

# INSTALLING PKG'S FOR DESKTOP ENVIRONMENT
file="x86_64.txt"

while read -r pkg; do
    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "\e[31m#################################################################\n######### $pkg already installed.\n#################################################################\e[0m"
    else
        echo -e "\e[33m#################################################################\n######### Installing $pkg...\n#################################################################\e[0m"
        sudo pacman -Syu --noconfirm --needed "$pkg"
    fi
done < <(awk '{print $1}' "$file")

# INSTALLING SDDM AND DEPENDENCIES 
sudo pacman -S --noconfirm sddm qt5-quickcontrols2 archnoob-sddm-theme

# MAKE SDDM DEFAULT DISPLAY MANAGER
current_manager=$(grep '/usr/s\?bin' /etc/systemd/system/display-manager.service | awk -F / '{print $NF}')
if [ -n "$current_manager" ]; then
    sudo systemctl disable "$current_manager" || echo "Cannot disable current display manager."
fi

sudo systemctl enable sddm
echo "Enabling and configuring SDDM as the login manager."

# CONFIGURE SDDM THEME
if [ -f "/usr/lib/sddm/sddm.conf.d/default.conf" ]; then
    sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /usr/lib/sddm/sddm.conf.d/archnoobtheme.conf
    [ ! -d "/etc/sddm.conf.d/" ] && sudo mkdir -p /etc/sddm.conf.d/
    
    if [ -f "/usr/lib/sddm/sddm.conf.d/archnoobtheme.conf" ]; then
        sudo mv /usr/lib/sddm/sddm.conf.d/archnoobtheme.conf /etc/sddm.conf.d/
        sudo sed -i 's/^Current=.*/Current=archnoobtheme/' /etc/sddm.conf.d/archnoobtheme.conf
    fi
fi

echo "#####################################"
echo "####### SDDM HAS BEEN INSTALLED "
echo "#####################################"

# INSTALL ALACRITTY TERMINAL WITH THEME
mkdir -p "$HOME/.config/alacritty/"
sudo cp -r /etc/skel/.config/alacritty/alacritty.toml "$HOME/.config/alacritty/" 2>/dev/null

# INSTALLING STARSHIP
echo "Installing Starship." 
mkdir -p "$HOME/.config/"
sudo cp -r /etc/skel/.config/starship.toml "$HOME/.config/"

if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.bak."$(date +"%Y%m%d_%H%M%S")"
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    source ~/.bashrc
fi

# INSTALLING ICON THEME
git clone https://github.com/L4ki/Magna-Plasma-Themes.git
sudo mv Magna-Plasma-Themes/'Magna Icons Themes'/Magna-Dark-Icons /usr/share/icons/
rm -rf Magna-Plasma-Themes

# USING XFCONF-QUERY TO ADJUST DEFAULT THEME
xfconf-query -c xsettings -p /Net/IconThemeName -s "Magna-Dark-Icons"
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"

# SETTING DEFAULT BACKGROUND
git clone https://github.com/archn00b/wallpapers.git
rm -rf wallpapers/.git wallpapers/pushit2git.sh
sudo cp -r wallpapers/* /usr/share/backgrounds/xfce/
rm -rf wallpapers

# COMMAND TO SET BACKGROUND
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorDP-4/workspace0/last-image -s /usr/share/backgrounds/xfce/bg3.jpg

echo "##########################################"
echo "##### INSTALLATION DONE, REBOOTING... #####"
echo "##########################################"
sleep 5
reboot
