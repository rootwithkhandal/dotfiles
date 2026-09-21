{ pkgs, ... }:

{
  home.packages = with pkgs; [

    imagemagick
    ffmpeg
    poppler

  ];
}
