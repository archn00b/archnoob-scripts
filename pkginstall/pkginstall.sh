#!/usr/bin/env bash
set -euo pipefail
##################################################################################################################
# Author 	: ArchN00B
# Website   : https://www.github.com/archn00b
######################################################################################
#
#   ITS ALL IN YOUR HANDS. READ & OBSERVE SCRIPT ESPECIALLY COMMENTS
#
######################################################################################
#tput setaf 0 = black 
#tput setaf 1 = red 
#tput setaf 2 = green
#tput setaf 3 = yellow 
#tput setaf 4 = dark blue 
#tput setaf 5 = purple
#tput setaf 6 = cyan 
#tput setaf 7 = gray 
#tput setaf 8 = light blue
#tput sgr0 = default
######################################################################################


#ROOT_UID=0     # Only users with $UID 0 have root privileges.
E_NOTROOT=87   # Non-root exit error.


# Run as root, of course.
if [ "$UID" -ne "0" ]
then
  tput setaf 1
  echo "###################################"
  echo "Must be root to run this script."
  echo "###################################"
  tput sgr0
  echo ""
  exit $E_NOTROOT
fi

# ASSIGNING VARIABLES
logfile="/var/log/install_packages.log"
packages=("alacritty" "vim" "firefox") # use double quotes maintaing package name

# CHECK IF PACKAGE IS ALREADY INSTALLED
check_pkg() {
	pacman -Qi "$1" &> /dev/null
}

# INSTALLING PACKAGES
install_packages() {
	echo "Installing packages..." | tee -a $logfile
	for pkg in "${packages[@]}"; do
	    if check_pkg "$pkg"; then
		   tput setaf 1
	       echo "$pkg is already installed." | tee -a $logfile
		   echo ""
		   tput sgr0
	else
	       echo "Installing $pkg..." | tee -a $logfile
	       sudo pacman -S --noconfirm --needed "$pkg" # | tee -a >> $logfile 2>&1
	       if ! install_packages; then
		   echo "$pkg installed successfully" | tee -a $logfile
	       else
		   echo "Error installing $pkg..." | tee -a $logfile
	       fi
             fi
	  done
}

# INSTALLATION PROCESS MAIN FUNCTION
main() {
    check_pkg
    echo "Package installation complete." | tee -a $logfile
}
main
    
	       
