{ pkgs, ... }:

{
  home.packages = with pkgs; [

    abootimg
    androguard
    apkeep
    apkleaks
    apktool
    dex2jar
    # genymotion
    payload-dumper-go
    scrcpy
    simg2img
    trueseeing

  ];
}
