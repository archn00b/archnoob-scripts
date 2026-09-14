#!/usr/bin/env bash
set -Eeuo pipefail

##################################################################################################################
# Author     : ArchN00B
# Website    : https://github.com/archn00b
# Script     : driver-detect.sh
# Purpose    : AMD GPU detection and driver management for Arch Linux
##################################################################################################################

# ---------------------------------------------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------------------------------------------

SCRIPT_NAME="ArchN00B AMD GPU Driver"
SCRIPT_VERSION="1.0.1"

LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/archn00b-amd.log"

LOCK_DIR="/run/lock"
LOCK_FILE="${LOCK_DIR}/archn00b-amd.lock"

BACKUP_DIR="/var/backups/archn00b-amd"

DRIVER_PACKAGE="mesa"
VULKAN_PACKAGE="vulkan-radeon"
FIRMWARE_PACKAGE="linux-firmware-amdgpu"

MULTILIB_PACKAGES=(
    "lib32-mesa"
    "lib32-vulkan-radeon"
)

# ---------------------------------------------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------------------------------------------

if [[ -t 1 ]]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 6)"
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    BOLD=""
    RESET=""
fi

# ---------------------------------------------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------------------------------------------

print_header() {
    clear 2>/dev/null || true

    echo
    echo "============================================================"
    printf "%28s\n" "${SCRIPT_NAME}"
    echo "============================================================"
    echo
}

section() {
    echo
    echo "==> $1"
    echo
}

msg_ok() {
    printf " ${GREEN}[ OK ]${RESET} %s\n" "$1"
}

msg_info() {
    printf " ${CYAN}[INFO]${RESET} %s\n" "$1"
}

msg_warn() {
    printf " ${YELLOW}[WARN]${RESET} %s\n" "$1"
}

msg_error() {
    printf " ${RED}[ERROR]${RESET} %s\n" "$1" >&2
}

die() {
    msg_error "$1"
    exit 1
}

# ---------------------------------------------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------------------------------------------

setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    exec > >(tee -a "$LOG_FILE") 2>&1
}

# ---------------------------------------------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------------------------------------------

cleanup() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

trap cleanup EXIT

# ---------------------------------------------------------------------------------------------------------------
# Root check
# ---------------------------------------------------------------------------------------------------------------

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "This script must be run as root. Use: sudo ./driver-detect.sh"
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Lock
# ---------------------------------------------------------------------------------------------------------------

acquire_lock() {
    mkdir -p "$LOCK_DIR"

    if [[ -e "$LOCK_FILE" ]]; then
        die "Another instance of this script is already running."
    fi

    touch "$LOCK_FILE"
}

# ---------------------------------------------------------------------------------------------------------------
# Command helpers
# ---------------------------------------------------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

package_available() {
    pacman -Si "$1" >/dev/null 2>&1
}

run_cmd() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        printf " ${BLUE}[DRY]${RESET} "
        printf '%q ' "$@"
        echo
        return 0
    fi

    "$@"
}

# ---------------------------------------------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------------------------------------------

check_dependencies() {
    local missing=()

    for cmd in lspci pacman awk sed grep findmnt uname modprobe lsmod; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        die "Missing required commands: ${missing[*]}"
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# AMD GPU detection
# ---------------------------------------------------------------------------------------------------------------

GPU_LINE=""
GPU_SLOT=""
GPU_PCI_ID=""
GPU_VENDOR_ID=""
GPU_DEVICE_ID=""
GPU_MODEL=""
GPU_SUBSYSTEM=""
HARDWARE_FAMILY="AMD Radeon"
ARCHITECTURE="Unknown"

detect_gpu() {
    section "Detecting AMD GPU"

    GPU_LINE="$(
        lspci -Dn 2>/dev/null |
        awk '
            $2 ~ /^(0300|0302)$/ &&
            $3 ~ /^1002:/ {
                print
                exit
            }
        '
    )"

    if [[ -z "$GPU_LINE" ]]; then
        GPU_LINE="$(
            lspci -Dn 2>/dev/null |
            awk '
                $2 ~ /^03/ &&
                $3 ~ /^1002:/ {
                    print
                    exit
                }
            '
        )"
    fi

    if [[ -z "$GPU_LINE" ]]; then
        die "No AMD graphics device was detected."
    fi

    GPU_SLOT="$(awk '{print $1}' <<< "$GPU_LINE")"
    GPU_PCI_ID="$(awk '{print $3}' <<< "$GPU_LINE" | cut -d: -f2)"
    GPU_VENDOR_ID="$(cut -d: -f1 <<< "$GPU_PCI_ID")"
    GPU_DEVICE_ID="$(cut -d: -f2 <<< "$GPU_PCI_ID")"

    GPU_MODEL="$(
        sed -E 's/^[^:]+: [^:]+: //' <<< "$GPU_LINE"
    )"

    GPU_SUBSYSTEM="$(
        lspci -nn -s "$GPU_SLOT" 2>/dev/null |
        sed -n 's/.*Subsystem: //p' |
        head -n1
    )"

    detect_hardware_family

    msg_ok "AMD GPU detected"
}

# ---------------------------------------------------------------------------------------------------------------
# Hardware family detection
# ---------------------------------------------------------------------------------------------------------------

detect_hardware_family() {
    local gpu_info

    gpu_info="$(
        lspci -nn -s "$GPU_SLOT" 2>/dev/null
    )"

    case "$gpu_info" in
        *"Navi 1"*"gfx10"*|*"Navi 2"*"gfx10"*|*"Navi 3"*"gfx11"*|*"Navi 4"*"gfx12"*)
            HARDWARE_FAMILY="Navi / RDNA"
            ARCHITECTURE="RDNA"
            ;;

        *"Radeon RX 7000"*|*"gfx11"*)
            HARDWARE_FAMILY="RDNA2/RDNA3"
            ARCHITECTURE="RDNA2/RDNA3"
            ;;

        *"Radeon RX 6000"*|*"gfx10.3"*)
            HARDWARE_FAMILY="Navi 2x"
            ARCHITECTURE="RDNA2"
            ;;

        *"Vega"*"gfx9"*|*"Radeon RX Vega"*)
            HARDWARE_FAMILY="Vega"
            ARCHITECTURE="GCN5"
            ;;

        *"Radeon RX 5000"*|*"Navi"*)
            HARDWARE_FAMILY="Navi"
            ARCHITECTURE="RDNA1"
            ;;

        *"Polaris"*|*"Radeon RX 500"*|*"Radeon RX 400"*)
            HARDWARE_FAMILY="Polaris"
            ARCHITECTURE="GCN4"
            ;;

        *"Fiji"*|*"Tonga"*|*"Carrizo"*|*"Bristol"*|*"gfx8"*)
            HARDWARE_FAMILY="GCN3/GCN4"
            ARCHITECTURE="GCN3/GCN4"
            ;;

        *"Sea Islands"*|*"Southern Islands"*)
            HARDWARE_FAMILY="Southern/Sea Islands"
            ARCHITECTURE="GCN1/GCN2"
            ;;

        *"Radeon R5/R6/R7"*|*"Wani"*)
            HARDWARE_FAMILY="AMD Radeon"
            ARCHITECTURE="AMDGPU-compatible"
            ;;

        *)
            HARDWARE_FAMILY="AMD Radeon"
            ARCHITECTURE="AMDGPU-compatible"
            ;;
    esac
}

# ---------------------------------------------------------------------------------------------------------------
# Kernel driver detection
# ---------------------------------------------------------------------------------------------------------------

KERNEL_DRIVER="Unknown"
KERNEL_MODULES="Unknown"
AMDGPU_LOADED="no"

detect_kernel_driver() {
    local kernel_info

    kernel_info="$(
        lspci -k -s "$GPU_SLOT" 2>/dev/null || true
    )"

    KERNEL_DRIVER="$(
        awk -F': ' '/Kernel driver in use:/ {
            print $2
            exit
        }' <<< "$kernel_info"
    )"

    KERNEL_MODULES="$(
        awk -F': ' '/Kernel modules:/ {
            print $2
            exit
        }' <<< "$kernel_info"
    )"

    [[ -z "$KERNEL_DRIVER" ]] && KERNEL_DRIVER="Not bound"
    [[ -z "$KERNEL_MODULES" ]] && KERNEL_MODULES="Unknown"

    if lsmod | awk '{print $1}' | grep -qx "amdgpu"; then
        AMDGPU_LOADED="yes"
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Multilib detection
# ---------------------------------------------------------------------------------------------------------------

MULTILIB_ENABLED="no"

detect_multilib() {
    if grep -Eq '^[[:space:]]*\[multilib\]' /etc/pacman.conf; then
        MULTILIB_ENABLED="yes"
    else
        MULTILIB_ENABLED="no"
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Initramfs detection
# ---------------------------------------------------------------------------------------------------------------

INITRAMFS="Unknown"

detect_initramfs() {
    if command_exists mkinitcpio; then
        INITRAMFS="mkinitcpio"
    elif command_exists dracut; then
        INITRAMFS="dracut"
    elif command_exists booster; then
        INITRAMFS="booster"
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Secure Boot / lockdown detection
# ---------------------------------------------------------------------------------------------------------------

SECURE_BOOT="Disabled"
KERNEL_LOCKDOWN="[none]"

detect_secure_boot() {
    if command_exists bootctl; then
        if bootctl status 2>/dev/null | grep -qi "Secure Boot: enabled"; then
            SECURE_BOOT="Enabled"
        fi
    fi

    if [[ -r /sys/kernel/security/lockdown ]]; then
        KERNEL_LOCKDOWN="$(cat /sys/kernel/security/lockdown)"
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Graphics stack detection
# ---------------------------------------------------------------------------------------------------------------

MESA_STATUS="Not installed"
VULKAN_STATUS="Not installed"
OPENGL_STATUS="Not installed"

detect_graphics_stack() {
    if package_installed mesa; then
        MESA_STATUS="installed"
    fi

    if package_installed vulkan-radeon; then
        VULKAN_STATUS="installed"
    fi

    if command_exists glxinfo; then
        if glxinfo -B >/dev/null 2>&1; then
            OPENGL_STATUS="Installed"
        fi
    elif package_installed mesa; then
        OPENGL_STATUS="Installed"
    fi

    if command_exists vulkaninfo; then
        if vulkaninfo --summary >/dev/null 2>&1; then
            VULKAN_STATUS="Installed"
        fi
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Kernel detection -- FIXED
# ---------------------------------------------------------------------------------------------------------------

declare -a INSTALLED_KERNELS=()

detect_kernels() {
    INSTALLED_KERNELS=()

    while IFS= read -r kernel; do
        [[ -n "$kernel" ]] || continue

        case "$kernel" in
            linux|linux-lts|linux-zen|linux-hardened)
                INSTALLED_KERNELS+=("$kernel")
                ;;
        esac
    done < <(
        pacman -Qq 2>/dev/null |
        grep -E '^linux(-lts|-zen|-hardened)?$' |
        sort -u || true
    )

    # Fallback: detect the running kernel if its package wasn't found.
    if (( ${#INSTALLED_KERNELS[@]} == 0 )); then
        local running_kernel

        running_kernel="$(uname -r 2>/dev/null || true)"

        case "$running_kernel" in
            *-lts)
                INSTALLED_KERNELS+=("linux-lts")
                ;;
            *-zen)
                INSTALLED_KERNELS+=("linux-zen")
                ;;
            *-hardened)
                INSTALLED_KERNELS+=("linux-hardened")
                ;;
            *)
                INSTALLED_KERNELS+=("linux")
                ;;
        esac
    fi
}

# ---------------------------------------------------------------------------------------------------------------
# Kernel header detection -- FIXED
# ---------------------------------------------------------------------------------------------------------------

kernel_headers_package() {
    local kernel="$1"

    case "$kernel" in
        linux)
            printf '%s\n' "linux-headers"
            ;;

        linux-lts)
            printf '%s\n' "linux-lts-headers"
            ;;

        linux-zen)
            printf '%s\n' "linux-zen-headers"
            ;;

        linux-hardened)
            printf '%s\n' "linux-hardened-headers"
            ;;

        *)
            printf '%s\n' ""
            ;;
    esac
}

kernel_headers_installed() {
    local kernel="$1"
    local headers

    headers="$(kernel_headers_package "$kernel")"

    [[ -n "$headers" ]] || return 1

    package_installed "$headers"
}

# ---------------------------------------------------------------------------------------------------------------
# Print kernel information
# ---------------------------------------------------------------------------------------------------------------

print_kernel_information() {
    detect_kernels

    echo
    echo "Kernels:"

    local kernel
    local headers

    for kernel in "${INSTALLED_KERNELS[@]}"; do
        headers="$(kernel_headers_package "$kernel")"

        if [[ -n "$headers" ]] && package_installed "$headers"; then
            printf "  %-16s : headers installed\n" "$kernel"
        elif [[ -n "$headers" ]]; then
            printf "  %-16s : headers missing\n" "$kernel"
        else
            printf "  %-16s : header check unavailable\n" "$kernel"
        fi
    done
}

# ---------------------------------------------------------------------------------------------------------------
# Display detection results
# ---------------------------------------------------------------------------------------------------------------

show_detection() {
    detect_gpu
    detect_kernel_driver
    detect_multilib
    detect_initramfs
    detect_secure_boot
    detect_graphics_stack

    echo
    echo "GPU:"
    printf "  %-19s: %s\n" "Model" "$GPU_MODEL"
    printf "  %-19s: %s\n" "PCI device" "$GPU_VENDOR_ID:$GPU_DEVICE_ID"
    printf "  %-19s: %s\n" "Hardware family" "$HARDWARE_FAMILY"
    printf "  %-19s: %s\n" "Architecture" "$ARCHITECTURE"
    printf "  %-19s: %s\n" "PCI slot" "$GPU_SLOT"

    echo
    echo "Driver:"
    printf "  %-19s: %s\n" "Kernel driver" "$KERNEL_DRIVER"
    printf "  %-19s: %s\n" "Kernel modules" "$KERNEL_MODULES"
    printf "  %-19s: %s\n" "AMDGPU module" "$([[ "$AMDGPU_LOADED" == "yes" ]] && echo "loaded" || echo "not loaded")"

    echo
    echo "Graphics stack:"
    printf "  %-19s: %s\n" "Mesa" "$MESA_STATUS"
    printf "  %-19s: %s\n" "Vulkan RADV" "$VULKAN_STATUS"
    printf "  %-19s: %s\n" "OpenGL" "$OPENGL_STATUS"
    printf "  %-19s: %s\n" "Vulkan" "$VULKAN_STATUS"

    echo
    echo "System:"
    printf "  %-19s: %s\n" "Multilib" "$([[ "$MULTILIB_ENABLED" == "yes" ]] && echo "enabled" || echo "disabled")"
    printf "  %-19s: %s\n" "Initramfs" "$INITRAMFS"
    printf "  %-19s: %s\n" "Secure Boot" "$SECURE_BOOT"
    printf "  %-19s: %s\n" "Kernel lockdown" "$KERNEL_LOCKDOWN"

    print_kernel_information
}

# ---------------------------------------------------------------------------------------------------------------
# Backup configuration
# ---------------------------------------------------------------------------------------------------------------

create_backup() {
    local timestamp
    timestamp="$(date '+%Y%m%d-%H%M%S')"

    local backup="${BACKUP_DIR}/${timestamp}"

    mkdir -p "$backup"

    if [[ -f /etc/mkinitcpio.conf ]]; then
        cp -a /etc/mkinitcpio.conf "$backup/"
    fi

    if [[ -f /etc/pacman.conf ]]; then
        cp -a /etc/pacman.conf "$backup/"
    fi

    msg_ok "Configuration backup created: $backup"
}

# ---------------------------------------------------------------------------------------------------------------
# Install AMD graphics stack
# ---------------------------------------------------------------------------------------------------------------

install_graphics_stack() {
    local packages=(
        "mesa"
        "vulkan-radeon"
        "linux-firmware-amdgpu"
    )

    if [[ "$MULTILIB_ENABLED" == "yes" ]]; then
        packages+=("${MULTILIB_PACKAGES[@]}")
    fi

    section "Installing AMD graphics stack"

    msg_info "Packages:"
    printf '  %s\n' "${packages[@]}"

    run_cmd pacman -S --needed "${packages[@]}"

    msg_ok "AMD graphics stack installed"
}

# ---------------------------------------------------------------------------------------------------------------
# Rebuild initramfs
# ---------------------------------------------------------------------------------------------------------------

rebuild_initramfs() {
    section "Rebuilding initramfs"

    case "$INITRAMFS" in
        mkinitcpio)
            run_cmd mkinitcpio -P
            ;;

        dracut)
            run_cmd dracut --regenerate-all --force
            ;;

        booster)
            msg_info "Booster detected; no generic rebuild command was executed."
            ;;

        *)
            msg_warn "No supported initramfs generator detected."
            return 0
            ;;
    esac

    msg_ok "Initramfs rebuild completed"
}

# ---------------------------------------------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------------------------------------------

install_driver() {
    section "Installing AMD GPU support"

    if [[ "$KERNEL_DRIVER" == "radeon" ]]; then
        msg_warn "The system is currently using the legacy radeon kernel driver."
        msg_warn "No automatic radeon -> amdgpu kernel parameter changes will be made."
        msg_warn "This avoids potentially breaking boot on older AMD hardware."
    fi

    create_backup

    section "Synchronizing Arch Linux packages"

    run_cmd pacman -Syu

    install_graphics_stack

    rebuild_initramfs

    msg_ok "AMD GPU installation completed"
}

# ---------------------------------------------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------------------------------------------

verify_driver() {
    section "Verifying AMD GPU"

    detect_gpu
    detect_kernel_driver
    detect_graphics_stack

    local failed=0

    if [[ "$KERNEL_DRIVER" == "amdgpu" ]]; then
        msg_ok "Kernel driver: amdgpu"
    else
        msg_warn "Kernel driver: ${KERNEL_DRIVER}"
        failed=1
    fi

    if [[ "$AMDGPU_LOADED" == "yes" ]]; then
        msg_ok "AMDGPU kernel module is loaded"
    else
        msg_warn "AMDGPU kernel module is not loaded"
        failed=1
    fi

    if package_installed mesa; then
        msg_ok "Mesa is installed"
    else
        msg_warn "Mesa is not installed"
        failed=1
    fi

    if package_installed vulkan-radeon; then
        msg_ok "Vulkan RADV is installed"
    else
        msg_warn "Vulkan RADV is not installed"
        failed=1
    fi

    if [[ "$failed" -eq 0 ]]; then
        echo
        msg_ok "AMD GPU verification successful"
        return 0
    fi

    echo
    msg_warn "AMD GPU verification reported problems"
    return 1
}

# ---------------------------------------------------------------------------------------------------------------
# Remove userspace graphics packages
# ---------------------------------------------------------------------------------------------------------------

remove_driver() {
    section "Removing AMD graphics userspace packages"

    msg_warn "The AMDGPU kernel driver is part of the Linux kernel."
    msg_warn "This operation does NOT remove the kernel's AMDGPU driver."

    local packages=()

    for package in \
        mesa \
        vulkan-radeon \
        lib32-mesa \
        lib32-vulkan-radeon \
        xf86-video-amdgpu
    do
        if package_installed "$package"; then
            packages+=("$package")
        fi
    done

    if (( ${#packages[@]} == 0 )); then
        msg_info "No removable AMD graphics packages were found."
        return 0
    fi

    printf "Packages to remove:\n"
    printf "  %s\n" "${packages[@]}"

    if [[ "${ASSUME_YES:-false}" != "true" ]]; then
        echo
        read -r -p "Continue? [y/N]: " answer

        case "$answer" in
            y|Y|yes|YES)
                ;;
            *)
                msg_info "Operation cancelled."
                return 0
                ;;
        esac
    fi

    run_cmd pacman -Rns "${packages[@]}"

    msg_ok "AMD userspace graphics packages removed"
}

# ---------------------------------------------------------------------------------------------------------------
# Dry run
# ---------------------------------------------------------------------------------------------------------------

DRY_RUN="false"
ASSUME_YES="false"

# ---------------------------------------------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------------------------------------------

show_help() {
    cat <<EOF

${BOLD}${SCRIPT_NAME}${RESET}
Version: ${SCRIPT_VERSION}

Usage:
    sudo ./driver-detect.sh [OPTION]

Options:

    --detect
        Detect AMD GPU and display driver information.

    --install
        Install the AMD graphics stack.

    --install --yes
        Install without confirmation prompts.

    --install --dry-run
        Show commands without executing package changes.

    --verify
        Verify the AMD graphics stack.

    --remove
        Remove AMD userspace graphics packages.

    --version
        Display script version.

    --help
        Display this help message.

Examples:

    sudo ./driver-detect.sh --detect

    sudo ./driver-detect.sh --install

    sudo ./driver-detect.sh --install --yes

    sudo ./driver-detect.sh --install --dry-run

    sudo ./driver-detect.sh --verify

    sudo ./driver-detect.sh --remove

EOF
}

# ---------------------------------------------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------------------------------------------

ACTION=""

parse_arguments() {
    while (( $# > 0 )); do
        case "$1" in
            --detect)
                ACTION="detect"
                ;;

            --install)
                ACTION="install"
                ;;

            --verify)
                ACTION="verify"
                ;;

            --remove)
                ACTION="remove"
                ;;

            --dry-run)
                DRY_RUN="true"
                ;;

            --yes)
                ASSUME_YES="true"
                ;;

            --version)
                echo "${SCRIPT_NAME} ${SCRIPT_VERSION}"
                exit 0
                ;;

            --help|-h)
                show_help
                exit 0
                ;;

            *)
                die "Unknown option: $1"
                ;;
        esac

        shift
    done

    if [[ -z "$ACTION" ]]; then
        ACTION="detect"
    fi
}

main() {
    parse_arguments "$@"

    print_header

    require_root
    setup_logging
    acquire_lock
    check_dependencies

    case "$ACTION" in
        detect)
            section "AMD GPU Detection"
            show_detection
            ;;

        install)
            section "AMD GPU Detection"
            show_detection
            install_driver
            ;;

        verify)
            verify_driver
            ;;

        remove)
            remove_driver
            ;;

        *)
            die "Invalid operation."
            ;;
    esac

    echo
    echo "============================================================"
    msg_ok "Operation completed."
    echo "============================================================"
    echo
}

main "$@"
