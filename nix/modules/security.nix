{
  pkgs,
  lib,
  osConfig,
  ...
}:

{
  home.packages = lib.mkIf osConfig.profiles.security.enable (
    with pkgs;
    [
      burpsuite
      nmap
    
      tcpdump
      arp-scan
      netdiscover
      traceroute

      gobuster
      dirb
      ffuf
      feroxbuster

      nuclei
      subfinder
      httpx
      assetfinder
      amass
      gau
      waybackurls
      httprobe
      naabu
      sqlmap
      nikto
      wfuzz

      hydra
      john
      hashcat

      aircrack-ng

      enum4linux-ng
      smbmap

      responder
      seclists

      metasploit

      apktool
      frida-tools

      net-tools
      iftop

      openvpn
      wireguard-tools
      networkmanagerapplet
      lynx
      speedtest-cli
      httpie

      proxychains-ng
    ]
  );
}
