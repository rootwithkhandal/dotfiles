{ pkgs, ... }:

{
  home.packages = with pkgs; [

    gitleaks
    trufflehog
    detect-secrets
    osv-scanner
    checkov
    trivy
    grype

  ];
}
