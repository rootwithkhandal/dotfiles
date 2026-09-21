#!/bin/bash

install_stow() {
    echo "┌────────────────────────────────────┐"
    echo "│         [+] Installing stow        │"
    echo "└─────────────────────────────╴ marine"

    sudo apt install -y stow
    clear
}



stowing() {
    STOW_DIR="stow"
    STOWi3_DIR="i3"
    TARGET_DIR="$HOME"

    APPS=("atuin" "bash" "bat" "bettercap" "brave" "burpsuite" "chrome" "cursor" "discord" "fish" "fonts" "ghostty" "icons" "kiro" "monkeytype" "neofetch" "ngrok" "nvim" "obs" "powershell" "slack" "spotify" "ssh" "starship" "sublime" "swift" "themes" "tmux" "vscode" "wallpapers" "warp" "wezterm" "zed" "zen" "zsh")
    
    echo "┌────────────────────────────────────────────────┐"
    echo "│     [+] Installing dotfiles using GNU Stow     │"
    echo "└─────────────────────────────────────────╴ marine"
    echo ""
    echo "[*] Target directory: $TARGET_DIR [*]"

    for app in "${APPS[@]}"; do
        echo "→ Stowing $app"
        stow -d "$STOW_DIR" -t "$TARGET_DIR" "$app"
    done
}


# Main Execution
install_stow
stowing