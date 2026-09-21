{ config, pkgs, ... }:

{
  profiles = {
    development = {
      enable = true;
    };
    security = {
      enable = true;
    };
  };
}
