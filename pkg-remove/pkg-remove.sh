#!/usr/bin/env bash 
#set -e
##################################################################################################################
# Author    : ArchNoob 
# Website   : https://www.github.com/archn00b
##################################################################################################################
#
#   PLEASE READ THE SCRIPT SO YOU KNOW WHAT PACKAGES ARE BEING INSTALLED. USE AT OWN RISK 
#
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

installed_dir=$(dirname $(readlink -f $(basename `pwd`)))

###################################################################################################################################
# RUN THIS COMMAND FIRST sudo pacman -Q > pkg-remove.txt. REMOVE PKG'S YOU DONT WANT IN PKG-REMOVE.TXT.
# THEN RUN SCRIPT. IT'S IN YOUR HANDS. YOU CAN ALSO TRY PACMAN -RSU TO GET RID OF DEPENDECIES
###################################################################################################################################

file="pkg-remove.txt"

for pkg in $(awk '{print $1}' $file)
do
   if pacman -Rsn &> /dev/null; then
        tput setaf 1
        echo "#################################################################"
        echo "######### $pkg in pkg.txt already installed. "
        echo "#################################################################"
        echo
        tput sgr0
    else
        tput setaf 6
        echo "#################################################################"
        echo "######### $pkg in pkg.txt is being removed. "
        echo "#################################################################"
        sudo pacman -Rsn --noconfirm $pkg 
        echo
        tput sgr0        
    fi
done

