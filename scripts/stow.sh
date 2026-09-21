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
    TARGET_DIR="$HOME"

    APPS=("antigravity" "atuin" "bat" "bettercap" "brave" "burpsuite" "chrome" "cursor" "discord" "fonts" "ghostty" "icons" "kiro" "monkeytype" "neofetch" "ngrok" "nvim" "obs" "powershell" "shell" "slack" "spotify" "ssh" "starship" "sublime" "swift" "themes" "tmux" "vscode" "wallpaper" "warp" "wezterm" "zed" "zen")
    
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
