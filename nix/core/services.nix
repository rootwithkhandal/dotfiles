{ config, pkgs, ... }:

{
  services = {
    # openssh
    openssh = {
      enable = false; # rednix: true
      allowSFTP = false; # rednix: true
      settings = {
        AllowAgentForwarding = false;
        AllowStreamLocalForwarding = false;
        AllowTcpForwarding = true;
        AuthenticationMethods = "publickey";
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        X11Forwarding = false;
      };
    };

    # avahi = {
    #   enable = true;
    #   browseDomains = [];
    #   wideArea = false;
    #   nssmdns4 = true;
    # };

    # unbound = {
    #   enable = true;
    #   settings.server = {
    #     access-control = [];
    #     interface = [];
    #   };
    # };

    # using VPN is generally a good idea
    # use Mullvad btw
    # mullvad-vpn.enable = true;

    hardware.bolt.enable = true;

    spice-vdagentd.enable = true;
    qemuGuest.enable = true;

    printing.enable = false;
    xserver = {
      # libinput.enable = true;
    };
  };
}
