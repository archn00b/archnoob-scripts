#!/usr/bin/env bash

set -Eeuo pipefail

##################################################################################################################
# Author    : ArchN00B
# Website   : https://www.github.com/archn00b
#
# Interactive ISO Burner
##################################################################################################################

ROOT_UID=0
E_NOTROOT=87

# -------------------------------------------------------------------------------------------------
# COLORS
# -------------------------------------------------------------------------------------------------

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)

# -------------------------------------------------------------------------------------------------
# USER HOME
# -------------------------------------------------------------------------------------------------

USER_HOME="$HOME"

if [[ -n "${SUDO_USER:-}" ]]; then
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

# -------------------------------------------------------------------------------------------------
# GLOBAL VARIABLES
# -------------------------------------------------------------------------------------------------

iso=""
disk=""

# Arrays
isos=()
disks=()

# -------------------------------------------------------------------------------------------------
# ROOT CHECK
# -------------------------------------------------------------------------------------------------

check_root() {

    if [[ "$UID" -ne "$ROOT_UID" ]]; then

        printf "%sERROR:%s Must be run as root.\n" \
            "$RED" "$NORMAL"

        echo
        echo "Run it with:"
        echo
        echo "    sudo $0"

        exit "$E_NOTROOT"
    fi
}

# -------------------------------------------------------------------------------------------------
# FIND ISO FILES
# -------------------------------------------------------------------------------------------------

find_isos() {

    mapfile -t isos < <(
        find "$USER_HOME" \
            -type f \
            -iname "*.iso" \
            -print 2>/dev/null |
        sort
    )

    if (( ${#isos[@]} == 0 )); then

        printf "%sERROR:%s No ISO files found.\n" \
            "$RED" "$NORMAL"

        echo
        echo "Search location:"
        echo "    $USER_HOME"

        exit 1
    fi
}

# -------------------------------------------------------------------------------------------------
# CHOOSE ISO
# -------------------------------------------------------------------------------------------------

choose_iso() {

    find_isos

    echo
    printf "%sAvailable ISO files:%s\n" \
        "$CYAN" "$NORMAL"

    echo

    for i in "${!isos[@]}"; do

        printf "  %d) %s\n" \
            "$((i + 1))" \
            "${isos[$i]}"

    done

    echo

    while true; do

        read -rp "Choose an ISO [1-${#isos[@]}]: " choice

        # Must be a number
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then

            printf "%sERROR:%s Enter a number.\n" \
                "$RED" "$NORMAL"

            continue
        fi

        # Must be within array bounds
        if (( choice < 1 || choice > ${#isos[@]} )); then

            printf "%sERROR:%s Choose 1-%d.\n" \
                "$RED" \
                "$NORMAL" \
                "${#isos[@]}"

            continue
        fi

        # Convert human selection to array index
        iso="${isos[$((choice - 1))]}"

        break
    done

    echo
    printf "%sSelected ISO:%s\n" \
        "$GREEN" "$NORMAL"

    echo "    $iso"
}

# -------------------------------------------------------------------------------------------------
# FIND PHYSICAL DISKS
# -------------------------------------------------------------------------------------------------

find_disks() {

    mapfile -t disks < <(
        lsblk -dnpo NAME,TYPE |
        awk '$2 == "disk" {print $1}'
    )

    if (( ${#disks[@]} == 0 )); then

        printf "%sERROR:%s No physical disks detected.\n" \
            "$RED" "$NORMAL"

        echo
        echo "Run:"
        echo
        echo "    lsblk"

        exit 1
    fi
}

# -------------------------------------------------------------------------------------------------
# CHOOSE DISK
# -------------------------------------------------------------------------------------------------

choose_disk() {

    find_disks

    echo
    printf "%sAvailable disks:%s\n" \
        "$CYAN" "$NORMAL"

    echo

    for i in "${!disks[@]}"; do

        local current_disk="${disks[$i]}"
        local size
        local model

        size="$(lsblk -dnro SIZE "$current_disk")"

        model="$(
            lsblk -dnro MODEL "$current_disk" |
            sed 's/[[:space:]]*$//'
        )"

        printf "  %d) %-15s %-10s %s\n" \
            "$((i + 1))" \
            "$current_disk" \
            "$size" \
            "${model:-Unknown}"

    done

    echo

    while true; do

        read -rp "Choose target disk [1-${#disks[@]}]: " choice

        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then

            printf "%sERROR:%s Enter a number.\n" \
                "$RED" "$NORMAL"

            continue
        fi

        if (( choice < 1 || choice > ${#disks[@]} )); then

            printf "%sERROR:%s Choose 1-%d.\n" \
                "$RED" \
                "$NORMAL" \
                "${#disks[@]}"

            continue
        fi

        disk="${disks[$((choice - 1))]}"

        break
    done

    # Verify it is actually a block device
    if [[ ! -b "$disk" ]]; then

        printf "%sERROR:%s %s is not a block device.\n" \
            "$RED" "$NORMAL" "$disk"

        exit 1
    fi

    # Verify it is a whole disk
    if [[ "$(lsblk -dnro TYPE "$disk")" != "disk" ]]; then

        printf "%sERROR:%s %s is not a whole disk.\n" \
            "$RED" "$NORMAL" "$disk"

        exit 1
    fi
}

# -------------------------------------------------------------------------------------------------
# SHOW TARGET INFORMATION
# -------------------------------------------------------------------------------------------------

show_target() {

    local size
    local model
    local serial

    size="$(lsblk -dnro SIZE "$disk")"

    model="$(
        lsblk -dnro MODEL "$disk" |
        sed 's/[[:space:]]*$//'
    )"

    serial="$(
        lsblk -dnro SERIAL "$disk" |
        sed 's/[[:space:]]*$//'
    )"

    echo
    echo "============================================================"
    printf "                    %sREADY TO WRITE%s\n" \
        "$YELLOW" "$NORMAL"
    echo "============================================================"
    echo

    printf "%sISO:%s\n" "$CYAN" "$NORMAL"
    echo "    $iso"

    echo

    printf "%sTARGET DISK:%s\n" "$CYAN" "$NORMAL"
    echo "    Device : $disk"
    echo "    Size   : $size"
    echo "    Model  : ${model:-Unknown}"
    echo "    Serial : ${serial:-Unknown}"

    echo

    printf "%sWARNING:%s\n" "$RED" "$NORMAL"
    echo "    EVERYTHING on $disk will be destroyed."

    echo
}

# -------------------------------------------------------------------------------------------------
# CHECK MOUNTED PARTITIONS
# -------------------------------------------------------------------------------------------------

check_mounted() {

    local mounted_partitions

    mounted_partitions="$(
        lsblk -lnpo NAME,MOUNTPOINTS "$disk" |
        awk '$2 != "" {print $1}'
    )"

    if [[ -z "$mounted_partitions" ]]; then

        printf "%sNo mounted partitions detected.%s\n" \
            "$GREEN" "$NORMAL"

        return 0
    fi

    echo
    printf "%sMounted partitions detected:%s\n" \
        "$YELLOW" "$NORMAL"

    echo

    while IFS= read -r partition; do

        [[ -z "$partition" ]] && continue

        echo "    $partition"

    done <<< "$mounted_partitions"

    echo
    printf "%sUnmounting partitions...%s\n" \
        "$YELLOW" "$NORMAL"

    while IFS= read -r partition; do

        [[ -z "$partition" ]] && continue

        if ! umount "$partition"; then

            printf "%sERROR:%s Could not unmount %s\n" \
                "$RED" "$NORMAL" "$partition"

            exit 1
        fi

    done <<< "$mounted_partitions"

    echo
    printf "%sPartitions successfully unmounted.%s\n" \
        "$GREEN" "$NORMAL"
}

# -------------------------------------------------------------------------------------------------
# CONFIRM WRITE
# -------------------------------------------------------------------------------------------------

confirm_write() {

    echo
    printf "%sTHIS ACTION CANNOT BE UNDONE.%s\n" \
        "$RED" "$NORMAL"

    echo

    echo "ISO:"
    echo "    $iso"

    echo

    echo "TARGET:"
    echo "    $disk"

    echo

    echo "To continue, type exactly:"
    echo

    printf "    ERASE %s\n" "$disk"

    echo

    read -rp "Confirmation: " confirmation

    if [[ "$confirmation" != "ERASE $disk" ]]; then

        echo
        printf "%sOperation cancelled.%s\n" \
            "$YELLOW" "$NORMAL"

        exit 0
    fi
}

# -------------------------------------------------------------------------------------------------
# BURN ISO
# -------------------------------------------------------------------------------------------------

burn_iso() {

    echo
    printf "%sStarting ISO write...%s\n" \
        "$GREEN" "$NORMAL"

    echo

    dd \
        if="$iso" \
        of="$disk" \
        bs=4M \
        status=progress \
        conv=fsync \
        oflag=direct

    echo

    printf "%sSynchronizing data...%s\n" \
        "$CYAN" "$NORMAL"

    sync

    echo

    printf "%sISO successfully written to %s%s%s\n" \
        "$GREEN" "$disk" "$NORMAL" "$NORMAL"
}

# -------------------------------------------------------------------------------------------------
# ERROR HANDLER
# -------------------------------------------------------------------------------------------------

error_handler() {

    local exit_code=$?

    printf "\n%sERROR:%s Script failed with exit code %d.\n" \
        "$RED" "$NORMAL" "$exit_code"

    exit "$exit_code"
}

# -------------------------------------------------------------------------------------------------
# INTERRUPT HANDLER
# -------------------------------------------------------------------------------------------------

interrupt_handler() {

    echo
    printf "%sOperation interrupted.%s\n" \
        "$YELLOW" "$NORMAL"

    exit 130
}

trap error_handler ERR
trap interrupt_handler INT TERM

# -------------------------------------------------------------------------------------------------
# MAIN
# -------------------------------------------------------------------------------------------------

main() {

    check_root

    choose_iso

    choose_disk

    show_target

    check_mounted

    confirm_write

    burn_iso
}

main "$@"
