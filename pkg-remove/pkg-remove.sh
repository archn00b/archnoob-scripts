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
# PRINTING COLORS TO THE COMMAND LINE CHOOSE EITHER SYLE
######################################################################################################################################################
# tput setaf 0 = black 
# tput setaf 1 = red 
# tput setaf 2 = green
# tput setaf 3 = yellow 
# tput setaf 4 = dark blue 
# tput setaf 5 = purple
# tput setaf 6 = cyan 
# tput setaf 7 = gray 
# tput setaf 8 = light blue
# tput sgr0 = default
# printf "|039| \033[39mDefault \033[m  |049| \033[49mDefault \033[m  |037| \033[37mLight gray \033[m     |047| \033[47mLight gray \033[m\n"
# printf "|030| \033[30mBlack \033[m    |040| \033[40mBlack \033[m    |090| \033[90mDark gray \033[m      |100| \033[100mDark gray \033[m\n"
# printf "|031| \033[31mRed \033[m      |041| \033[41mRed \033[m      |091| \033[91mLight red \033[m      |101| \033[101mLight red \033[m\n"
# printf "|032| \033[32mGreen \033[m    |042| \033[42mGreen \033[m    |092| \033[92mLight green \033[m    |102| \033[102mLight green \033[m\n"
# printf "|033| \033[33mYellow \033[m   |043| \033[43mYellow \033[m   |093| \033[93mLight yellow \033[m   |103| \033[103mLight yellow \033[m\n"
# printf "|034| \033[34mBlue \033[m     |044| \033[44mBlue \033[m     |094| \033[94mLight blue \033[m     |104| \033[104mLight blue \033[m\n"
# printf "|035| \033[35mMagenta \033[m  |045| \033[45mMagenta \033[m  |095| \033[95mLight magenta \033[m  |105| \033[105mLight magenta \033[m\n"
# printf "|036| \033[36mCyan \033[m     |046| \033[46mCyan \033[m     |096| \033[96mLight cyan \033[m     |106| \033[106mLight cyan \033[m\n"
######################################################################################################################################################

ROOT_UID=0     # Only users with $UID 0 have root privileges.
E_NOTROOT=87   # Non-root exit error.
FILE="pkgremove.txt"

# Function to check if the script is run as root
check_root() {
    if [ "$UID" -ne "$ROOT_UID" ]; then
        tput setaf 1
        echo "###################################"
        echo "Must be root to run this script."
        echo "###################################"
        echo ""
        tput sgr0

        exit $E_NOTROOT
    fi
}

# Function to uninstall packages listed in the specified file
pkg_remove() {
    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    while IFS= read -r package || [ -n "$package" ]; do
        if [ -n "$package" ]; then
            if pacman -Qi "$package" &>/dev/null; then
                echo "Uninstalling $package..."
                sudo pacman -Rns --noconfirm "$package"
            else
                echo "$package is not installed, skipping..."
            fi
        fi
    done < "$FILE"

    echo "Uninstallation complete."
}

# Main function to orchestrate the script
main() {
    check_root
    pkg_remove
}

main





