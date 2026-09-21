{ pkgs, ... }:

{
  home.packages = with pkgs; [

    burpsuite
    ffuf
    feroxbuster
    gobuster
    katana
    nuclei
    sqlmap
    nikto
    wpscan
    dalfox
    arjun
    gau
    gospider
    whatweb
    zap

  ];
}
