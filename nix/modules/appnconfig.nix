{ config, pkgs, inputs, ... }:

{
  # ghostty
  xdg.configFile."ghostty/config".source =
    ./../dotfiles/ghostty/config;

  # alacritty
  xdg.configFile."alacritty/alacritty.toml".source =
    ./../dotfiles/alacritty/alacritty.toml;

  # btop
  xdg.configFile."btop/btop.conf".source =
    ./../dotfiles/btop/btop.conf;

  # foot
  xdg.configFile."foot/foot.ini".source =
    ./../dotfiles/foot/foot.ini;

  # herdr
  xdg.configFile."herdr/config.toml".source =
    ./../dotfiles/herdr/config.toml;

  # kitty
  xdg.configFile."kitty/kitty.conf".source =
    ./../dotfiles/kitty/kitty.conf;

  xdg.configFile."kitty/Catppuccin-Mocha.conf".source =
    ./../dotfiles/kitty/Catppuccin-Mocha.conf;

  xdg.configFile."kitty/current-theme.conf".source =
    ./../dotfiles/kitty/current-theme.conf;

  # tmux
  xdg.configFile."tmux/tmux.conf".source =
    ./../dotfiles/tmux/tmux.conf;

  # lazygit
  xdg.configFile."lazygit/config.yml".source =
    ./../dotfiles/lazygit/config.yml;

  # wezterm
  xdg.configFile."../.wezterm.lua".source =
    ./../dotfiles/wezterm/.wezterm.lua;

  # zed
  xdg.configFile."zed/settings.json".source =
    ./../dotfiles/zed/settings.json;

  # starship
  xdg.configFile."starship.toml".source =
    ./../dotfiles/starship/starship.toml;
}
