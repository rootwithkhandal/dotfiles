# { config, pkgs, ... }:

# {
#   # Bootloader.
#   boot = {
#     loader = {
#       systemd-boot = {
#         enable = false;
#       };
#       efi = {
#         canTouchEfiVariables = true;
#       };
#       grub = {
#         enable = true;
#         efiSupport = true;
#         efiInstallAsRemovable = false; # canTouchEfiVariables handles the NVRAM entry
#         device = "nodev"; # UEFI-only install, no MBR write needed
#         gfxmodeEfi = "1920x1080";
#         gfxmodeBios = "1920x1080";

#         theme = pkgs.stdenvNoCC.mkDerivation {
#           pname = "sidonia-grub-theme";
#           version = "unstable-2026-08-27";
#           src = pkgs.fetchFromGitHub {
#             owner = "Aleph1-9012";
#             repo = "Sidonia";
#             rev = "main";
#             # hash = pkgs.lib.fakeHash; # placeholder, see note below
#             hash = "sha256-wYCLywymI8I+Ay7+OhW8ZipprpX9gYj8hf4D4a9CTNc=";
#           };
#           installPhase = ''
#             mkdir -p $out
#             cp -r themes/T4/1080p/. $out/
#           '';
#         };
#       };
#     };
#   };
# }

{ config, pkgs, ... }:

{
  boot = {
    loader = {
      # Use GRUB instead of systemd-boot
      systemd-boot.enable = false;

      # UEFI
      efi = {
        canTouchEfiVariables = true;
      };

      # Default GRUB
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        device = "nodev";

        # Show the latest 7 NixOS generations
        configurationLimit = 7;
      };

      # Keep GRUB menu visible
      timeout = 5;
    };
  };
}
