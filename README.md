# Dotfiles Installer

A script-based automation system for setting up development environments across Linux and Windows. Linux package lists and app settings live in `scripts/config`, while platform entrypoints live in `scripts/linux` and `scripts/windows`.

## Features

- **Multi-distro support**: Debian, Ubuntu, Arch, Fedora with automatic detection
- **Modular architecture**: Easy to extend and customize
- **YAML configuration**: Simple, readable config files - no code changes needed
- **Comprehensive coverage**: System packages, Flatpak apps, Docker, VSCode extensions, terminal patching
- **Dry-run mode**: Preview changes before applying
- **Colored logging**: Clear, timestamped output with progress tracking
- **Selective installation**: Skip any component with CLI flags
- **Terminal patching**: Automatically configure WezTerm or Ghostty as default terminal
- **Security tools**: Pre-configured with pentesting and security tools
- **Development ready**: Full stack support (Python, Go, Rust, Node.js, PHP, Java, etc.)

## Quick Start

```bash
# Clone repository
git clone https://github.com/rootwithkhandal/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run full installation (requires sudo)
sudo ./scripts/linux/linux-install.sh all

# Or run a focused step
sudo ./scripts/linux/linux-install.sh deps
```

## What Gets Installed

- **60+ Essential dependencies**: Build tools, Python stack, development libraries
- **100+ Applications**: Editors, terminals, languages, system tools, network tools, security tools
- **20+ Flatpak apps**: Spotify, Telegram, Discord, Signal, Postman, OBS Studio, and more
- **150+ VSCode extensions**: Python, Go, Rust, Web dev, AI assistants (Copilot, Continue, Claude), security tools
- **Docker containers**: Portainer for container management
- **Custom installers**: Zed, WezTerm, Brave, Sublime Text, Ngrok
- **System services**: Docker, Bluetooth, Ngrok
- **Firewall configuration**: UFW with SSH and custom ports
- **Terminal patching**: WezTerm or Ghostty as default terminal wrapper

## Usage

### Full Installation
```bash
# Install everything
sudo ./scripts/linux/linux-install.sh all
```

### Component-Based Installation

Install specific components only:

```bash
# Install only dependencies
sudo ./scripts/linux/linux-install.sh deps

# Install configured application packages
sudo ./scripts/linux/linux-install.sh apps

# Install custom applications
sudo ./scripts/linux/linux-install.sh custom

# Install VS Code extensions
./scripts/linux/linux-install.sh vscode
```

### Other Linux Commands

```bash
sudo ./scripts/linux/linux-install.sh flatpak
sudo ./scripts/linux/linux-install.sh services
sudo ./scripts/linux/linux-install.sh containers
sudo ./scripts/linux/linux-install.sh firewall
./scripts/linux/linux-install.sh stow
```

### Standalone Terminal Patching

```bash
# Patch for WezTerm
./scripts/linux/patch_wezterm.sh

# Patch for Ghostty
./scripts/linux/patch_ghostty.sh
```

### View Installation Errors

```bash
# Quick error summary
./scripts/linux/linux-install.sh view-errors

# View full log
cat install.log

# Search for specific package
grep "appmenu-qt5" install.log
```

## Project Structure

```
dotfiles/
├── README.md                     # This file
│
├── scripts/
│   ├── config/                  # YAML configuration files
│   │   ├── apps.yaml           # Package lists (dependencies, apps, flatpak)
│   │   ├── distros.yaml        # Multi-distro package manager configs
│   │   ├── settings.yaml       # Services, firewall, docker containers
│   │   └── vscode_extensions.yaml
│   └── linux/
│       ├── linux-install.sh    # Linux packages, logs, security, and stow
│       ├── patch_wezterm.sh    # Patch terminal apps for WezTerm
│       └── patch_ghostty.sh    # Patch terminal apps for Ghostty
│
└── backup/                       # Old bash scripts (archived)
    ├── src/                     # Original modular bash scripts
    ├── *.sh                     # Original installer scripts
    └── README_OLD.md            # Original documentation
```

## Configuration

All configuration is done through YAML files - no code changes needed!

### Adding Applications

Edit `scripts/config/apps.yaml`:

```yaml
applications:
  editors:
    - neovim
    - vim
  
  languages:
    - python3
    - nodejs
  
  security_tools:
    - nmap
    - wireshark
```

### Adding Flatpak Apps

Edit `scripts/config/apps.yaml`:

```yaml
flatpak_apps:
  - com.spotify.Client
  - org.telegram.desktop
  - com.yourapp.App
```

### Adding VSCode Extensions

Edit `scripts/config/vscode_extensions.yaml`:

```yaml
vscode_extensions:
  - ms-python.python
  - github.copilot
  - your.extension
```

### Custom Installers

Add to `scripts/config/apps.yaml`:

```yaml
custom_installers:
  myapp:
    enabled: true
    url: "https://example.com/install.sh"
  
  myrepo:
    enabled: true
    type: "apt_repo"
    key_url: "https://example.com/key.gpg"
    repo: "deb https://example.com/repo stable main"
    package: "mypackage"
```

### Firewall Rules

Edit `scripts/config/settings.yaml`:

```yaml
firewall:
  rules:
    - "allow 8080/tcp"
    - "allow 443/tcp"
    - "enable"
```

### Docker Containers

Edit `scripts/config/settings.yaml`:

```yaml
docker:
  containers:
    mycontainer:
      image: "nginx:latest"
      ports:
        - "80:80"
      volumes:
        - "/data:/data"
      restart: always
```

## Extending the System

### Adding a New Command

Add a shell function to `scripts/linux/linux-install.sh`, then route it in the `case "$command"` block near the bottom of the file.

### Adding Distribution Support

Edit `scripts/config/distros.yaml`:

```yaml
mynewdistro:
  package_manager: apt
  install_cmd: "apt install -y"
  update_cmd: "apt update"
  upgrade_cmd: "apt upgrade -y"
```

The system will auto-detect the distro from `/etc/os-release`.

## CLI Command Reference

Run `./scripts/linux/linux-install.sh help` for the current command list.

## Troubleshooting

### Check Installation Logs

All errors are logged to `install.log`:
```bash
# View recent errors
tail -50 install.log

# Search for specific package errors
grep "PACKAGE_ERROR" install.log

# View all errors
grep "ERROR" install.log

# Quick error summary
./scripts/linux/linux-install.sh view-errors
```

### Common Package Issues

Some packages are not available on all distributions. See [PACKAGE_NOTES.md](PACKAGE_NOTES.md) for details.

**Removed packages and alternatives:**
- `neofetch` → Use `screenfetch` (included) or install `fastfetch`
- `gotop` → Use `btop` (included)
- `colorls` → Ruby gem: `gem install colorls`
- `xrandr` → Included in `x11-xserver-utils`
- `nmtui` → Included in `network-manager`

### VSCode Extensions Not Installing

If you see "code command not found":
1. Open VSCode
2. Press `Ctrl+Shift+P`
3. Run: "Shell Command: Install 'code' command in PATH"
4. Re-run: `./scripts/linux/linux-install.sh vscode`

### Repository GPG Key Errors

If you see errors like "Sub-process /usr/bin/sqv returned an error code" or "Missing key":

```bash
# Fix all repository keys automatically
sudo ./scripts/linux/linux-install.sh fix-repo-keys

# Or fix manually
sudo apt update
```

Common repository issues:
- WezTerm: `/etc/apt/keyrings/wezterm.gpg` missing or wrong permissions
- Ngrok: Missing GPG key
- Sublime Text: Missing GPG key

The fix script will:
1. Remove old repository configurations
2. Re-download GPG keys with correct permissions
3. Re-add repositories with proper signed-by directives
4. Update package lists

### Sublime Text Repository (Removed)

Sublime Text has been disabled by default. If you want to install it:

```bash
# Enable in config
# Edit scripts/config/apps.yaml and set sublime: enabled: true

# Or install manually
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/sublime-text.gpg
sudo chmod 644 /etc/apt/keyrings/sublime-text.gpg
echo "deb [signed-by=/etc/apt/keyrings/sublime-text.gpg] https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update
sudo apt install sublime-text
```

### Permission Errors

Run installer commands that modify the system with sudo:
```bash
sudo ./scripts/linux/linux-install.sh all
```

### Package Not Found

Some packages may have different names on different distros. Common errors like "Package has no installation candidate" are logged to `install.log`. Edit `scripts/config/apps.yaml` to remove or rename problematic packages.

### Terminal Patching Not Working

Run standalone scripts:
```bash
./scripts/linux/patch_wezterm.sh
# or
./scripts/linux/patch_ghostty.sh
```

## Migration from Old Scripts

The old bash scripts are preserved in `backup/` for reference. The new Python system provides:

- **Better error handling**: Continues on failures, reports issues clearly
- **Modular design**: Easy to extend and maintain
- **Easier configuration**: YAML instead of bash arrays
- **Cross-platform support**: Linux and Windows entrypoints are separated
- **Selective installation**: Run only the Linux component command you need

## Requirements

- **Python + PyYAML**: Optional, used by the Linux script to read YAML config files
- **sudo privileges**: Required for system-level changes
- **Internet connection**: For downloading packages and extensions

## Contributing

This is a personal dotfiles repository, but feel free to fork and adapt for your own use. Suggestions and improvements are welcome!

## License

Personal use - adapt as needed for your environment.
