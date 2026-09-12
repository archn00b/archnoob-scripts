#!/usr/bin/env bash
set -euo pipefail


property="/backdrop/screen0/monitorDP-1/workspace0/last-image"
bg="/usr/share/backgrounds/xfce/bg3.jpg"
cp_destination="/usr/share/backgrounds/xfce/"

change_wallpaper(){
    git clone https://github.com/archn00b/wallpapers.git
    sudo cp -rf wallpapers/* "$cp_destination"
    rm -rf wallpapers

    xfconf-query -c xfce4-desktop -p "$property" -s "$bg"
}

main(){
  change_wallpaper
}

main