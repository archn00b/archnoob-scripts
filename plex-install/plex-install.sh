#!/usr/bin/env bash

# INSTALLING PLEXMEDIA SERVER FROM AUR FIRST NEED YAY

sudo pacman -S yay --noconfirm 

# NOW INSTALL PLEX MEDIA SERVER
sudo yay -S plexmediaserver --noconfirm

# ENABLE SERVICE WITH SYSTEMCTL
sudo systemctl enabale plexmediaserver

# LETS START THE SERVER
sudo systemctl start plexmediaserver

# ALLOW THROUGH FIREWALL USING UFW
sudo pacman -S ufw

# COMMAND TO ALLOW PLEX MEDIA SERVER PORT THROUGH FIREWALL
sudo ufw allow 32400

# ACCESS PLEX MEDIA SERVER FROM HTTPS://HOST.ADDRESS:32400/web configure settings to personal preference
# NOW LETS INSTALL PLEX HTPC WE NEED SNAP FIRST
sudo yay -S snapd --noconfirm

# NOW WE HAVE TO ENABLE AND START THE SOCKET
sudo systemctl enable --now snapd.socket

# ADD /bin/snap to ENVVIORMENT
echo "export PATH=\$PATH:/snap/bin" >> ~/.bashrc
source ~/.bashrc

# NOW WE NEED FFMPEG6.1 THIS WILL TAKE AWHILE TO INSTALL
sudo yay -S ffmpeg6.1 --noconfirm

# NOW LETS INSTALL PLEX-HTPC
sudo snap install plex-htpc

# SHOULD BE GOOD TO GO START PLEX-HTPC FROM DMENU OR COMMAND LINE LINK YOUR TV AT HHTPS://PLEXTV/LINK

