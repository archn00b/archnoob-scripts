#!/usr/bin/env bash
set -euo pipefail



cp_destination="$HOME/wallpapers/"

change_wallpaper(){

    # Open Thunar for previews
    thunar "$cp_destination" &

    # Select wallpaper
    wallpaper=$(printf '%s\n' "$cp_destination"/*.jpg | fzf --prompt="Select wallpaper: ")

    # Set wallpaper on every connected monitor
    while read -r monitor; do
        property="/backdrop/screen0/monitor${monitor}/workspace0/last-image"

        xfconf-query -c xfce4-desktop -p "$property" -s "$wallpaper"
    done < <(xrandr --query | awk '$2 == "connected" {print $1}')
}

main(){
    change_wallpaper
}

main
