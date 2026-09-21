{ config, pkgs, ... }:

{
  # Hyprland
  xdg.configFile."hypr" = {
    source = ./../dotfiles/hypr;
    force = true;
    recursive = true;
  };

  # Waybar
  xdg.configFile."waybar" = {
    source = ./../dotfiles/waybar;
    force = true;
    recursive = true;
  };

  # Rofi
  xdg.configFile."rofi" = {
    source = ./../dotfiles/rofi;
    force = true;
    recursive = true;
  };
}
