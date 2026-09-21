{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./core/audio.nix
    ./core/bootloader.nix
    ./core/networking.nix
    ./core/profiles.nix
    ./core/programs.nix
    ./core/security.nix
    ./core/services.nix
    ./core/settings.nix
    ./core/timezone.nix
    ./core/users.nix
    ./core/virtualisation.nix
    ./core/window.nix
  ];


  # Allow unfree packages
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowInsecurePredicate = p: true;
      segger-jlink.acceptLicense = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      neovim git curl wget
      vim nano file which
      pciutils usbutils lsof

      wayland-utils wl-clipboard

      sddm-astronaut
    ];
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };

  system = {
    stateVersion = "26.05";
  };
}
