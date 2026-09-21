path=(
  $HOME/bin
  $HOME/.local/bin
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $path
)

# macOS Homebrew
[[ -n $IS_MACOS && -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

# Go
path=(/usr/local/go/bin $GOPATH/bin $path)

# Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Krew / PDTM / Spicetify
path=(
  $HOME/.krew/bin
  $HOME/.pdtm/go/bin
  $HOME/.spicetify
  $path
)
