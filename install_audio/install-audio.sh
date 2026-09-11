#!/usr/bin/env bash

set -Eeuo pipefail

#--------------------------------------------------------------------------------------------------
# AUDIO
#--------------------------------------------------------------------------------------------------

audio_packages=(
    pulseaudio
    pulseaudio-alsa
    pavucontrol
    xfce4-pulseaudio-plugin
)

pipewire_packages=(
    pipewire
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    wireplumber
)

echo "Removing PipeWire audio stack..."

sudo pacman -Rns --noconfirm "${pipewire_packages[@]}" 2>/dev/null || true

echo
echo "Installing PulseAudio..."

sudo pacman -S --needed "${audio_packages[@]}"

echo
echo "PulseAudio setup complete."
echo

#--------------------------------------------------------------------------------------------------
# VERIFY
#--------------------------------------------------------------------------------------------------

echo "Audio server:"
pactl info | grep -E 'Server Name|Server String'

echo
echo "PulseAudio version:"
pulseaudio --version

echo
echo "Audio devices:"
pactl list short sinks

echo
echo "Done."