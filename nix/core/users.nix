{ config, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."nyx" = {
    isNormalUser = true;
    description = "Priyansh Khandal";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "input"
      "docker"
    ];

    shell = pkgs.zsh;
  };
}
