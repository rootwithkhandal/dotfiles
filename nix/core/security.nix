{ config, pkgs, ... }:

{
  security = {
    # if you want, you can disable sudo and use doas
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
      execWheelOnly = true;
    };

    # apparmor.enable = true;
    # lockKernelModules = true;

    auditd.enable = true;

    audit = {
      enable = true;
      rules = [
        "-a always,exit -F arch=b64 -S execve"
      ];
    };

    rtkit = {
      enable = true;
    };
  };
}
