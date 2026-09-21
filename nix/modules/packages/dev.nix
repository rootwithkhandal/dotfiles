{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Compilers / build tools
    gcc gnumake cmake pkg-config binutils llvm gdb

    # Languages
    go rustup nodejs ruby
    # Python
    (
      python3.withPackages (
        ps: with ps; [
          pip requests dnspython setuptools virtualenv
        ]
      )
    )

    # Nix development
    nil nixfmt

    # Development CLI
    delta postman awscli2 podman-desktop

    # Shell development
    shellcheck shfmt
  ];
}
