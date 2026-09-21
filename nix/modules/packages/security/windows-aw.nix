{ pkgs, ... }:

{
  home.packages = with pkgs; [

    bloodhound-py
    certipy
    certsync
    coercer
    donpapi
    evil-winrm
    kerbrute
    # pypykatz
    # lsassy
    smbmap
    smbscan
    enum4linux
    enum4linux-ng

  ];
}
