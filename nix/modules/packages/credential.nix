{ pkgs, ... }:

{
  home.packages = with pkgs; [

    hashcat
    hashcat-utils
    john
    thc-hydra
    medusa
    ncrack
    crunch
    hcxtools

  ];
}
