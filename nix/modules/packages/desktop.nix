{ pkgs, ... }:

{
  home.packages = with pkgs; [

    ghostty
    waybar
    rofi
    hyprlauncher
    dunst
    thunar
    pavucontrol
    tela-icon-theme

    foot
    kitty
    alacritty
    wezterm
    htop
    ranger
    vlc
    spotify
    telegram-desktop
    discord
    signal-desktop
    tailscale
    thermald
    bluewalker
    redfang
    ubertooth
    # genymotion
    gqrx
    kalibrate-hackrf
    kalibrate-rtl

  ];
}
