{ config, pkgs, ... }:

{
  virtualisation = {
    docker.enable = true;
    hypervGuest.enable = true;
    virtualbox.guest.enable = false;
    vmware.guest.enable = true;
  };
}
