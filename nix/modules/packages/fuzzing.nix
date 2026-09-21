{ pkgs, ... }:

{
  home.packages = with pkgs; [

    aflplusplus
    ffuf
    honggfuzz
    radamsa
    wfuzz
    boofuzz


  ];
}
