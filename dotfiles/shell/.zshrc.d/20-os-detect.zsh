export OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
  Darwin)
    export IS_MACOS=1
    ;;
  Linux)
    export IS_LINUX=1
    ;;
esac

# WSL detection
if grep -qi microsoft /proc/version 2>/dev/null; then
  export IS_WSL=1
fi
