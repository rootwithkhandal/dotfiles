
{ config, pkgs, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      auto-optimise-store = true;

      trusted-users = [
        "root"
        "@wheel"
      ];

      # Locks down access to nix-daemon
      allowed-users = [
        "@wheel"
      ];
    };

    package = pkgs.nixVersions.git;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
  };
}
