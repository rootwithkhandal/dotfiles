# Dotfiles - Modular Development Environment Setup

A comprehensive, Python-based automation system for setting up development environments across multiple Linux distributions. Automates installation of packages, Flatpak apps, Docker containers, VSCode extensions, terminal configuration, and includes Nix Home Manager configurations.

## 🚀 Features

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
- **Nix Home Manager**: Declarative package management and configuration
- **Profile-based installation**: Install specific components only

## 📦 What Gets Installed

### Core Components
- **60+ Essential dependencies**: Build tools, Python stack, development libraries
- **100+ Applications**: Editors, terminals, languages, system tools, network tools, security tools
- **20+ Flatpak apps**: Spotify, Telegram, Discord, Signal, Postman, OBS Studio, and more
- **150+ VSCode extensions**: Python, Go, Rust, Web dev, AI assistants (Copilot, Continue, Claude), security tools
- **Docker containers**: Portainer for container management
- **Custom installers**: Zed, WezTerm, Brave, Sublime Text, Ngrok
- **System services**: Docker, Bluetooth, Ngrok
- **Firewall configuration**: UFW with SSH and custom ports
- **Terminal patching**: WezTerm or Ghostty as default terminal wrapper

### Nix Home Manager Profiles
- **Development**: Full development environment with editors, languages, and tools
- **Bug Bounty**: Security testing tools and utilities
- **SOC**: Security Operations Center tools
- **Unified**: Complete setup with all components

## 🛠️ Quick Start

### Traditional Python Installation

```bash
# Clone repository
git clone https://github.com/rootwithkhandal/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Python dependencies
pip3 install -r requirements.txt

# Run full installation (requires sudo)
sudo python3 linux-setup/install.py

# Or preview what would be installed
sudo python3 linux-setup/install.py --dry-run --verbose
```

### Nix Home Manager Installation

```bash
# Install Nix (if not already installed)
curl -L https://nixos.org/nix/install | sh

# Install Home Manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# Use the configurations
cd ~/.dotfiles/nix-home-manager/home-manager

# Switch to a specific profile
./scripts/switch-profile.sh development
./scripts/switch-profile.sh bug-bounty
./scripts/switch-profile.sh soc
./scripts/switch-profile.sh unified
```

## 📋 Usage

### Profile-Based Installation

Install specific components only:

```bash
# List all available profiles
python3 linux-setup/install.py --list-profiles

# Install only dependencies
sudo python3 linux-setup/install.py --profile dependencies

# Install specific application categories
sudo python3 linux-setup/install.py --profile editors
sudo python3 linux-setup/install.py --profile languages
sudo python3 linux-setup/install.py --profile security-tools

# Install custom applications
sudo python3 linux-setup/install.py --profile custom-zed
sudo python3 linux-setup/install.py --profile custom-brave
sudo python3 linux-setup/install.py --profile custom-wezterm

# Combine multiple profiles
sudo python3 linux-setup/install.py --profile editors --profile languages --profile custom-zed

# Special profiles
sudo python3 linux-setup/install.py --profile minimal      # Dependencies + essential tools
sudo python3 linux-setup/install.py --profile developer    # Full dev environment
sudo python3 linux-setup/install.py --profile security     # Security/pentesting tools
```

### Legacy Options (Backward Compatible)

```bash
# Skip specific components
sudo python3 linux-setup/install.py --skip-flatpak --skip-docker --skip-vscode

# Use Ghostty instead of WezTerm
sudo python3 linux-setup/install.py --terminal ghostty

# Verbose output
sudo python3 linux-setup/install.py --verbose
```

### Standalone Terminal Patching

```bash
# Patch for WezTerm
./linux-setup/scripts/patch_wezterm.sh

# Patch for Ghostty
./linux-setup/scripts/patch_ghostty.sh
```

### View Installation Errors

```bash
# Quick error summary
./linux-setup/scripts/view_errors.sh

# View full log
cat docs/install.log

# Search for specific package
grep "appmenu-qt5" docs/install.log
```

## 📁 Project Structure

```
dotfiles/
├── README.md                     # This file
├── .gitignore                    # Git ignore patterns
│
├── linux-setup/                 # Python-based installer
│   ├── install.py               # Main entry point with CLI
│   ├── config/                  # YAML configuration files
│   │   ├── apps.yaml           # Package lists (dependencies, apps, flatpak)
│   │   ├── distros.yaml        # Multi-distro package manager configs
│   │   ├── settings.yaml       # Services, firewall, docker containers
│   │   └── vscode_extensions.yaml # VSCode extensions by category
│   ├── modules/                 # Python modules (core functionality)
│   ├── utils/                   # Utility functions
│   └── scripts/                 # Standalone bash scripts
│
├── nix-home-manager/            # Nix Home Manager configurations
│   └── home-manager/
│       ├── flake.nix           # Nix flake configuration
│       ├── home.nix            # Main home configuration
│       ├── modules/            # Modular configurations
│       │   ├── browsers/       # Browser configurations
│       │   ├── editors/        # Editor configurations
│       │   ├── security-tools/ # Security tool configurations
│       │   ├── shell/          # Shell configurations
│       │   ├── terminal/       # Terminal configurations
│       │   └── utilities/      # Utility configurations
│       ├── profiles/           # Pre-defined profiles
│       │   ├── development.nix # Development profile
│       │   ├── bug-bounty.nix  # Bug bounty profile
│       │   ├── soc.nix         # SOC profile
│       │   └── unified.nix     # Complete profile
│       └── scripts/            # Helper scripts
│
├── nix/                         # Simple Nix configuration
│   ├── flake.nix               # Basic flake
│   └── home.nix                # Basic home configuration
│
├── docs/                        # Documentation
│   ├── INSTALLATION_GUIDE.md   # Detailed installation guide
│   ├── TROUBLESHOOTING.md      # Common issues and solutions
│   ├── CHANGELOG.md            # Version history
│   └── PACKAGE_NOTES.md        # Package-specific notes
│
└── backup/                      # Legacy bash scripts (archived)
    ├── src/                    # Original modular bash scripts
    ├── *.sh                    # Original installer scripts
    └── README_OLD.md           # Original documentation
```

## ⚙️ Configuration

All configuration is done through YAML files - no code changes needed!

### Adding Applications

Edit `linux-setup/config/apps.yaml`:

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

Edit `linux-setup/config/apps.yaml`:

```yaml
flatpak_apps:
  - com.spotify.Client
  - org.telegram.desktop
  - com.yourapp.App
```

### Adding VSCode Extensions

Edit `linux-setup/config/vscode_extensions.yaml`:

```yaml
vscode_extensions:
  - ms-python.python
  - github.copilot
  - your.extension
```

### Nix Home Manager Configuration

Edit `nix-home-manager/home-manager/modules/` files to customize Nix configurations:

```nix
# Example: Adding a new package to development profile
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Add your packages here
    git
    curl
    wget
  ];
}
```

## 🔧 Extending the System

### Adding a New Python Module

1. Create `linux-setup/modules/mymodule.py`:

```python
from utils.runner import CommandRunner

class MyModule:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
    
    def setup(self):
        self.logger.info("Setting up...")
        # Your logic here
        self.runner.run("your-command", shell=True)
```

2. Import in `linux-setup/install.py`:

```python
from modules.mymodule import MyModule

# In main():
my_module = MyModule(logger, dry_run=args.dry_run)
my_module.setup()
```

### Adding Distribution Support

Edit `linux-setup/config/distros.yaml`:

```yaml
mynewdistro:
  package_manager: apt
  install_cmd: "apt install -y"
  update_cmd: "apt update"
  upgrade_cmd: "apt upgrade -y"
```

### Adding Nix Home Manager Modules

1. Create a new module in `nix-home-manager/home-manager/modules/`:

```nix
{ config, pkgs, ... }:

{
  # Your configuration here
  programs.myprogram = {
    enable = true;
    # Additional configuration
  };
}
```

2. Import in the appropriate profile or `home.nix`.

## 🐛 Troubleshooting

### Check Installation Logs

All errors are logged to `docs/install.log`:
```bash
# View recent errors
tail -50 docs/install.log

# Search for specific package errors
grep "PACKAGE_ERROR" docs/install.log

# View all errors
grep "ERROR" docs/install.log

# Quick error summary
./linux-setup/scripts/view_errors.sh
```

### Common Issues

#### Package Not Found
Some packages may have different names on different distros. Edit `linux-setup/config/apps.yaml` to remove or rename problematic packages.

#### VSCode Extensions Not Installing
1. Open VSCode
2. Press `Ctrl+Shift+P`
3. Run: "Shell Command: Install 'code' command in PATH"
4. Re-run: `sudo python3 linux-setup/install.py`

#### Repository GPG Key Errors
```bash
# Fix all repository keys automatically
sudo ./linux-setup/scripts/fix_repo_keys.sh
```

#### Nix Home Manager Issues
```bash
# Rebuild home manager configuration
home-manager switch

# Check for configuration errors
nix-instantiate --eval --expr 'import <home-manager/modules> {}'
```

### Permission Errors

Always run with sudo for system-level changes:
```bash
sudo python3 linux-setup/install.py
```

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION_GUIDE.md) - Detailed installation instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Package Notes](docs/PACKAGE_NOTES.md) - Package-specific information
- [Changelog](docs/CHANGELOG.md) - Version history and updates

## 🔄 Migration from Old Scripts

The old bash scripts are preserved in `backup/` for reference. The new Python system provides:

- **Better error handling**: Continues on failures, reports issues clearly
- **Modular design**: Easy to extend and maintain
- **Easier configuration**: YAML instead of bash arrays
- **Cross-platform support**: Works on Debian, Ubuntu, Arch, Fedora
- **Dry-run capability**: Preview changes before applying
- **Progress tracking**: See what's happening in real-time
- **Selective installation**: Skip components you don't need

## 📋 Requirements

### Python Installation
- **Python**: 3.6 or higher
- **PyYAML**: Installed via `pip3 install -r requirements.txt`
- **sudo privileges**: Required for system-level changes
- **Internet connection**: For downloading packages and extensions

### Nix Installation
- **Nix**: Package manager (installed automatically if not present)
- **Home Manager**: Nix-based user environment management
- **Internet connection**: For downloading packages

## 🤝 Contributing

This is a personal dotfiles repository, but feel free to fork and adapt for your own use. Suggestions and improvements are welcome!

## 📄 License

Personal use - adapt as needed for your environment.

---

## 🎯 Quick Commands Reference

```bash
# Full installation
sudo python3 linux-setup/install.py

# Dry run
sudo python3 linux-setup/install.py --dry-run --verbose

# Profile installation
sudo python3 linux-setup/install.py --profile developer

# Nix Home Manager
cd nix-home-manager/home-manager && ./scripts/switch-profile.sh development

# View errors
./linux-setup/scripts/view_errors.sh

# Fix repository keys
sudo ./linux-setup/scripts/fix_repo_keys.sh
```