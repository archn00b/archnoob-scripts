#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROFILE="/tmp/archlive"
PACKAGES_FILE="$PROFILE/packages.x86_64"

# ------------------------------------------------------------------------------
# CLEAN BUILD DIRECTORY
# ------------------------------------------------------------------------------

rm -rf "$PROFILE"
mkdir -p "$PROFILE"

# ------------------------------------------------------------------------------
# INSTALL ARCHISO
# ------------------------------------------------------------------------------

sudo pacman --noconfirm -S archiso

# ------------------------------------------------------------------------------
# COPY BASE ARCHISO PROFILE
# ------------------------------------------------------------------------------

cp -r /usr/share/archiso/configs/releng/* "$PROFILE/"

# ------------------------------------------------------------------------------
# ADD ARCHN00B REPOSITORY
# ------------------------------------------------------------------------------

addrepo() {
    local pacman_conf="$PROFILE/pacman.conf"

    if ! grep -qxF '[core-repo]' "$pacman_conf"; then
        cat <<'EOF' | sudo tee -a "$pacman_conf" >/dev/null

[core-repo]
SigLevel = Optional TrustAll
Server = https://archn00b.github.io/$repo/$arch
EOF
    fi
}

addrepo

# ------------------------------------------------------------------------------
# INSTALL FONTS
# ------------------------------------------------------------------------------

mkdir -p "$PROFILE/airootfs/usr/share/fonts"

cp -rf FiraCode \
    "$PROFILE/airootfs/usr/share/fonts/"

# ------------------------------------------------------------------------------
# COPY USER CONFIGURATION
# ------------------------------------------------------------------------------

cp -rf users/* \
    "$PROFILE/airootfs/etc/"

cp -rf sddm.conf.d \
    "$PROFILE/airootfs/etc/"

cp -rf sudoers.d \
    "$PROFILE/airootfs/etc/"

cp -rf pam.d \
    "$PROFILE/airootfs/etc/"

cp -rf profiledef.sh \
    "$PROFILE/"

# ------------------------------------------------------------------------------
# BASH / STARSHIP CONFIGURATION
# ------------------------------------------------------------------------------

mkdir -p "$PROFILE/airootfs/etc/skel/.config"

cp -rf starship.toml \
    "$PROFILE/airootfs/etc/skel/.config/"

cp -rf .bashrc \
    "$PROFILE/airootfs/etc/skel/"

# ------------------------------------------------------------------------------
# ENABLE SDDM
# ------------------------------------------------------------------------------

mkdir -p "$PROFILE/airootfs/etc/systemd/system"

ln -sf \
    /usr/lib/systemd/system/sddm.service \
    "$PROFILE/airootfs/etc/systemd/system/display-manager.service"

# ------------------------------------------------------------------------------
# PACKAGES
# ------------------------------------------------------------------------------

packages=(
    xfce4
    xfce4-goodies
    xorg
    sddm
    alacritty
    archnoob-alacritty
    archnoob-sddm-theme
    firefox
    lsd
    starship
)

for package in "${packages[@]}"; do
    printf '%s\n' "$package" >> "$PACKAGES_FILE"
done

# ------------------------------------------------------------------------------
# BUILD ISO
# ------------------------------------------------------------------------------

cd "$PROFILE"

rm -rf work/*

mkarchiso -v -w work/ -o out/ ./