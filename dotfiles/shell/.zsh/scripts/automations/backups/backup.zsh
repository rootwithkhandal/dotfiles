function backup_all() {
    local backup_destination = "$HOME/.backup/$(date +%d-%m-%Y)"
    local config_destination="$backup_destination/.config"


    local vscode_settings_source="$HOME/.config/Code/User/settings.json"
    local vscode_settings_destination="$config_destination/Code/User/settings.json"
    if [[ ! -d "$vscode_settings_destination" ]]; then
        echo "Destination directory '$vscode_settings_destination' does not exist. Creating it."
        mkdir -p "$config_dest_dir"
    fi


    local vscode_extensions_source="$HOME/.vscode/extensions"
    local vscode_extensions_destination="$backup_destination/.vscode"

    local autostart_source="$HOME/.config/autostart"
    local autostart_destination="$config_destination/autostart"

    local neofetch_config_source="$HOME/.config/neofetch"
    local neofetch_config_destination="$config_destination/.config/neofetch"

    local powershell_ps1_source="$HOME/.config/powershell"
    local powershell_ps1_destination="$config_destination/powershell"

    local sublime_text_settings_destination="$HOME/.config/sublime-text/Packages"
    local sublime_text_settings_destination="$config_destination/sublime-text/Packages"

    local sublime_text_themes_source="$HOME/.config/sublime-text/Packages"
    local sublime_text_themes_destination="$config_destination/sublime-text/Packages"

    local warp_terminal_settings_source="$HOME/.config/warp-terminal"
    local warp_terminal_settings_destination="$config_destination/warp-terminal"

    # local/share/warp-terminal
    local warp_terminal_theme_source="$HOME/.local/share/warp-terminal"
    local warp_terminal_theme_destination="$backup_destination/.local/share/warp-terminal"

    local nvim_source="$HOME/.config/nvim"
    local nvim_destination="$config_destination/nvim"

    local starship_source="$HOME/.config/starship.toml"
    local starship_destination="$config_destination/starship.toml"

    local zed_settings_source="$HOME/.config/zed"
    local zed_settings_destination="$config_destination/zed"

    local zed_extensions_source="$HOME/.config/zed/extensions"
    local zed_extensions_destination="$config_destination/zed/extensions"

    local ghostty_config_source="$HOME/.config/ghostty"
    local ghostty_config_destination="$config_destination/ghostty"

    local zsh_source="$HOME/.zsh"
    local zsh_source="$backup_destination/.zsh"
    
    local zshrc_source="$HOME/.zshrc"
    local zshrc_destination="$backup_destination/.zshrc"

    local p10k_source="$HOME/.p10k.zsh"
    local p10k_source="$backup_destination/.p10k.zsh"

    local wezterm_source="$HOME/.wezterm.lua"
    local wezterm_source="$backup_destination/.wezterm.lua"

    local tmux_source="$HOME/.tmux.conf"
    local tmux_source="$backup_destination/.tmux.conf"

    local zprofile_source="$HOME/.zprofile"
    local zprofile_source="$backup_destination/.zprofile"

    local swift_source="$HOME/.apps/.swift"
    local swift_source="$backup_destination/.apps/.swift"

    local bat_source="$HOME/.apps/.bat"
    local bat_source="$backup_destination/.apps/.bat"

    local ssh_source="$HOME/.ssh"
    local ssh_source="$backup_destination/.ssh"




    # Check if destination directory exists, if not create it
    if [[ ! -d "$config_dest_dir" ]]; then
        echo "Destination directory '$config_dest_dir' does not exist. Creating it."
        mkdir -p "$config_dest_dir"
    fi

    
}
