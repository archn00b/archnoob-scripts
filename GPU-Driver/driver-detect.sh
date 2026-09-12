#!/usr/bin/env bash

##################################################################################################################
# ArchN00B NVIDIA UNIVERSAL DRIVER INSTALLER
#
# Author  : ArchN00B
# Version : 2.0.0
#
# Website : https://www.github.com/ArchN00b
#
##################################################################################################################
#
# NVIDIA-ONLY DRIVER INSTALLER FOR ARCH LINUX
#
# This script identifies NVIDIA GPUs using their hardware family/codename
# rather than relying primarily on marketing model names.
#
# Examples:
#
#   GP102  -> Pascal
#   GP104  -> Pascal
#   GM204  -> Maxwell
#   TU102  -> Turing
#   GA102  -> Ampere
#   AD102  -> Ada Lovelace
#   GB202  -> Blackwell
#   GK104  -> Kepler
#   GF104  -> Fermi
#   GT200  -> Tesla
#
##################################################################################################################
#
# DRIVER MATRIX
#
#   Blackwell+                  -> nvidia-open
#   Ada Lovelace                -> nvidia-open
#   Ampere                      -> nvidia-open
#   Turing                      -> nvidia-open
#   Volta                       -> nvidia-580xx-dkms
#   Pascal                      -> nvidia-580xx-dkms
#   Maxwell                     -> nvidia-580xx-dkms
#   Kepler                      -> nvidia-470xx-dkms
#   Fermi                       -> nvidia-390xx-dkms
#   Tesla                       -> nvidia-340xx-dkms
#   Curie and older             -> unsupported
#
##################################################################################################################

set -Eeuo pipefail
IFS=$'\n\t'

##################################################################################################################
# SCRIPT INFORMATION
##################################################################################################################

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0.0"

##################################################################################################################
# FILES
##################################################################################################################

LOG_FILE="/var/log/archn00b-nvidia.log"
LOCK_FILE="/run/lock/archn00b-nvidia.lock"

BACKUP_ROOT="/var/backups/archn00b-nvidia"

##################################################################################################################
# COLORS
##################################################################################################################

if [[ -t 1 ]]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    MAGENTA="$(tput setaf 5)"
    CYAN="$(tput setaf 6)"
    WHITE="$(tput setaf 7)"
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    BOLD=""
    RESET=""
fi

##################################################################################################################
# GLOBAL VARIABLES
##################################################################################################################

DRY_RUN=0
ASSUME_YES=0
DETECT_ONLY=0
VERIFY_ONLY=0
REMOVE_MODE=0

GPU_COUNT=0

GPU_SLOT=""
GPU_NAME=""
GPU_PCI_ID=""
GPU_CLASS=""
GPU_CODENAME=""
GPU_ARCH=""
DRIVER_BRANCH=""
DRIVER_TYPE=""
DRIVER_PACKAGE=""
UTILS_PACKAGE=""
LIB32_UTILS_PACKAGE=""

AUR_HELPER=""

KERNELS=()
HEADERS=()

##################################################################################################################
# LOGGING
##################################################################################################################

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

##################################################################################################################
# ERROR HANDLING
##################################################################################################################

cleanup() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

error_handler() {

    local exit_code=$?

    echo
    echo "${RED}${BOLD}ERROR:${RESET} Installation stopped."
    echo "${YELLOW}Exit code:${RESET} $exit_code"
    echo "${YELLOW}Log file:${RESET} $LOG_FILE"
    echo

    cleanup

    exit "$exit_code"
}

trap error_handler ERR
trap cleanup EXIT

##################################################################################################################
# BASIC FUNCTIONS
##################################################################################################################

msg() {
    echo "${CYAN}${BOLD}==>${RESET} $*"
}

success() {
    echo "${GREEN}${BOLD}[OK]${RESET} $*"
}

warning() {
    echo "${YELLOW}${BOLD}[WARNING]${RESET} $*"
}

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

error() {
    echo "${RED}${BOLD}[ERROR]${RESET} $*"
}

die() {
    error "$*"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_cmd() {

    if (( DRY_RUN )); then
        echo "${MAGENTA}[DRY-RUN]${RESET} $*"
        return 0
    fi

    "$@"
}

##################################################################################################################
# ROOT CHECK
##################################################################################################################

require_root() {

    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root."
    fi
}

##################################################################################################################
# ARCH CHECK
##################################################################################################################

check_arch() {

    [[ -f /etc/arch-release ]] ||
        die "This script is designed specifically for Arch Linux."

    command_exists pacman ||
        die "pacman was not found."

    command_exists lspci ||
        die "pciutils is required. Install it with: pacman -S pciutils"

    success "Arch Linux detected."
}

##################################################################################################################
# LOCK
##################################################################################################################

acquire_lock() {

    if [[ -e "$LOCK_FILE" ]]; then

        warning "Another ArchN00B NVIDIA process appears to be running."

        echo
        echo "Lock file:"
        echo "  $LOCK_FILE"
        echo

        exit 1
    fi

    mkdir -p "$(dirname "$LOCK_FILE")"

    echo "$$" > "$LOCK_FILE"
}

##################################################################################################################
# SYSTEM INFORMATION
##################################################################################################################

detect_system() {

    msg "System information"

    echo
    echo "Hostname       : $(hostname)"
    echo "Kernel         : $(uname -r)"
    echo "Architecture   : $(uname -m)"
    echo "Kernel cmdline : $(cat /proc/cmdline)"

    if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
        echo "Session        : $XDG_SESSION_TYPE"
    else
        echo "Session        : unknown"
    fi

    echo
}

##################################################################################################################
# NVIDIA GPU DISCOVERY
##################################################################################################################

detect_nvidia_gpu() {

    msg "Scanning PCI devices for NVIDIA GPUs..."

    local gpu_lines=()

    mapfile -t gpu_lines < <(
        lspci -nn |
        grep -Ei \
        'VGA compatible controller.*NVIDIA|3D controller.*NVIDIA|Display controller.*NVIDIA' ||
        true
    )

    if [[ ${#gpu_lines[@]} -eq 0 ]]; then
        die "No NVIDIA GPU was detected."
    fi

    GPU_COUNT="${#gpu_lines[@]}"

    echo

    local line

    for line in "${gpu_lines[@]}"; do
        echo "  $line"
    done

    echo

    GPU_SLOT="$(awk '{print $1}' <<< "${gpu_lines[0]}")"

    GPU_NAME="$(
        sed -E \
        's/^.*NVIDIA Corporation //;
         s/ \[[^]]+\].*$//;
         s/ \(rev.*$//' \
        <<< "${gpu_lines[0]}"
    )"

    GPU_PCI_ID="$(
        grep -oE '\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]' <<< "${gpu_lines[0]}" |
        head -n1 |
        tr -d '[]' |
        cut -d: -f2
    )"

    GPU_CLASS="$(
        lspci -n -s "$GPU_SLOT" |
        awk '{print $2}'
    )"

    echo "GPU name       : $GPU_NAME"
    echo "PCI slot       : $GPU_SLOT"
    echo "PCI device ID  : $GPU_PCI_ID"
    echo "PCI class      : $GPU_CLASS"
    echo

    if (( GPU_COUNT > 1 )); then
        warning "Multiple NVIDIA GPUs were detected."
        warning "The first NVIDIA GPU determines the driver branch."
    fi
}

##################################################################################################################
# NVIDIA HARDWARE CODENAME
#
# lspci normally exposes identifiers such as:
#
#   GP102
#   GP104
#   GM204
#   TU102
#   GA102
#   AD102
#   GB202
#   GK104
#
# We extract these identifiers rather than depending on the consumer
# marketing name.
##################################################################################################################

detect_gpu_codename() {

    msg "Detecting NVIDIA hardware codename..."

    local lspci_detail

    lspci_detail="$(
        lspci -nn -s "$GPU_SLOT"
    )"

    ##############################################################################################################
    # Extract NVIDIA architecture family identifiers.
    ##############################################################################################################

    GPU_CODENAME="$(
        grep -oE \
        '\b(GB[0-9]{3,4}|GB[0-9]{2}|AD[0-9]{3,4}|AD[0-9]{2}|GA[0-9]{3,4}|GA[0-9]{2}|TU[0-9]{3,4}|TU[0-9]{2}|GV[0-9]{3,4}|GV[0-9]{2}|GP[0-9]{3,4}|GP[0-9]{2}|GM[0-9]{3,4}|GM[0-9]{2}|GK[0-9]{3,4}|GK[0-9]{2}|GF[0-9]{3,4}|GF[0-9]{2}|GT[0-9]{3,4}|GT[0-9]{2}|G[89]0|G9[0-9]|NV[0-9]{3})\b' \
        <<< "$lspci_detail" |
        head -n1 ||
        true
    )"

    if [[ -z "$GPU_CODENAME" ]]; then

        warning "Could not extract an NVIDIA hardware codename from lspci."

        echo
        echo "Raw device:"
        echo "  $lspci_detail"
        echo

        return 1
    fi

    GPU_CODENAME="${GPU_CODENAME^^}"

    success "NVIDIA hardware codename: $GPU_CODENAME"
}

##################################################################################################################
# ARCHITECTURE CLASSIFICATION
##################################################################################################################

classify_gpu_architecture() {

    msg "Classifying NVIDIA GPU architecture..."

    local code="${GPU_CODENAME^^}"

    ##############################################################################################################
    # BLACKWELL
    ##############################################################################################################

    if [[ "$code" =~ ^GB[0-9]+$ ]]; then

        GPU_ARCH="Blackwell"
        DRIVER_BRANCH="current"
        DRIVER_TYPE="open"

        DRIVER_PACKAGE="nvidia-open"
        UTILS_PACKAGE="nvidia-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-utils"

        return
    fi

    ##############################################################################################################
    # ADA LOVELACE
    ##############################################################################################################

    if [[ "$code" =~ ^AD[0-9]+$ ]]; then

        GPU_ARCH="Ada Lovelace"
        DRIVER_BRANCH="current"
        DRIVER_TYPE="open"

        DRIVER_PACKAGE="nvidia-open"
        UTILS_PACKAGE="nvidia-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-utils"

        return
    fi

    ##############################################################################################################
    # AMPERE
    ##############################################################################################################

    if [[ "$code" =~ ^GA[0-9]+$ ]]; then

        GPU_ARCH="Ampere"
        DRIVER_BRANCH="current"
        DRIVER_TYPE="open"

        DRIVER_PACKAGE="nvidia-open"
        UTILS_PACKAGE="nvidia-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-utils"

        return
    fi

    ##############################################################################################################
    # TURING
    ##############################################################################################################

    if [[ "$code" =~ ^TU[0-9]+$ ]]; then

        GPU_ARCH="Turing"
        DRIVER_BRANCH="current"
        DRIVER_TYPE="open"

        DRIVER_PACKAGE="nvidia-open"
        UTILS_PACKAGE="nvidia-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-utils"

        return
    fi

    ##############################################################################################################
    # VOLTA
    ##############################################################################################################

    if [[ "$code" =~ ^GV[0-9]+$ ]]; then

        GPU_ARCH="Volta"
        DRIVER_BRANCH="580xx"
        DRIVER_TYPE="legacy"

        DRIVER_PACKAGE="nvidia-580xx-dkms"
        UTILS_PACKAGE="nvidia-580xx-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-580xx-utils"

        return
    fi

    ##############################################################################################################
    # PASCAL
    ##############################################################################################################

    if [[ "$code" =~ ^GP[0-9]+$ ]]; then

        GPU_ARCH="Pascal"
        DRIVER_BRANCH="580xx"
        DRIVER_TYPE="legacy"

        DRIVER_PACKAGE="nvidia-580xx-dkms"
        UTILS_PACKAGE="nvidia-580xx-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-580xx-utils"

        return
    fi

    ##############################################################################################################
    # MAXWELL
    ##############################################################################################################

    if [[ "$code" =~ ^GM[0-9]+$ ]]; then

        GPU_ARCH="Maxwell"
        DRIVER_BRANCH="580xx"
        DRIVER_TYPE="legacy"

        DRIVER_PACKAGE="nvidia-580xx-dkms"
        UTILS_PACKAGE="nvidia-580xx-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-580xx-utils"

        return
    fi

    ##############################################################################################################
    # KEPLER
    ##############################################################################################################

    if [[ "$code" =~ ^GK[0-9]+$ ]]; then

        GPU_ARCH="Kepler"
        DRIVER_BRANCH="470xx"
        DRIVER_TYPE="legacy"

        DRIVER_PACKAGE="nvidia-470xx-dkms"
        UTILS_PACKAGE="nvidia-470xx-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-470xx-utils"

        return
    fi

    ##############################################################################################################
    # FERMI
    ##############################################################################################################

    if [[ "$code" =~ ^GF[0-9]+$ ]]; then

        GPU_ARCH="Fermi"
        DRIVER_BRANCH="390xx"
        DRIVER_TYPE="legacy"

        DRIVER_PACKAGE="nvidia-390xx-dkms"
        UTILS_PACKAGE="nvidia-390xx-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-390xx-utils"

        return
    fi

    ##############################################################################################################
    # TESLA
    ##############################################################################################################

    if [[ "$code" =~ ^GT[0-9]+$ ||
          "$code" =~ ^G80$ ||
          "$code" =~ ^G90$ ||
          "$code" =~ ^G92$ ||
          "$code" =~ ^G94$ ||
          "$code" =~ ^G96$ ||
          "$code" =~ ^G98$ ]]; then

        GPU_ARCH="Tesla"
        DRIVER_BRANCH="340xx"
        DRIVER_TYPE="legacy"

        DRIVER_PACKAGE="nvidia-340xx-dkms"
        UTILS_PACKAGE="nvidia-340xx-utils"
        LIB32_UTILS_PACKAGE="lib32-nvidia-340xx-utils"

        return
    fi

    ##############################################################################################################
    # UNKNOWN / UNSUPPORTED
    ##############################################################################################################

    GPU_ARCH="Unknown"
    DRIVER_BRANCH="unknown"
    DRIVER_TYPE="unknown"

    DRIVER_PACKAGE=""
    UTILS_PACKAGE=""
    LIB32_UTILS_PACKAGE=""

    warning "Unknown NVIDIA hardware family."
}

##################################################################################################################
# KERNEL DETECTION
##################################################################################################################

detect_kernels() {

    msg "Detecting installed kernels..."

    KERNELS=()

    while read -r kernel; do

        [[ -n "$kernel" ]] ||
            continue

        KERNELS+=("$kernel")

    done < <(
        pacman -Qq 2>/dev/null |
        grep -E '^linux(-lts|-zen|-hardened)?$' |
        sort -u
    )

    if [[ ${#KERNELS[@]} -eq 0 ]]; then
        warning "No standard Arch kernel packages detected."
    else

        for kernel in "${KERNELS[@]}"; do
            echo "  $kernel"
        done
    fi

    echo
}

##################################################################################################################
# HEADER DETECTION
##################################################################################################################

detect_headers() {

    msg "Detecting kernel headers..."

    HEADERS=()

    while read -r header; do

        [[ -n "$header" ]] ||
            continue

        HEADERS+=("$header")

    done < <(
        pacman -Qq 2>/dev/null |
        grep -E '^linux(-lts|-zen|-hardened)?-headers$' |
        sort -u
    )

    if [[ ${#HEADERS[@]} -eq 0 ]]; then
        warning "No kernel headers are currently installed."
    else

        for header in "${HEADERS[@]}"; do
            echo "  $header"
        done
    fi

    echo
}

##################################################################################################################
# INITRAMFS DETECTION
##################################################################################################################

detect_initramfs() {

    msg "Detecting initramfs generator..."

    if command_exists mkinitcpio; then
        echo "  mkinitcpio : detected"
    fi

    if command_exists dracut; then
        echo "  dracut     : detected"
    fi

    if command_exists booster; then
        echo "  booster    : detected"
    fi

    if ! command_exists mkinitcpio &&
       ! command_exists dracut &&
       ! command_exists booster; then

        warning "No supported initramfs generator detected."
    fi

    echo
}

##################################################################################################################
# MULTILIB
##################################################################################################################

multilib_enabled() {

    awk '
        /^\[multilib\]/ {
            section=1
            next
        }

        /^\[/ {
            section=0
        }

        section &&
        $0 !~ /^[[:space:]]*#/ &&
        $0 !~ /^[[:space:]]*$/ {
            found=1
        }

        END {
            exit !found
        }
    ' /etc/pacman.conf
}

##################################################################################################################
# AUR HELPER
##################################################################################################################

detect_aur_helper() {

    if command_exists paru; then
        AUR_HELPER="paru"
        return
    fi

    if command_exists yay; then
        AUR_HELPER="yay"
        return
    fi

    AUR_HELPER=""
}

##################################################################################################################
# CURRENT DRIVER DETECTION
##################################################################################################################

detect_existing_driver() {

    msg "Checking existing NVIDIA driver..."

    local found=0

    while read -r package; do

        [[ -n "$package" ]] ||
            continue

        echo "  Installed: $package"

        found=1

    done < <(
        pacman -Qq 2>/dev/null |
        grep -E \
        '^(nvidia|nvidia-open|nvidia-[0-9]+xx|lib32-nvidia|lib32-nvidia-[0-9]+xx)' |
        sort -u ||
        true
    )

    if (( ! found )); then
        echo "  No NVIDIA driver packages detected."
    fi

    echo
}

##################################################################################################################
# NOUVEAU DETECTION
##################################################################################################################

detect_nouveau() {

    msg "Checking nouveau..."

    if lsmod | grep -q '^nouveau'; then
        warning "nouveau is currently loaded."
    else
        success "nouveau is not currently loaded."
    fi

    local binding

    binding="$(
        lspci -nnk -s "$GPU_SLOT" |
        grep -i 'Kernel driver in use:' ||
        true
    )"

    if [[ -n "$binding" ]]; then
        echo "  $binding"
    fi

    echo
}

##################################################################################################################
# SECURE BOOT / LOCKDOWN
##################################################################################################################

detect_secure_boot() {

    msg "Checking Secure Boot / kernel lockdown..."

    if command_exists bootctl; then

        if bootctl status 2>/dev/null | grep -qi 'Secure Boot: enabled'; then
            warning "UEFI Secure Boot appears to be enabled."
        else
            echo "  Secure Boot does not appear to be enabled."
        fi
    fi

    if [[ -r /sys/kernel/security/lockdown ]]; then

        local lockdown

        lockdown="$(cat /sys/kernel/security/lockdown)"

        echo "  Kernel lockdown: $lockdown"
    fi

    echo
}

##################################################################################################################
# PACKAGE AVAILABILITY
##################################################################################################################

package_in_repo() {

    local package="$1"

    pacman -Si "$package" >/dev/null 2>&1
}

##################################################################################################################
# PRE-FLIGHT PACKAGE CHECK
##################################################################################################################

check_driver_packages() {

    msg "Checking driver package availability..."

    if [[ "$DRIVER_TYPE" == "open" ]]; then

        if ! package_in_repo "$DRIVER_PACKAGE"; then
            die "$DRIVER_PACKAGE is not available in the configured Arch repositories."
        fi

        if ! package_in_repo "$UTILS_PACKAGE"; then
            die "$UTILS_PACKAGE is not available in the configured Arch repositories."
        fi

        success "Current NVIDIA driver packages are available."

        return
    fi

    ##############################################################################################################
    # Legacy drivers are expected in AUR.
    ##############################################################################################################

    if [[ "$DRIVER_TYPE" == "legacy" ]]; then

        warning "$DRIVER_PACKAGE is an AUR package."

        if [[ -n "$AUR_HELPER" ]]; then
            echo "  AUR helper: $AUR_HELPER"
        else
            echo "  AUR helper: none"
            echo "  Manual makepkg build will be used."
        fi
    fi

    echo
}

##################################################################################################################
# BACKUP
##################################################################################################################

backup_file() {

    local file="$1"

    [[ -e "$file" ]] ||
        return 0

    local timestamp

    timestamp="$(date '+%Y%m%d-%H%M%S')"

    mkdir -p "$BACKUP_ROOT/$timestamp"

    cp -a "$file" "$BACKUP_ROOT/$timestamp/"

    success "Backed up: $file"
}

backup_configuration() {

    msg "Creating configuration backup..."

    backup_file "/etc/mkinitcpio.conf"
    backup_file "/etc/dracut.conf"
    backup_file "/etc/modprobe.d/nvidia.conf"
    backup_file "/etc/modprobe.d/blacklist-nouveau.conf"

    success "Configuration backup complete."
}

##################################################################################################################
# FULL SYSTEM UPDATE
##################################################################################################################

update_system() {

    msg "Synchronizing and updating Arch Linux..."

    run_cmd pacman -Syu --noconfirm

    success "System update complete."
}

##################################################################################################################
# KERNEL HEADERS
##################################################################################################################

install_kernel_headers() {

    msg "Checking kernel headers..."

    local required_headers=()

    if pacman -Q linux >/dev/null 2>&1 &&
       ! pacman -Q linux-headers >/dev/null 2>&1; then

        required_headers+=("linux-headers")
    fi

    if pacman -Q linux-lts >/dev/null 2>&1 &&
       ! pacman -Q linux-lts-headers >/dev/null 2>&1; then

        required_headers+=("linux-lts-headers")
    fi

    if pacman -Q linux-zen >/dev/null 2>&1 &&
       ! pacman -Q linux-zen-headers >/dev/null 2>&1; then

        required_headers+=("linux-zen-headers")
    fi

    if pacman -Q linux-hardened >/dev/null 2>&1 &&
       ! pacman -Q linux-hardened-headers >/dev/null 2>&1; then

        required_headers+=("linux-hardened-headers")
    fi

    if [[ ${#required_headers[@]} -eq 0 ]]; then

        success "Required kernel headers already installed."

        return
    fi

    echo
    echo "Installing:"
    printf '  %s\n' "${required_headers[@]}"
    echo

    run_cmd pacman -S --needed --noconfirm "${required_headers[@]}"

    success "Kernel headers installed."
}

##################################################################################################################
# INSTALL CURRENT NVIDIA DRIVER
##################################################################################################################

install_current_driver() {

    msg "Installing current NVIDIA open driver..."

    local packages=(
        "$DRIVER_PACKAGE"
        "$UTILS_PACKAGE"
    )

    if multilib_enabled; then
        packages+=("$LIB32_UTILS_PACKAGE")
    else
        warning "Multilib is disabled."
        warning "32-bit NVIDIA libraries will not be installed."
    fi

    run_cmd pacman -S --needed --noconfirm "${packages[@]}"

    success "Current NVIDIA driver installed."
}

##################################################################################################################
# CREATE AUR BUILDER
##################################################################################################################

create_aur_builder() {

    local user="archn00b-aur"

    if id "$user" >/dev/null 2>&1; then
        return
    fi

    msg "Creating temporary unprivileged AUR build user..."

    run_cmd useradd \
        --system \
        --create-home \
        --shell /bin/bash \
        "$user"

    success "AUR build user created."
}

##################################################################################################################
# MANUAL AUR BUILD
##################################################################################################################

install_aur_package_manual() {

    local package="$1"
    local builder="archn00b-aur"
    local build_root="/var/tmp/archn00b-nvidia"

    create_aur_builder

    run_cmd mkdir -p "$build_root"

    run_cmd chown -R "$builder:$builder" "$build_root"

    run_cmd rm -rf "$build_root/$package"

    msg "Downloading AUR package: $package"

    runuser -u "$builder" -- bash -c "
        cd '$build_root' &&
        git clone --depth=1 'https://aur.archlinux.org/$package.git' &&
        cd '$package' &&
        makepkg --syncdeps --install --needed --noconfirm
    "

    success "$package installed."
}

##################################################################################################################
# AUR INSTALL
##################################################################################################################

install_aur_package() {

    local package="$1"

    if [[ -n "$AUR_HELPER" ]]; then

        msg "Installing $package using $AUR_HELPER..."

        case "$AUR_HELPER" in

            paru)
                run_cmd paru -S --needed --noconfirm "$package"
                ;;

            yay)
                run_cmd yay -S --needed --noconfirm "$package"
                ;;

            *)
                die "Unsupported AUR helper: $AUR_HELPER"
                ;;

        esac

        return
    fi

    install_aur_package_manual "$package"
}

##################################################################################################################
# INSTALL LEGACY DRIVER
##################################################################################################################

install_legacy_driver() {

    msg "Installing NVIDIA legacy driver branch: $DRIVER_BRANCH"

    ##############################################################################################################
    # DKMS requires headers.
    ##############################################################################################################

    install_kernel_headers

    ##############################################################################################################
    # Utilities first.
    ##############################################################################################################

    if ! pacman -Q "$UTILS_PACKAGE" >/dev/null 2>&1; then
        install_aur_package "$UTILS_PACKAGE"
    else
        success "$UTILS_PACKAGE already installed."
    fi

    ##############################################################################################################
    # DKMS driver.
    ##############################################################################################################

    if ! pacman -Q "$DRIVER_PACKAGE" >/dev/null 2>&1; then
        install_aur_package "$DRIVER_PACKAGE"
    else
        success "$DRIVER_PACKAGE already installed."
    fi

    ##############################################################################################################
    # 32-bit libraries.
    ##############################################################################################################

    if multilib_enabled; then

        if ! pacman -Q "$LIB32_UTILS_PACKAGE" >/dev/null 2>&1; then
            install_aur_package "$LIB32_UTILS_PACKAGE"
        else
            success "$LIB32_UTILS_PACKAGE already installed."
        fi

    else

        warning "Multilib is disabled."
        warning "Skipping $LIB32_UTILS_PACKAGE."

    fi

    success "Legacy NVIDIA driver installed."
}

##################################################################################################################
# DRIVER INSTALLATION
##################################################################################################################

install_driver() {

    case "$DRIVER_TYPE" in

        open)
            install_current_driver
            ;;

        legacy)
            install_legacy_driver
            ;;

        *)
            die "No safe NVIDIA driver could be selected."
            ;;

    esac
}

##################################################################################################################
# DRM CONFIGURATION
##################################################################################################################

configure_drm() {

    msg "Checking NVIDIA DRM configuration..."

    ##############################################################################################################
    # Current Arch NVIDIA packages enable DRM modesetting by default.
    #
    # We intentionally do not blindly write:
    #
    #   options nvidia_drm modeset=1
    #
    # because current drivers already provide this.
    ##############################################################################################################

    if [[ -e /sys/module/nvidia_drm/parameters/modeset ]]; then

        local modeset

        modeset="$(cat /sys/module/nvidia_drm/parameters/modeset)"

        echo "  NVIDIA DRM modeset: $modeset"

        if [[ "$modeset" == "Y" ]]; then
            success "NVIDIA DRM modesetting is enabled."
        else
            warning "NVIDIA DRM modesetting is not enabled."
        fi

    else

        info "nvidia_drm is not currently loaded."
        info "A reboot may be required before verification."
    fi

    echo
}

##################################################################################################################
# INITRAMFS
##################################################################################################################

rebuild_initramfs() {

    msg "Rebuilding initramfs..."

    if command_exists mkinitcpio; then

        run_cmd mkinitcpio -P

        success "mkinitcpio completed."

        return
    fi

    if command_exists dracut; then

        run_cmd dracut --regenerate-all --force

        success "dracut completed."

        return
    fi

    if command_exists booster; then

        warning "booster is installed."
        warning "No automatic booster configuration will be modified."

        return
    fi

    warning "No supported initramfs generator detected."
}

##################################################################################################################
# DRIVER BINDING
##################################################################################################################

verify_driver_binding() {

    msg "Checking kernel driver binding..."

    echo

    lspci -nnk -s "$GPU_SLOT"

    echo

    if lspci -nnk -s "$GPU_SLOT" |
        grep -q 'Kernel driver in use: nvidia'; then

        success "NVIDIA kernel driver is bound to the GPU."

    elif lspci -nnk -s "$GPU_SLOT" |
        grep -q 'Kernel driver in use: nouveau'; then

        warning "nouveau is still bound to the GPU."

    else

        warning "No NVIDIA kernel driver is currently bound."
        warning "A reboot may be required."
    fi
}

##################################################################################################################
# MODULE VERIFICATION
##################################################################################################################

verify_modules() {

    msg "Checking NVIDIA modules..."

    local modules=(
        nvidia
        nvidia_modeset
        nvidia_drm
        nvidia_uvm
    )

    local module

    for module in "${modules[@]}"; do

        if lsmod | grep -q "^${module}[[:space:]]"; then
            success "$module loaded."
        else
            warning "$module is not currently loaded."
        fi

    done

    echo
}

##################################################################################################################
# NVIDIA-SMI
##################################################################################################################

verify_nvidia_smi() {

    msg "Testing nvidia-smi..."

    if ! command_exists nvidia-smi; then

        warning "nvidia-smi was not found."

        return
    fi

    if nvidia-smi; then
        success "nvidia-smi is working."
    else
        warning "nvidia-smi failed."
    fi

    echo
}

##################################################################################################################
# DRIVER VERSION
##################################################################################################################

show_driver_version() {

    if command_exists nvidia-smi; then

        nvidia-smi \
            --query-gpu=name,driver_version \
            --format=csv,noheader 2>/dev/null ||
            true
    fi
}

##################################################################################################################
# FULL VERIFICATION
##################################################################################################################

verify_installation() {

    echo
    echo "${WHITE}${BOLD}============================================================${RESET}"
    echo "${WHITE}${BOLD} NVIDIA DRIVER VERIFICATION${RESET}"
    echo "${WHITE}${BOLD}============================================================${RESET}"
    echo

    detect_nvidia_gpu

    if detect_gpu_codename; then
        classify_gpu_architecture
    fi

    detect_existing_driver
    verify_driver_binding
    verify_modules
    configure_drm
    verify_nvidia_smi

    echo
    echo "${WHITE}${BOLD}Driver:${RESET}"

    show_driver_version

    echo
    echo "${GREEN}${BOLD}Verification complete.${RESET}"
    echo
}

##################################################################################################################
# DETECTION REPORT
##################################################################################################################

detection_report() {

    echo
    echo "${WHITE}${BOLD}============================================================${RESET}"
    echo "${WHITE}${BOLD} ArchN00B NVIDIA DETECTION REPORT${RESET}"
    echo "${WHITE}${BOLD}============================================================${RESET}"
    echo

    detect_system
    detect_nvidia_gpu

    if ! detect_gpu_codename; then

        warning "Unable to safely classify this NVIDIA GPU."

        echo
        echo "The script will NOT guess a driver."
        echo

        return 1
    fi

    classify_gpu_architecture

    detect_kernels
    detect_headers
    detect_initramfs
    detect_existing_driver
    detect_nouveau
    detect_secure_boot
    detect_aur_helper
    check_driver_packages

    echo
    echo "${WHITE}${BOLD}GPU:${RESET}"
    echo "  Model            : $GPU_NAME"
    echo "  PCI device       : $GPU_PCI_ID"
    echo "  Hardware family  : $GPU_CODENAME"
    echo "  Architecture     : $GPU_ARCH"

    echo
    echo "${WHITE}${BOLD}Driver:${RESET}"
    echo "  Branch           : $DRIVER_BRANCH"
    echo "  Type             : $DRIVER_TYPE"
    echo "  Kernel package   : $DRIVER_PACKAGE"
    echo "  Utilities        : $UTILS_PACKAGE"

    if multilib_enabled; then
        echo "  32-bit utilities : $LIB32_UTILS_PACKAGE"
        echo "  Multilib         : enabled"
    else
        echo "  Multilib         : disabled"
    fi

    echo
    echo "${WHITE}${BOLD}============================================================${RESET}"
    echo

    if [[ "$DRIVER_TYPE" == "legacy" ]]; then

        warning "LEGACY NVIDIA DRIVER"

        echo
        echo "This GPU is no longer supported by the current NVIDIA driver."
        echo "Arch provides the appropriate legacy branch through the AUR."
        echo
    fi

    if [[ "$GPU_ARCH" == "Unknown" ]]; then
        die "Unknown NVIDIA architecture."
    fi
}

##################################################################################################################
# CONFIRMATION
##################################################################################################################

confirm_install() {

    (( ASSUME_YES )) &&
        return

    echo

    read -rp \
        "${YELLOW}Install the driver shown above? [y/N]: ${RESET}" \
        answer

    case "${answer,,}" in

        y|yes)
            echo
            ;;

        *)
            echo
            echo "Installation cancelled."
            exit 0
            ;;

    esac
}

##################################################################################################################
# REMOVE NVIDIA DRIVER
##################################################################################################################

remove_driver() {

    msg "Searching for installed NVIDIA packages..."

    local packages=()

    while read -r package; do

        [[ -n "$package" ]] ||
            continue

        packages+=("$package")

    done < <(
        pacman -Qq 2>/dev/null |
        grep -E \
        '^(nvidia-open|nvidia-open-dkms|nvidia|nvidia-[0-9]+xx(-dkms|-utils|-settings)?|lib32-nvidia|lib32-nvidia-[0-9]+xx-utils|opencl-nvidia)' |
        sort -u ||
        true
    )

    if [[ ${#packages[@]} -eq 0 ]]; then

        success "No NVIDIA packages were found."

        return
    fi

    echo
    echo "${YELLOW}Packages detected:${RESET}"

    printf '  %s\n' "${packages[@]}"

    echo

    if (( ! ASSUME_YES )); then

        read -rp \
            "${YELLOW}Remove these packages? [y/N]: ${RESET}" \
            answer

        case "${answer,,}" in

            y|yes)
                ;;

            *)
                echo "Removal cancelled."
                return
                ;;

        esac
    fi

    run_cmd pacman -Rns --noconfirm "${packages[@]}"

    rebuild_initramfs

    success "NVIDIA packages removed."

    echo
    warning "Reboot recommended."
    echo
}

##################################################################################################################
# INSTALL
##################################################################################################################

perform_install() {

    if ! detection_report; then
        die "NVIDIA hardware could not be safely identified."
    fi

    confirm_install

    backup_configuration

    update_system

    install_driver

    rebuild_initramfs

    configure_drm

    echo
    echo "${GREEN}${BOLD}============================================================${RESET}"
    echo "${GREEN}${BOLD} NVIDIA DRIVER INSTALLATION COMPLETE${RESET}"
    echo "${GREEN}${BOLD}============================================================${RESET}"
    echo

    warning "Reboot your computer before performing the final verification."
    echo

    echo "After reboot:"
    echo
    echo "    sudo $SCRIPT_NAME --verify"
    echo
}

##################################################################################################################
# HELP
##################################################################################################################

usage() {

    cat <<EOF

${WHITE}${BOLD}ArchN00B NVIDIA Universal Driver Installer${RESET}

Version: $SCRIPT_VERSION

Usage:

    sudo $SCRIPT_NAME --detect
    sudo $SCRIPT_NAME --install
    sudo $SCRIPT_NAME --verify
    sudo $SCRIPT_NAME --remove

Options:

    --detect
        Detect NVIDIA hardware and show the driver plan.
        Makes no system changes.

    --install
        Detect and install the correct NVIDIA driver.

    --verify
        Verify the currently installed NVIDIA driver.

    --remove
        Remove NVIDIA driver packages.

    --dry-run
        Show what would be done without making changes.

    --yes
        Automatically answer yes to confirmation prompts.

    --version
        Display script version.

    --help
        Display this help.

Examples:

    sudo $SCRIPT_NAME --detect

    sudo $SCRIPT_NAME --install

    sudo $SCRIPT_NAME --install --yes

    sudo $SCRIPT_NAME --verify

    sudo $SCRIPT_NAME --remove

    sudo $SCRIPT_NAME --install --dry-run

EOF
}

##################################################################################################################
# ARGUMENT PARSER
##################################################################################################################

parse_arguments() {

    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    while [[ $# -gt 0 ]]; do

        case "$1" in

            --detect)
                DETECT_ONLY=1
                ;;

            --install)
                ;;

            --verify)
                VERIFY_ONLY=1
                ;;

            --remove)
                REMOVE_MODE=1
                ;;

            --dry-run)
                DRY_RUN=1
                ;;

            --yes)
                ASSUME_YES=1
                ;;

            --version)
                echo "$SCRIPT_NAME $SCRIPT_VERSION"
                exit 0
                ;;

            --help|-h)
                usage
                exit 0
                ;;

            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;

        esac

        shift
    done
}

##################################################################################################################
# MAIN
##################################################################################################################

main() {

    parse_arguments "$@"

    require_root
    check_arch
    acquire_lock

    ##############################################################################################################
    # DETECT
    ##############################################################################################################

    if (( DETECT_ONLY )); then

        detection_report

        exit 0
    fi

    ##############################################################################################################
    # VERIFY
    ##############################################################################################################

    if (( VERIFY_ONLY )); then

        verify_installation

        exit 0
    fi

    ##############################################################################################################
    # REMOVE
    ##############################################################################################################

    if (( REMOVE_MODE )); then

        remove_driver

        exit 0
    fi

    ##############################################################################################################
    # INSTALL
    ##############################################################################################################

    perform_install
}

##################################################################################################################
# START
##################################################################################################################

main "$@"