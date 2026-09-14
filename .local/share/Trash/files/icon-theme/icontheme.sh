#!/usr/bin/env bash 

# INSTALLING ICON THEME
git clone https://github.com/L4ki/Magna-Plasma-Themes.git
sudo mv Magna-Plasma-Themes/'Magna Icons Themes'/Magna-Dark-Icons /usr/share/icons/
sudo rm -rf Magna-Plasma-Themes
sleep 1

# USING XFCONF-QUERY TO ADJUST DEFAULT THEME
icon=/Net/IconThemeName
iconname="Magna-Dark-Icons"                                

xfconf-query -c xsettings -p $icon -s $iconname