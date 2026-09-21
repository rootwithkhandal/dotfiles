{ pkgs, ... }:

{
  home.packages = with pkgs; [

    gdb
    # pwndbg
    ghidra-bin
    radare2
    rizin
    # r2pipe
    capstone
    unicorn
    valgrind
    volatility3
    yara
    flare-floss
    # binrep

  ];
}
