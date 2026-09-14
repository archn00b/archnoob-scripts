#!/usr/bin/env bash

# INSTALLING ICON THEME

install_icon() {
git clone https://github.com/L4ki/Magna-Plasma-Themes.git
mv "Magna-Plasma-Themes/Magna Icons Themes"/* "$HOME/Icons"

sleep 2

# USING XFCONF-QUERY TO ADJUST DEFAULT ICON THEME
icon="/Net/IconThemeName"
iconname="Magna-Glassy-Dark-Icons"

xfconf-query \
    --channel xsettings \
    --property "$icon" \
    --create \
    --type string \
    --set "$iconname"


}

install_icon

