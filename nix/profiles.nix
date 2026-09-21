{ lib, ... }:

{
  options.profiles = {
    development.enable = lib.mkEnableOption "development toolchains (languages, compilers, dev utilities)";
    security.enable = lib.mkEnableOption "security / pentesting toolkit";
  };
}
