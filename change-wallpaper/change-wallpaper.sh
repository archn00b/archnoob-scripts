#!/usr/bin/env bash

git clone https://github.com/archn00b/wallpapers.git
rm -rf wallpapers/.git
rm -rf wallpapers/pushit2git.sh
sudo cp -rf wallpapers/* /usr/share/backgrounds/xfce/
rm -rf wallpapers
property=/backdrop/screen0/monitorDP-4/workspace0/last-image
bg=/usr/share/backgrounds/xfce/bg3.jpg

xfconf-query -c xfce4-desktop -p $property -s $bg