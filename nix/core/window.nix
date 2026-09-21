{ config, pkgs, ... }:

{
  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          };
        theme = "sddm-astronaut-theme";
        extraPackages = [ pkgs.sddm-astronaut ];
      };
      # lightdm = {
      #   enable = false;
      # };
    };
    desktopManager = {
      pantheon = {
        enable = false;
      };

      gnome = {
        enable = true;
      };

    };
    xserver = {
      enable = true;            # X11 windowing system.
      xkb = {             # keymap in X11
        layout = "us";
        variant = "";
      };
    };
  };
}
