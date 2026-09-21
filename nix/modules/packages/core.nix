{ pkgs, ... }:

{
  home.packages = with pkgs; [

    curl
    wget
    git
    jq
    ripgrep
    ripgrep-all
    fd
    fzf
    tree
    file
    unzip
    zip
    p7zip
    cabextract
    unrar

  ];
}
