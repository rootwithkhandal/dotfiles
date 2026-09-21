{ pkgs, ... }:

{
  home.packages = with pkgs; [

    aircrack-ng
    airgeddon
    bully
    cowpatty
    kismet
    pixiewps
    # reaver-wps
    # reaver-wps-t6x
    wifite2
    gqrx
    kalibrate-hackrf
    kalibrate-rtl
    multimon-ng
    killerbee

  ];
}
