{ pkgs, ... }:

{
  home.packages = with pkgs; [

    tcpdump
    # tshark
    termshark
    wireshark
    mitmproxy
    socat

  ];
}
