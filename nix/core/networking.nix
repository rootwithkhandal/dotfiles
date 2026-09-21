{ config, pkgs, ... }:

{
  # bluetooth
  hardware.bluetooth.enable = true;

  # networking
  networking = {
    hostName = "nixos";
    wireless = {
      enable = true;  # Enables wireless support via wpa_supplicant.
    };
    # proxy = {
    #   default = "http://user:password@proxy:port/";
    #   noProxy = "127.0.0.1,localhost,internal.domain";
    # };
    networkmanager = {
      enable = true;
    };

    firewall = {
      allowedTCPPorts = [22 80];
      allowPing = false;
      checkReversePath = "loose";
      logReversePathDrops = true;
      autoLoadConntrackHelpers = false;
      connectionTrackingModules = [
        "ftp"
        "irc"
        "sane"
        "sip"
        "tftp"
        "amanda"
        "h323"
        "netbios_sn"
        "pptp"
        "snmp"
      ];
      # trustedInterfaces = [ "" ];
    };
  };
}
