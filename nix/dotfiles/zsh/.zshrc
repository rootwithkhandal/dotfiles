# =========================================================
# Interactive guard
# =========================================================

[[ -o interactive ]] || return


# =========================================================
# Load user configuration
# =========================================================

for file in "$HOME/.zshrc.d/"*.zsh; do
    [[ -r "$file" ]] && source "$file"
done

for file in "$HOME/.zsh/aliases/"*.zsh; do
    [[ -r "$file" ]] && source "$file"
done

for file in "$HOME/.zsh/functions/"*.zsh; do
    [[ -r "$file" ]] && source "$file"
done


# =========================================================
# Starship
# =========================================================

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

eval "$(starship init zsh)"


# =========================================================
# Atuin
# =========================================================

if [[ -f "$HOME/.atuin/bin/env" ]]; then
    source "$HOME/.atuin/bin/env"
fi

eval "$(atuin init zsh)"


# =========================================================
# FZF
# =========================================================

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'

if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"


# =========================================================
# Zoxide
# =========================================================

eval "$(zoxide init zsh)"


# =========================================================
# Direnv
# =========================================================

eval "$(direnv hook zsh)"


# =========================================================
# Ranger
# =========================================================

function ranger {
    local IFS=$'\t\n'
    local tempfile="$(mktemp -t tmp.XXXXXX)"

    local ranger_cmd=(
        command
        ranger
        --cmd="map Q chain shell echo %d > $tempfile; quitall"
    )

    "${ranger_cmd[@]}" "$@"

    if [[ -f "$tempfile" ]] &&
       [[ "$(cat -- "$tempfile")" != "$(pwd)" ]]; then
        cd -- "$(cat "$tempfile")" || return
    fi

    command rm -f -- "$tempfile" 2>/dev/null
}

alias rr='ranger'


# =========================================================
# Directory navigation
# =========================================================

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."


# =========================================================
# General
# =========================================================

alias cl='clear'
alias cat='bat'

alias l="eza -l --icons --git -a"
alias la="eza -la --icons --git"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2 --icons --git"


# =========================================================
# Go
# =========================================================

export GOPATH="$HOME/go"

export PATH="$GOPATH/bin:$PATH"


# =========================================================
# Neovim
# =========================================================

alias v="nvim"


# =========================================================
# Kubernetes
# =========================================================

export KUBECONFIG="$HOME/.kube/config"

alias k="kubectl"
alias ka="kubectl apply -f"
alias kg="kubectl get"
alias kd="kubectl describe"
alias kdel="kubectl delete"
alias kl="kubectl logs -f"
alias kgpo="kubectl get pods"
alias kgd="kubectl get deployments"
alias kc="kubectx"
alias kns="kubens"
alias ke="kubectl exec -it"
alias kcns='kubectl config set-context --current --namespace'


# =========================================================
# HTTP
# =========================================================

alias http="xh"


# =========================================================
# Security
# =========================================================

alias nm="nmap -sC -sV -oN nmap"

alias gobust='gobuster dir --wordlist "$HOME/security/wordlists/diccnoext.txt" --wildcard --url'

alias dirsearch='python dirsearch.py -w db/dicc.txt -b -u'

alias massdns='$HOME/hacking/tools/massdns/bin/massdns -r $HOME/hacking/tools/massdns/lists/resolvers.txt -t A -o S bf-targets.txt -w livehosts.txt -s 4000'

alias server='python -m http.server 4445'

alias tunnel='ngrok http 4445'

alias fuzz='ffuf -w "$HOME/hacking/SecLists/content_discovery_all.txt" -mc all -u'

alias gf='$HOME/go/src/github.com/tomnomnom/gf/gf'


# =========================================================
# Git
# =========================================================

alias gc="git commit -m"
alias gca="git commit -a -m"

alias gp="git push origin HEAD"
alias gpu="git pull origin"

alias gst="git status"

alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"

alias gdiff="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gba="git branch -a"
alias gadd="git add"
alias ga="git add -p"
alias gcoall="git checkout -- ."
alias grem="git remote"
alias gre="git reset"


# =========================================================
# Docker
# =========================================================

alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker ps -l -q"
alias dx="docker exec -it"


# =========================================================
# Vi mode
# =========================================================

bindkey jj vi-cmd-mode


# =========================================================
# Locale
# =========================================================

export LC_ALL="en_US.UTF-8"


# =========================================================
# Fastfetch
# =========================================================

if command -v fastfetch >/dev/null 2>&1; then
    fastfetch \
        --config "$HOME/.config/fastfetch/config.nano.jsonc" \
        --logo "/opt/pokemon-colorscripts/colorscripts/small/regular/$(pokemon-colorscripts -l | head -251 | shuf -n 1)"
fi
