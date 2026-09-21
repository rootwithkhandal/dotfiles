{ pkgs, ... }:

{
  home.packages = with pkgs; [

    # arduino
    cantoolz
    # chipsec
    cmospwd
    # esptool
    gallia
    hachoir
    # nrfutil
    # teensy-loader-cli
    # pyi2cflash
    # pyspiflash

  ];
}
