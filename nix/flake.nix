{
  description = "NixOS configuration for nyx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    grub2-themes = {
      url = "github:vinceliuice/grub2-themes";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
  }:
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./profiles.nix
        # inputs.grub2-themes.nixosModules.default
        inputs.home-manager.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs;
            };
            users = {
              nyx = {
                imports = [
                  ./home.nix
                  ./modules/fonts.nix
                  ./modules/git.nix
                  ./modules/hyprland.nix
                  # ./modules/packages.nix
                  ./modules/vscode.nix
                  ./modules/zsh.nix
                  ./modules/security.nix
                  # ./modules/development.nix
                  ./modules/agents.nix
                  ./modules/appnconfig.nix

                  ./modules/packages/apps.nix
                  ./modules/packages/bluetooth.nix
                  ./modules/packages/chain.nix
                  ./modules/packages/cli.nix
                  ./modules/packages/container.nix
                  ./modules/packages/core.nix
                  ./modules/packages/credential.nix
                  ./modules/packages/desktop.nix
                  ./modules/packages/dev.nix
                  ./modules/packages/exploitation.nix
                  ./modules/packages/file-analysis.nix
                  ./modules/packages/forensic.nix
                  ./modules/packages/fuzzing.nix
                  ./modules/packages/networking.nix
                  ./modules/packages/reverse-engineering.nix
                  ./modules/packages/shell.nix
                  ./modules/packages/traffic-analysis.nix
                  ./modules/packages/web.nix

                  ./modules/packages/security/cloud.nix
                  ./modules/packages/security/hardware.nix
                  ./modules/packages/security/mobile.nix
                  ./modules/packages/security/windows-aw.nix
                  ./modules/packages/security/wireless.nix
                ];
              };
            };
          };
        }
      ];
    };
  };
}
