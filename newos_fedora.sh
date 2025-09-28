#!/bin/bash

# Written by NorthernChicken
# https://github.com/NorthernChicken/dhs-autoscript
# For personal use

set -uo pipefail

# State Tracking
TOTAL_ACTIONS=0
SUCCESSFUL_ACTIONS=0
FAILED_ACTIONS=()

# Helper Functions

# Wrapper function to execute commands
run_action() {
    local description="$1"
    shift

    ((TOTAL_ACTIONS++))
    echo "-->  $description..."

    if output=$("$@" 2>&1); then
        echo "✅  Success: $description"
        ((SUCCESSFUL_ACTIONS++))
    else
        echo "❌  Failure: $description" >&2
        echo "    -ERROR DETAILS-" >&2
        echo "$output" | sed 's/^/    /' >&2
        FAILED_ACTIONS+=("$description")
    fi
    echo
}

# For editing fstab
add_fstab_entry() {
    # Steam Library
    if ! grep -q "UUID=87f62db8-a45d-4955-ad93-e15c70f4ec22" /etc/fstab; then
        echo '#steam library drive
UUID=87f62db8-a45d-4955-ad93-e15c70f4ec22   /mnt/steamgames   ext4    rw,users,exec,auto   0 0' >> /etc/fstab
    fi

    # Windows Games
    if ! grep -q "UUID=1975D4020FD241DB" /etc/fstab; then
        echo '#windows games
UUID=1975D4020FD241DB /mnt/windowsgames ntfs-3g defaults,uid=1000,gid=1000,windows_names,umask=022,exec,permissions 0 0' >> /etc/fstab
    fi

    # Other drive
    if ! grep -q "UUID=e04a3879-dc4e-4ee2-a485-a624efb0f895" /etc/fstab; then
        echo '#bluekrill data drive
UUID=e04a3879-dc4e-4ee2-a485-a624efb0f895    /mnt/bluekrill    ext4    rw,users,exec,auto    0 0' >> /etc/fstab
    fi
}

# Gaming fixes
create_libinput_quirks() {
    echo "[asdfsajngiughiughbda]
MatchName=*
ModelBouncingKeys=1
" > /etc/libinput/local-overrides.quirks
}

# SpotX
install_spotx() {
    bash <(curl -sSL https://spotx-official.github.io/run.sh) -c -f
}

# Vencord
install_vencord() {
    sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
}

# Theme
install_orchis_theme() {
    tmp_dir=$(mktemp -d)
    run_action "Cloning Orchis KDE theme repository" git clone --depth=1 https://github.com/vinceliuice/Orchis-kde.git "$tmp_dir/Orchis-kde"

    run_action "Running Orchis KDE theme install script" bash "$tmp_dir/Orchis-kde/install.sh" --no-confirm
    run_action "Cleaning up Orchis KDE theme repo" rm -rf "$tmp_dir"
}

# Icons
install_tela_icons() {
    tmp_dir=$(mktemp -d)
    run_action "Cloning Tela Circle icon theme repository" git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$tmp_dir/Tela-circle-icon-theme"

    run_action "Running Tela Circle install script" bash "$tmp_dir/Tela-circle-icon-theme/install.sh" --dark --system
    run_action "Cleaning up Tela Circle icon repo" rm -rf "$tmp_dir"
}

set_kde_defaults() {
    local kdeglobals="/etc/skel/.config/kdeglobals"
    mkdir -p "$(dirname "$kdeglobals")"
    touch "$kdeglobals"

    run_action "Setting Orchis Dark as Plasma theme" sed -i 's/^PlasmaStyle=.*/PlasmaStyle=Orchis-dark/' "$kdeglobals" || echo "PlasmaStyle=Orchis-dark" >> "$kdeglobals"
    run_action "Setting Tela Circle Dark as icon theme" sed -i 's/^Icons=.*/Icons=Tela-circle-dark/' "$kdeglobals" || echo "Icons=Tela-circle-dark" >> "$kdeglobals"
}

# --- Main Script ---

echo "========================================================="
echo "  Starting dhs-autoscript for Fedora by NorthernChicken  "
echo "========================================================="
echo

# Root
if [[ $EUID -ne 0 ]]; then
   echo "Error: Run with root." >&2
   exit 1
fi

# Drive setup
run_action "Creating Steam games mount point" mkdir -p /mnt/steamgames
run_action "Mounting Steam games drive (/dev/nvme0n1p1)" mount /dev/nvme0n1p1 /mnt/steamgames

run_action "Creating Windows games mount point" mkdir -p /mnt/windowsgames
run_action "Mounting Windows games drive (/dev/nvme0n1p2)" mount /dev/nvme0n1p2 /mnt/windowsgames

run_action "Creating Bluekrill mount point" mkdir -p /mnt/bluekrill
run_action "Mounting Bluekrill drive (/dev/sda1)" mount /dev/sda1 /mnt/bluekrill

run_action "Adding drives to /etc/fstab for auto-mounting" add_fstab_entry

# Gaming fixes
run_action "Creating libinput configuration directory" mkdir -p /etc/libinput
run_action "Creating local overrides file for mouse debouncing" create_libinput_quirks
run_action "Creating Minecraft symlink" ln -s "/mnt/steamgames/.minecraft" "$HOME/.minecraft"

# Repositories and System Updates
run_action "Installing RPM Fusion Free repository" sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
run_action "Installing RPM Fusion Non-Free repository" sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
run_action "Updating all system packages" sudo dnf update -y
run_action "Installing predetermined basic packages" sudo dnf install -y fastfetch steam code kdenlive obs-studio chromium

# Flatpak Setup
run_action "Installing Flatpak" sudo dnf install -y flatpak

echo "Checking for Flathub remote..."
if ! flatpak remote-list | grep -q flathub; then
    run_action "Adding Flathub remote repository" sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    echo "Flathub remote already exists"
    echo
fi

run_action "Installing ProtonUp-Qt" flatpak install -y flathub net.davidotek.pupgui2
run_action "Installing PrismLauncher" flatpak install -y flathub org.prismlauncher.PrismLauncher

# Spotify and SpotX-Bash
run_action "Installing Spotify" flatpak install -y flathub com.spotify.Client
run_action "Installing SpotX" install_spotx

# Discord and Vencord
run_action "Installing Discord (Fusion RPM)" sudo dnf install -y discord
run_action "Installing Vencord" install_vencord

# KDE
install_orchis_theme
install_tela_icons
set_kde_defaults

# Final Summary

echo "========================================"
echo "          SETUP COMPLETE "
echo "========================================"
echo
echo "Summary: $SUCCESSFUL_ACTIONS / $TOTAL_ACTIONS actions were successful."
echo

if [ ${#FAILED_ACTIONS[@]} -ne 0 ]; then
    echo "The following actions failed:" >&2
    for action in "${FAILED_ACTIONS[@]}"; do
        echo "  - $action" >&2
    done
    echo
    echo "Please review" >&2
else
    echo "All actions completed successfully!"
fi

echo "========================================"
