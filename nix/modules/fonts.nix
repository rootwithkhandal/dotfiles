{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-cove
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
    nerd-fonts.hack

    inter
  ];
}
