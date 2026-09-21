{ pkgs, ... }:

{
  home.packages = with pkgs; [

    iproute2
    iputils
    inetutils
    mtr
    nmap
    netcat-gnu
    netdiscover
    netexec
    masscan
    rustscan
    naabu
    arp-scan
    whois
    dnsrecon
    amass
    subfinder
    httpx

  ];
}
