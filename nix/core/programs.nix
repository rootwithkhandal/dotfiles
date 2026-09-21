{ config, pkgs, ... }:

{
  programs = {
    # mtr.enable = true;
    # gnupg = {
    #   agent = {
    #     enable = true;
    #     enableSSHSupport = true;
    #   };
    # };

    firefox.enable = true;
    zsh.enable = true;
    git.enable = true;

    # Wayland compositors
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland = {
        enable = true;
      };
    };

    dconf = {enable = true;};

    niri = {
      enable = true;
    };
  };
}
