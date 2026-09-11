#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Arch Linux Audio Setup
#
# Goal:
#   Reproduce the Omarchy-style audio stack:
#     ALSA
#     PipeWire
#     PipeWire PulseAudio compatibility
#     WirePlumber
#     RTKit
#
# This does NOT install standalone PulseAudio.
# pipewire-pulse provides the PulseAudio-compatible server.
# =============================================================================


# -----------------------------------------------------------------------------
# 1. ROOT CHECK
# -----------------------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
    echo "Do not run this script as root."
    echo "Run it as your normal user."
    exit 1
fi


# -----------------------------------------------------------------------------
# 2. VARIABLES
# -----------------------------------------------------------------------------

AUDIO_PACKAGES=(
    alsa-card-profiles
    alsa-lib
    alsa-topology-conf
    alsa-ucm-conf
    alsa-utils

    gst-plugin-pipewire

    libpipewire
    libwireplumber

    pipewire
    pipewire-alsa
    pipewire-audio
    pipewire-jack
    pipewire-pulse

    wireplumber

    rtkit
)

WIREPLUMBER_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
BLUETOOTH_CONFIG="$WIREPLUMBER_DIR/bluetooth-a2dp-autoconnect.conf"


# -----------------------------------------------------------------------------
# 3. FUNCTIONS
# -----------------------------------------------------------------------------

info() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

success() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$1"
}

warning() {
    printf '\033[1;33m[WARNING]\033[0m %s\n' "$1"
}


# -----------------------------------------------------------------------------
# 4. UPDATE SYSTEM
# -----------------------------------------------------------------------------

info "Updating system"

sudo pacman -Syu --needed

success "System updated"


# -----------------------------------------------------------------------------
# 5. INSTALL AUDIO PACKAGES
# -----------------------------------------------------------------------------

info "Installing audio packages"

sudo pacman -S --needed "${AUDIO_PACKAGES[@]}"

success "Audio packages installed"


# -----------------------------------------------------------------------------
# 6. REMOVE STANDALONE PULSEAUDIO
#
# pipewire-pulse provides the PulseAudio API.
# We don't want standalone PulseAudio competing with it.
# -----------------------------------------------------------------------------

if pacman -Qq pulseaudio &>/dev/null; then

    warning "Standalone PulseAudio is installed."

    echo
    read -rp "Remove standalone PulseAudio? [Y/n]: " answer

    if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
        sudo pacman -Rns pulseaudio
        success "Standalone PulseAudio removed"
    else
        warning "Standalone PulseAudio was left installed."
    fi

else
    success "Standalone PulseAudio is not installed"
fi


# -----------------------------------------------------------------------------
# 7. CREATE WIREPLUMBER CONFIG DIRECTORY
# -----------------------------------------------------------------------------

info "Creating WirePlumber configuration directory"

mkdir -p "$WIREPLUMBER_DIR"

success "WirePlumber configuration directory ready"


# -----------------------------------------------------------------------------
# 8. CHECK BLUETOOTH CONFIG
#
# We don't invent or overwrite Omarchy's configuration here.
# If the file already exists, preserve it.
# -----------------------------------------------------------------------------

if [[ -f "$BLUETOOTH_CONFIG" ]]; then
    success "Bluetooth A2DP configuration already exists"
else
    warning "Bluetooth A2DP configuration was not found"
    echo
    echo "This is not required for normal wired/HDMI audio."
    echo "If your Omarchy installation has this file, copy its contents here:"
    echo
    echo "  $BLUETOOTH_CONFIG"
fi


# -----------------------------------------------------------------------------
# 9. ENABLE RTKIT
#
# PipeWire/WirePlumber can use RTKit for realtime scheduling.
# -----------------------------------------------------------------------------

info "Configuring RTKit"

sudo systemctl enable --now rtkit-daemon.service

if systemctl is-active --quiet rtkit-daemon.service; then
    success "RTKit is running"
else
    warning "RTKit is not running"
fi


# -----------------------------------------------------------------------------
# 10. ENABLE PIPEWIRE USER SERVICES
# -----------------------------------------------------------------------------

info "Enabling PipeWire services"

systemctl --user enable pipewire.service
systemctl --user enable pipewire-pulse.service
systemctl --user enable wireplumber.service

success "PipeWire user services enabled"


# -----------------------------------------------------------------------------
# 11. RESTART AUDIO SERVICES
# -----------------------------------------------------------------------------

info "Restarting audio services"

systemctl --user restart pipewire.service
systemctl --user restart pipewire-pulse.service
systemctl --user restart wireplumber.service

sleep 3

success "Audio services restarted"


# -----------------------------------------------------------------------------
# 12. SAVE ALSA MIXER STATE
#
# This stores the current hardware mixer state in:
#
#   /var/lib/alsa/asound.state
#
# We do not copy an old state file blindly because mixer controls can differ.
# -----------------------------------------------------------------------------

info "Saving ALSA mixer state"

sudo alsactl store

success "ALSA mixer state saved"


# -----------------------------------------------------------------------------
# 13. VERIFY PIPEWIRE
# -----------------------------------------------------------------------------

info "Checking PipeWire"

if systemctl --user is-active --quiet pipewire.service; then
    success "pipewire.service is running"
else
    warning "pipewire.service is NOT running"
fi


# -----------------------------------------------------------------------------
# 14. VERIFY PIPEWIRE-PULSE
# -----------------------------------------------------------------------------

info "Checking PulseAudio compatibility layer"

if systemctl --user is-active --quiet pipewire-pulse.service; then
    success "pipewire-pulse.service is running"
else
    warning "pipewire-pulse.service is NOT running"
fi


# -----------------------------------------------------------------------------
# 15. VERIFY WIREPLUMBER
# -----------------------------------------------------------------------------

info "Checking WirePlumber"

if systemctl --user is-active --quiet wireplumber.service; then
    success "wireplumber.service is running"
else
    warning "wireplumber.service is NOT running"
fi


# -----------------------------------------------------------------------------
# 16. SHOW PACTL INFORMATION
# -----------------------------------------------------------------------------

info "PulseAudio compatibility information"

pactl info || warning "pactl could not connect"


# -----------------------------------------------------------------------------
# 17. SHOW AUDIO DEVICES
# -----------------------------------------------------------------------------

info "Audio devices"

wpctl status


# -----------------------------------------------------------------------------
# 18. SHOW SINKS
# -----------------------------------------------------------------------------

info "Available audio outputs"

pactl list short sinks


# -----------------------------------------------------------------------------
# 19. SHOW SOURCES
# -----------------------------------------------------------------------------

info "Available audio inputs"

pactl list short sources


# -----------------------------------------------------------------------------
# 20. SHOW DEFAULT DEVICES
# -----------------------------------------------------------------------------

info "Default audio devices"

echo
echo "Default Sink:"
pactl get-default-sink

echo
echo "Default Source:"
pactl get-default-source


# -----------------------------------------------------------------------------
# 21. SHOW RTKIT STATUS
# -----------------------------------------------------------------------------

info "RTKit status"

systemctl status rtkit-daemon.service --no-pager --lines=5 || true


# -----------------------------------------------------------------------------
# 22. FINAL SUMMARY
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo " Audio setup complete"
echo "============================================================"
echo
echo "Audio stack:"
echo "  ALSA             : enabled"
echo "  PipeWire         : enabled"
echo "  PipeWire Pulse   : enabled"
echo "  WirePlumber      : enabled"
echo "  RTKit            : enabled"
echo
echo "PulseAudio clients:"
echo "  pipewire-pulse provides the PulseAudio API"
echo
echo "ALSA state:"
echo "  /var/lib/alsa/asound.state"
echo
echo "============================================================"
echo
echo "Recommended: reboot before testing audio."
echo
