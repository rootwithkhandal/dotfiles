{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "history"
        "colored-man-pages"
      ];
    };

    initContent = ''
      export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

      # Starship → primary prompt
      if command -v starship >/dev/null 2>&1; then
        eval "$(starship init zsh)" 2>/dev/null

        # Fallback to Powerlevel10k if Starship failed
        if [[ -z "$STARSHIP_SHELL" ]]; then
          if [[ -f "$HOME/.p10k.zsh" ]]; then
            source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
            source "$HOME/.p10k.zsh"
          fi
        fi
      else
        # Starship unavailable → Powerlevel10k
        if [[ -f "$HOME/.p10k.zsh" ]]; then
          source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
          source "$HOME/.p10k.zsh"
        fi
      fi
    '';
  };

  home.file.".p10k.zsh".source = ../dotfiles/zsh/.p10k.zsh;
}
