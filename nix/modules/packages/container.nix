{ pkgs, ... }:

{
  home.packages = with pkgs; [

    dive
    dockle
    trivy
    grype
    cloudfox
    prowler

  ];
}
