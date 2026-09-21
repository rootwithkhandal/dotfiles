nvm() {
  unset -f nvm node npm
  source "$NVM_DIR/nvm.sh"
  nvm "$@"
}

node() { nvm exec default node "$@"; }
npm()  { nvm exec default npm "$@"; }
