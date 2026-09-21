{ pkgs, ... }:

{
  home.packages = with pkgs; [

    testdisk
    ntfsprogs
    ntfs3g
    ddrescue
    ddrescueview
    sleuthkit
    foremost
    ext4magic
    extundelete
    dislocker
    exiv2
    stegseek

  ];
}
