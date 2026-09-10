#!/usr/bin/env bash 

addrepo() {  
    # Adding Archn00B core-repo to pacman.conf
    printf "%s\033[34m Adding [core-repo] to /tmp/archlive/etc/pacman.conf"
    grep -qxF "[core-repo]" /tmp/archlive/pacman.conf ||
        ( echo " "; echo "[core-repo]"; echo "SigLevel = Optional TrustAll"; \
        echo "Server = https://archn00b.github.io/\$repo/\$arch") | sudo tee -a /tmp/archlive/pacman.conf
}
addrepo

