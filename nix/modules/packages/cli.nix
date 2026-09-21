{ pkgs, ... }:

{
  home.packages = with pkgs; [

    bat
    eza
    btop
    fastfetch
    zoxide
    atuin
    direnv
    lazygit
    pay-respects
    lsof
    procs
    sd
    grex
    xh

  ];
}
