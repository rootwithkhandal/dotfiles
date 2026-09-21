{ pkgs, ... }:

{
  home.packages = with pkgs; [

    zed-editor
    obsidian
    brave
    powershell
    localsend
    thunderbird
  ];
}
