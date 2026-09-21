#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$DOTFILES_DIR/scripts/config"
TARGET_DIR="${STOW_TARGET:-$HOME}"
LOG_FILE="${LOG_FILE:-install.log}"
PYTHON_BIN=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEPENDENCY_PACKAGES=(
  git curl wget fuse libfuse2 dunst libnautilus-extension1a arp-scan
  python3 python3-pip python3-venv python3-requests python3-setuptools python3-dev
  python3-dnspython python3-dns python3-nautilus python3-gi
  nautilus-python nautilus-data nautilus-admin nautilus-image-converter
  imagemagick battery-stats git-delta ffmpeg pipx binutils-gold gcc
  libcurl4-openssl-dev libedit-dev libicu-dev libncurses-dev libpython3-dev
  libsqlite3-dev libxml2-dev pkg-config tzdata uuid-dev cmatrix gotop
  build-essential autojump sysstat ifstat net-tools iftop iperf3 nmtui
  speedtest-cli speed sd taskwarrior tee ruby-dev ruby-full xrandr xdotool
  xclip xsel devilspie2 fonts-font-awesome appmenu-gtk-module-common
  libdbusmenu-gtk3-4 libdbusmenu-qt5-2 vala-panel-appmenu appmenu-qt5
  poppler-utils awscli
)

APP_PACKAGES=(
  chromium gimp audacity neovim golang rust-all python3 htop btop tytop
  neofetch screenfetch apkinfo ranger cisco-auditing-tool apktool nano
  wireshark tshark tcpdump openvpn tor proxychains4 network-manager-gnome
  macchanger menson openvas hydra john hashcat aircrack-ng crunch
  hash-identifier dnsenum enum4linux smbclient smbmap crackmapexec bloodhound
  neo4j seclists wfuzz gobuster dirb feroxbuster nikto sqlmap netdiscover
  fzf fd-find ripgrep asciinema colorls curl wget nmap 7zip nodejs npm jq
  traceroute polybar burpsuite zenmap metasploit-framework ufw lynx direnv
  zoxide thefuck eza vlc
)

FLATPAK_APPS=(
  org.zaproxy.ZAP io.podman_desktop.PodmanDesktop com.github.tchx84.Flatseal
  io.github.flattool.Warehouse org.gnome.Logs org.gnome.font-viewer
  com.github.xournalpp.xournalpp com.obsproject.Studio com.signal.Signal-Desktop
  com.getpostman.Postman org.telegram.desktop io.github.zen_browser.zen
  com.todoist.Todoist md.obsidian.Obsidian org.angryip.ipscan
  io.emeric.toolblex com.github.flathub.Flathub-Slack
)

VSCODE_EXTENSIONS=(
  aaron-bond.better-comments almenon.arepl anthropic.claude-code
  aykutsarac.jsoncrack-vscode batisteo.vscode-django be5invis.vscode-custom-css
  chandan-sharma.csv-reader christian-kohler.npm-intellisense cocopon.iceberg-theme
  continue.continue davidbwaters.macos-modern-theme
  donjayamanne.python-environment-manager donjayamanne.python-extension-pack
  eamodio.gitlens charliermarsh.ruff esbenp.prettier-vscode github.copilot
  github.copilot-chat ivanarjona.cloudflaretunnel johnpapa.vscode-peacock
  kevinrose.vsc-python-indent mechatroner.rainbow-csv mindaro-dev.file-downloader
  ms-azuretools.vscode-containers ms-azuretools.vscode-docker
  ms-python.vscode-python-envs ms-toolsai.jupyter ms-toolsai.jupyter-keymap
  ms-toolsai.jupyter-renderers ms-toolsai.vscode-jupyter-cell-tags
  ms-toolsai.vscode-jupyter-slideshow ms-vscode-remote.remote-ssh-edit
  ms-vscode-remote.remote-wsl ms-vscode-remote.vscode-remote-extensionpack
  ms-vscode.remote-explorer ms-vscode.remote-server mtxr.sqltools
  njpwerner.autodocstring oderwat.indent-rainbow pkief.material-icon-theme
  postman.postman-for-vscode quicktype.quicktype redhat.vscode-yaml
  shalldie.background silofy.hackthebox tht13.python
  visualstudioexptteam.intellicode-api-usage-examples
  visualstudioexptteam.vscodeintellicode wholroyd.jinja
  wolfieshorizon.python-auto-venv ms-vscode-remote.remote-ssh
  ms-vscode-remote.remote-containers gruntfuggly.todo-tree usernamehw.errorlens
  wmaurer.change-case ms-python.python ms-python.black-formatter ms-python.debugpy
  dbaeumer.vscode-eslint xabikos.javascriptsnippets pranaygp.vscode-css-peek
  formulahendry.auto-close-tag formulahendry.auto-rename-tag
  zhuangtongfa.material-theme juanblanco.solidity nomicfoundation.hardhat-solidity
  tintinweb.solidity-visual-auditor tintinweb.vscode-solidity-flattener
  tintinweb.vscode-solidity-metrics tintinweb.vscode-security-auditor
  infosec.vscode-nmap muteki.vscode-pcap spmeesseman.vscode-taskexplorer
  githyanki.debugtron kakumei.jsontools sandcastle.vscode-open-in-burp
  vscode-icons-team.vscode-icons ms-vscode.powershell
  ms-azuretools.vscode-azurefunctions ms-kubernetes-tools.vscode-kubernetes-tools
  ms-vscode.azure-repos ionutvmi.path-autocomplete bencoleman.armview
  elastic.elastic-vscode foxundermoon.shell-format golang.go
  bmewburn.vscode-intelephense-client rebornix.ruby timonwong.shellcheck
  mads-hartmann.bash-ide-vscode shakram02.bash-beautify hashicorp.terraform
  naumovs.color-highlight akamud.vscode-theme-onedark spywhere.guides
  glassit.alpha enkia.tokyo-night catppuccin.catppuccin-vsc
  ms-vscode.cpptools-extension-pack ms-python.vscode-pylance
)

FIREWALL_RULES=(
  disable
  "allow ssh/tcp"
  "limit ssh/tcp"
  "allow 19683/tcp"
  "logging on"
  enable
  status
)

load_config_arrays() {
  local python_bin
  python_bin="$(command -v python3 || command -v python || true)"

  if [[ -z "$python_bin" ]]; then
    print_warn "python not found; using embedded Linux package lists"
    return
  fi

  if ! "$python_bin" - "$CONFIG_DIR" >/dev/null 2>&1 <<'PY'
import sys
from pathlib import Path
import yaml

config_dir = Path(sys.argv[1])
for name in ("apps.yaml", "settings.yaml", "vscode_extensions.yaml"):
    yaml.safe_load((config_dir / name).read_text())
PY
  then
    print_warn "Unable to read YAML configs; using embedded Linux package lists"
    return
  fi

  PYTHON_BIN="$python_bin"

  mapfile -t DEPENDENCY_PACKAGES < <("$python_bin" - "$CONFIG_DIR/apps.yaml" <<'PY'
import sys
from pathlib import Path
import yaml

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
for item in data.get("dependencies", []):
    print(item)
PY
  )

  mapfile -t APP_PACKAGES < <("$python_bin" - "$CONFIG_DIR/apps.yaml" <<'PY'
import sys
from pathlib import Path
import yaml

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
applications = data.get("applications", {}) or {}
for packages in applications.values():
    for item in packages or []:
        print(item)
PY
  )

  mapfile -t FLATPAK_APPS < <("$python_bin" - "$CONFIG_DIR/apps.yaml" <<'PY'
import sys
from pathlib import Path
import yaml

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
for item in data.get("flatpak_apps", []):
    print(item)
PY
  )

  mapfile -t VSCODE_EXTENSIONS < <("$python_bin" - "$CONFIG_DIR/vscode_extensions.yaml" <<'PY'
import sys
from pathlib import Path
import yaml

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
for item in data.get("vscode_extensions", []):
    print(item)
PY
  )

  mapfile -t FIREWALL_RULES < <("$python_bin" - "$CONFIG_DIR/settings.yaml" <<'PY'
import sys
from pathlib import Path
import yaml

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
for item in (data.get("firewall", {}) or {}).get("rules", []):
    print(item)
PY
  )
}

print_header() {
  printf '\n%s==== %s ====%s\n' "$BLUE" "$1" "$NC"
}

print_ok() {
  printf '%s[OK]%s %s\n' "$GREEN" "$NC" "$1"
}

print_warn() {
  printf '%s[WARN]%s %s\n' "$YELLOW" "$NC" "$1"
}

print_error() {
  printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$1" >&2
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    print_error "Run this command with sudo."
    exit 1
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    print_error "$command_name is required."
    exit 1
  fi
}

detect_package_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo apt
  elif command -v dnf >/dev/null 2>&1; then
    echo dnf
  elif command -v pacman >/dev/null 2>&1; then
    echo pacman
  else
    print_error "Unsupported package manager. Install packages manually."
    exit 1
  fi
}

install_os_packages() {
  require_root
  local manager
  manager="$(detect_package_manager)"
  local packages=("$@")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    return
  fi

  case "$manager" in
    apt)
      apt update
      apt install -y "${packages[@]}"
      ;;
    dnf)
      dnf install -y "${packages[@]}"
      ;;
    pacman)
      pacman -Sy --noconfirm "${packages[@]}"
      ;;
  esac
}

install_dependencies() {
  print_header "Installing dependency packages"
  install_os_packages "${DEPENDENCY_PACKAGES[@]}"
}

install_apps() {
  print_header "Installing application packages"
  install_os_packages "${APP_PACKAGES[@]}"
}

install_flatpak() {
  print_header "Installing Flatpak apps"
  require_root

  if ! command -v flatpak >/dev/null 2>&1; then
    install_os_packages flatpak
  fi

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  for app in "${FLATPAK_APPS[@]}"; do
    if flatpak list --app | grep -q "$app"; then
      print_ok "$app already installed"
    else
      flatpak install -y flathub "$app"
    fi
  done
}

install_vscode_extensions() {
  print_header "Installing VS Code extensions"
  require_command code

  for extension in "${VSCODE_EXTENSIONS[@]}"; do
    echo "Installing $extension"
    code --install-extension "$extension" --force
  done
}

install_custom_apps() {
  print_header "Installing custom apps"
  require_root
  mkdir -p /etc/apt/keyrings

  if [[ -z "$PYTHON_BIN" ]]; then
    print_warn "YAML config was not loaded; using built-in custom installer fallback"
    curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    chmod 644 /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' > /etc/apt/sources.list.d/wezterm.list
    curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | gpg --yes --dearmor -o /etc/apt/keyrings/ngrok.gpg
    chmod 644 /etc/apt/keyrings/ngrok.gpg
    echo "deb [signed-by=/etc/apt/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com buster main" > /etc/apt/sources.list.d/ngrok.list
    curl -fsS https://dl.brave.com/install.sh | sh
    curl -f https://zed.dev/install.sh | sh
    apt update
    apt install -y wezterm ngrok docker.io docker-compose
    return
  fi

  local apt_packages=()
  while IFS=$'\t' read -r name installer_type url key_url repo package; do
    [[ -n "$name" ]] || continue

    case "$installer_type" in
      apt_repo)
        local key_path="/etc/apt/keyrings/${name}.gpg"
        curl -fsSL "$key_url" | gpg --yes --dearmor -o "$key_path"
        chmod 644 "$key_path"
        echo "$repo" > "/etc/apt/sources.list.d/${name}.list"
        apt_packages+=("$package")
        ;;
      manual)
        print_warn "$name is marked manual in apps.yaml; skipping automatic install"
        ;;
      *)
        if [[ -n "$url" ]]; then
          curl -fsSL "$url" | sh
        fi
        ;;
    esac
  done < <("$PYTHON_BIN" - "$CONFIG_DIR/apps.yaml" <<'PY'
import sys
from pathlib import Path
import yaml

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
installers = data.get("custom_installers", {}) or {}
for name, config in installers.items():
    if not (config or {}).get("enabled", False):
        continue
    fields = [
        name,
        config.get("type", "script"),
        config.get("url", ""),
        config.get("key_url", ""),
        config.get("repo", ""),
        config.get("package", ""),
    ]
    print("\t".join(fields))
PY
  )

  if [[ "${#apt_packages[@]}" -gt 0 ]]; then
    apt update
    apt install -y "${apt_packages[@]}"
  fi

  apt install -y docker.io docker-compose
}

setup_gtk_theme() {
  print_header "Installing GTK icon and theme assets"
  mkdir -p "$HOME/.icons" "$HOME/.themes"

  if [[ ! -d /tmp/Qogir-icon-theme ]]; then
    git clone https://github.com/vinceliuice/Qogir-icon-theme /tmp/Qogir-icon-theme
  fi
  (cd /tmp/Qogir-icon-theme && chmod +x install.sh && ./install.sh)

  if [[ ! -d "$HOME/.themes/Space" ]]; then
    git clone https://github.com/EliverLara/Space.git "$HOME/.themes/Space"
  fi
}

start_services() {
  print_header "Starting services"
  require_root
  systemctl enable --now docker || true
  systemctl start ngrok.service || true
  service bluetooth start || true
  systemctl enable bluetooth || true
}

create_containers() {
  print_header "Creating Docker containers"
  require_root
  docker volume create portainer_data
  docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
    portainer/portainer-ce:2.9.3
  docker run -d -p 9001:9001 --name portainer_agent --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    portainer/agent:2.9.3
}

stow_dotfiles() {
  print_header "Stowing Linux dotfiles"
  require_command stow

  local stow_packages=(
    "$DOTFILES_DIR/linux/apps"/*
    "$DOTFILES_DIR/linux/assets"/*
    "$DOTFILES_DIR/linux/browser"/*
    "$DOTFILES_DIR/linux/cli"/*
    "$DOTFILES_DIR/linux/dev"/*
    "$DOTFILES_DIR/linux/editor"/*
    "$DOTFILES_DIR/linux/git"
    "$DOTFILES_DIR/linux/security"/*
    "$DOTFILES_DIR/linux/shell"
    "$DOTFILES_DIR/linux/ssh"
    "$DOTFILES_DIR/linux/terminal"/*
    "$DOTFILES_DIR/linux/wallpaper"
    "$DOTFILES_DIR/linux/wm"/*
    "$DOTFILES_DIR/linux/zen"
  )

  for package_path in "${stow_packages[@]}"; do
    [[ -d "$package_path" ]] || continue
    local package_dir package_name
    package_dir="$(dirname "$package_path")"
    package_name="$(basename "$package_path")"
    echo "Stowing $package_name from ${package_dir#$DOTFILES_DIR/}"
    stow -d "$package_dir" -t "$TARGET_DIR" "$package_name"
  done
}

unstow_dotfiles() {
  print_header "Unstowing Linux dotfiles"
  require_command stow

  local stow_packages=(
    "$DOTFILES_DIR/linux/apps"/*
    "$DOTFILES_DIR/linux/assets"/*
    "$DOTFILES_DIR/linux/browser"/*
    "$DOTFILES_DIR/linux/cli"/*
    "$DOTFILES_DIR/linux/dev"/*
    "$DOTFILES_DIR/linux/editor"/*
    "$DOTFILES_DIR/linux/git"
    "$DOTFILES_DIR/linux/security"/*
    "$DOTFILES_DIR/linux/shell"
    "$DOTFILES_DIR/linux/ssh"
    "$DOTFILES_DIR/linux/terminal"/*
    "$DOTFILES_DIR/linux/wallpaper"
    "$DOTFILES_DIR/linux/wm"/*
    "$DOTFILES_DIR/linux/zen"
  )

  for package_path in "${stow_packages[@]}"; do
    [[ -d "$package_path" ]] || continue
    stow -D -d "$(dirname "$package_path")" -t "$TARGET_DIR" "$(basename "$package_path")"
  done
}

patch_terminal_apps() {
  local terminal="${1:-wezterm}"

  case "$terminal" in
    wezterm) "$SCRIPT_DIR/patch_wezterm.sh" ;;
    ghostty) "$SCRIPT_DIR/patch_ghostty.sh" ;;
    *) print_error "Unknown terminal: $terminal"; exit 1 ;;
  esac
}

fix_repo_keys() {
  print_header "Fixing apt repository keys"
  require_root
  mkdir -p /etc/apt/keyrings

  if [[ -f /etc/apt/sources.list.d/wezterm.list ]]; then
    rm -f /etc/apt/sources.list.d/wezterm.list /etc/apt/keyrings/wezterm-fury.gpg
    curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    chmod 644 /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' > /etc/apt/sources.list.d/wezterm.list
    print_ok "WezTerm repository fixed"
  fi

  if [[ -f /etc/apt/sources.list.d/ngrok.list ]]; then
    rm -f /etc/apt/sources.list.d/ngrok.list /etc/apt/trusted.gpg.d/ngrok.asc /etc/apt/keyrings/ngrok.gpg
    curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | gpg --yes --dearmor -o /etc/apt/keyrings/ngrok.gpg
    chmod 644 /etc/apt/keyrings/ngrok.gpg
    echo "deb [signed-by=/etc/apt/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com buster main" > /etc/apt/sources.list.d/ngrok.list
    print_ok "Ngrok repository fixed"
  fi

  rm -f /etc/apt/sources.list.d/sublime-text.list /etc/apt/trusted.gpg.d/sublimehq-archive.gpg /etc/apt/keyrings/sublime-text.gpg
  apt update
}

view_errors() {
  local log_file="${1:-$LOG_FILE}"
  if [[ ! -f "$log_file" ]]; then
    print_error "No log file found at $log_file"
    exit 1
  fi

  print_header "Installation Error Summary"
  local package_errors exceptions total_errors
  package_errors="$(grep -c "PACKAGE_ERROR" "$log_file" 2>/dev/null || true)"
  exceptions="$(grep -c "EXCEPTION" "$log_file" 2>/dev/null || true)"
  total_errors="$(grep -c "\[ERROR\]" "$log_file" 2>/dev/null || true)"

  echo "Total Errors: ${total_errors:-0}"
  echo "Package Errors: ${package_errors:-0}"
  echo "Exceptions: ${exceptions:-0}"

  if [[ "${package_errors:-0}" -gt 0 ]]; then
    print_header "Package Installation Errors"
    grep "PACKAGE_ERROR" "$log_file" | tail -20
  fi

  if [[ "${exceptions:-0}" -gt 0 ]]; then
    print_header "Exceptions"
    grep "EXCEPTION" "$log_file" | tail -10
  fi

  print_header "Recent Errors"
  grep "\[ERROR\]" "$log_file" | tail -10 || true
}

setup_firewall_rules() {
  print_header "Applying firewall rules"
  require_root
  require_command ufw

  for rule in "${FIREWALL_RULES[@]}"; do
    echo "ufw $rule"
    ufw $rule
  done
}

shield_firewall() {
  local mode="${1:-status}"
  require_root
  require_command ufw

  case "$mode" in
    basic)
      ufw default deny incoming
      ufw default allow outgoing
      ufw default deny forward
      ufw limit ssh/tcp comment 'SSH rate limit'
      ufw --force enable
      ufw status verbose
      ;;
    reset)
      ufw --force reset
      ;;
    status)
      ufw status verbose
      ufw status numbered
      ;;
    enable)
      ufw --force enable
      ;;
    disable)
      ufw --force disable
      ;;
    *)
      print_error "Usage: $0 shield [basic|reset|status|enable|disable]"
      exit 1
      ;;
  esac
}

install_bug_bounty_tools() {
  print_header "Installing bug bounty tools"
  require_root
  apt update && apt upgrade -y
  apt install -y git curl wget unzip python3 python3-pip golang-go ruby-full jq nmap nikto sqlmap wfuzz

  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$PATH:$GOPATH/bin"
  local tools_dir="$HOME/bugbounty-tools"
  mkdir -p "$GOPATH" "$tools_dir"

  cd "$tools_dir"
  [[ -d Sublist3r ]] || git clone https://github.com/aboul3la/Sublist3r.git
  go install github.com/tomnomnom/assetfinder@latest
  go install github.com/OWASP/Amass/v3/...@latest
  go install github.com/tomnomnom/httprobe@latest
  go install github.com/lc/gau/v2/cmd/gau@latest
  go install github.com/tomnomnom/waybackurls@latest
  go install github.com/ffuf/ffuf@latest
  [[ -d SecLists ]] || git clone https://github.com/danielmiessler/SecLists.git
}

verify_production() {
  print_header "Production Readiness Verification"
  local errors=0

  cd "$DOTFILES_DIR"

  if [[ -f scripts/linux/linux-install.sh ]]; then
    print_ok "scripts/linux/linux-install.sh exists"
  else
    print_error "scripts/linux/linux-install.sh is missing"
    errors=$((errors + 1))
  fi

  for file in scripts/linux/*.sh; do
    [[ -f "$file" ]] || continue
    if [[ -s "$file" ]]; then
      print_ok "$file is present"
    else
      print_error "$file is empty"
      errors=$((errors + 1))
    fi
  done

  for file in README.md .gitignore scripts/config/apps.yaml scripts/config/settings.yaml scripts/config/vscode_extensions.yaml; do
    if [[ -f "$file" ]]; then
      print_ok "$file exists"
    else
      print_error "$file is missing"
      errors=$((errors + 1))
    fi
  done

  if python3 -c "import yaml" 2>/dev/null; then
    print_ok "PyYAML is installed"
  else
    print_warn "PyYAML not installed"
  fi

  if [[ "$errors" -eq 0 ]]; then
    print_ok "Production checks passed"
  else
    print_error "Production checks failed: $errors"
    exit 1
  fi
}

run_all() {
  install_dependencies
  install_apps
  install_flatpak
  install_custom_apps
  install_vscode_extensions
  setup_gtk_theme
  start_services
  create_containers
  setup_firewall_rules
  stow_dotfiles
}

usage() {
  cat <<'USAGE'
Usage: scripts/linux/linux-install.sh <command> [args]

Commands:
  all                  Run the full Linux bootstrap
  deps                 Install dependency packages
  apps                 Install application packages
  flatpak              Install Flatpak and Flatpak apps
  custom               Install custom apt-backed apps and Docker
  vscode               Install VS Code extensions
  gtk                  Install GTK icon/theme assets
  services             Start and enable common services
  containers           Create Docker containers
  stow                 Stow Linux dotfiles into $STOW_TARGET or $HOME
  unstow               Unstow Linux dotfiles
  patch-terminal NAME  Patch desktop files for wezterm or ghostty
  fix-repo-keys        Repair apt repository keys for WezTerm/Ngrok
  view-errors [LOG]    Show install log error summary
  firewall             Apply the saved firewall rule list
  shield [MODE]        UFW manager: basic, reset, status, enable, disable
  bugbounty            Install bug bounty tools
  verify               Run repository readiness checks
  help                 Show this message
USAGE
}

main() {
  local command="${1:-help}"
  shift || true

  case "$command" in
    help|-h|--help) usage; return ;;
  esac

  case "$command" in
    all|deps|apps|flatpak|custom|vscode|firewall)
      load_config_arrays
      ;;
  esac

  case "$command" in
    all) run_all "$@" ;;
    deps) install_dependencies "$@" ;;
    apps) install_apps "$@" ;;
    flatpak) install_flatpak "$@" ;;
    custom) install_custom_apps "$@" ;;
    vscode) install_vscode_extensions "$@" ;;
    gtk) setup_gtk_theme "$@" ;;
    services) start_services "$@" ;;
    containers) create_containers "$@" ;;
    stow) stow_dotfiles "$@" ;;
    unstow) unstow_dotfiles "$@" ;;
    patch-terminal) patch_terminal_apps "$@" ;;
    fix-repo-keys) fix_repo_keys "$@" ;;
    view-errors) view_errors "$@" ;;
    firewall) setup_firewall_rules "$@" ;;
    shield) shield_firewall "$@" ;;
    bugbounty) install_bug_bounty_tools "$@" ;;
    verify) verify_production "$@" ;;
    *) print_error "Unknown command: $command"; usage; exit 1 ;;
  esac
}

main "$@"
