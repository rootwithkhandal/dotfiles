{ pkgs, ... }:

{
  home.packages = with pkgs; [

    bluez
    python3Packages.bleak
    usbutils
    pciutils
    dmidecode
    lm_sensors

  ];
}
