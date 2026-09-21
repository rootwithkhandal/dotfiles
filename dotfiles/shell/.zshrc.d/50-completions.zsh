# =========================================================
# Zsh completion system (single-init, cached)
# =========================================================

[[ -n "$_COMPINIT_DONE" ]] && return
typeset -g _COMPINIT_DONE=1

export ZSH_COMPDUMP="$HOME/.zcompdump"

autoload -Uz compinit
compinit -C -d "$ZSH_COMPDUMP"

fpath=(~/.zsh/site-functions $fpath)
autoload -Uz compinit && compinit