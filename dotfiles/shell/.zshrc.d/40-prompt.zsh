export ZSH="$HOME/.oh-my-zsh"

# Disable OMZ completion management (we own it)
zstyle ':omz:plugins:completion' use-cache off
zstyle ':omz:plugins:completion' rehash true

export DISABLE_AUTO_UPDATE=true
export DISABLE_UPDATE_PROMPT=true
export DISABLE_COMPFIX=true


# ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  history
  battery 
  brew 
  coffee 
  copybuffer 
  copyfile
  copypath 
  dirhistory 
  terraform 
  toolbox 
  torrent 
  vscode 
  web-search 
  xcode
  zsh-interactive-cd 
  zsh-navigation-tools
  dotenv 
  ruby 
  colorize
  eza 
  grc
)

# Instant prompt (must be first)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


source "$ZSH/oh-my-zsh.sh"
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
