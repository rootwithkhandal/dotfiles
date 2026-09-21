{ pkgs, ... }:

{
  home.packages = with pkgs; [
    opencode
    codex
    claude-code
    kiro-cli
    kiro
    antigravity
    gemini-cli
  ];
}
