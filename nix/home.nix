{ config, pkgs, inputs, ... }:

{
  home = {
    username = "nyx";
    homeDirectory = "/home/nyx";
    stateVersion = "26.05";
  };

  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs = {
    fzf.enable = true;
    direnv.enable = true;
    waybar.enable = true;

    atuin = {
      enable = true;

      settings = {
        search_mode = "fuzzy";
        style = "compact";
      };
    };

    bash.enable = false;

    zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  # GTK / Icon Theme
  gtk = {
    enable = true;

    iconTheme = {
      package = pkgs.tela-icon-theme;
      name = "Tela";
    };
  };

  # GNOME/Pantheon settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      icon-theme = "Tela";
    };
  };


  # Cursor
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;

    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;

    size = 24;
  };

  # Make the cursor available to Wayland compositors
  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };
}
