{ pkgs, ... }:

{
  home.packages = with pkgs; [

    cloudfox
    cloud-nuke
    ec2stepshell
    gcp-scanner
    gato
    goblob
    imdshift
    pacu
    prowler
    yatas

  ];
}
