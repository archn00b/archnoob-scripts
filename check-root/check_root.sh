##!/usr/bin/env bash
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
######################################################################################


ROOT_UID=0     # Only users with $UID 0 have root privileges.
E_NOTROOT=87   # Non-root exit error.


# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID" ]
then
  tput setaf 1
  echo "###################################"
  echo "Must be root to run this script."
  echo "###################################"
  tput sgr0
  echo ""
  exit $E_NOTROOT
fi
