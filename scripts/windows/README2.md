# 🪟 Windows Dotfiles

Personal configuration files and setup automation for a Windows development environment.

## Overview

This repository contains configuration files, custom fonts, registry tweaks, and automation scripts to bootstrap and maintain a consistent dev environment across Windows machines.

## Repository Structure

```
dotfiles/windows/
├── browsers/             # Browser configuration placeholders
│   ├── arc/
│   ├── brave/
│   ├── chrome/
│   ├── firefox/
│   └── zen/
├── editors/              # Editor settings & configuration
│   ├── antigravity/      # Antigravity IDE settings.json
│   ├── cursor/           # Cursor IDE settings.json
│   ├── kiro/             # Kiro IDE settings.json
│   ├── nvim/             # Neovim configuration
│   ├── sublime/
│   ├── vscode/           # VS Code settings.json & recommended-ext.json
│   └── zed/              # Zed editor settings.json
├── fonts/                # Custom fonts + installer
│   ├── fonts/            # Font files (.ttf, .otf, .ttc)
│   └── install-fonts.ps1
├── obsidian/             # Obsidian vault settings (planned)
├── registries/           # Windows Registry tweaks
│   ├── add/              # .reg files to enable features
│   ├── remove/           # .reg files to revert changes
│   └── backup/           # Exported registry backups
├── scripts/              # Automation scripts
│   ├── installer.ps1     # Full dev environment installer
│   └── stow.ps1          # Config deployer (symlink/copy)
├── shell/
│   └── powershell/
│       └── WindowsPowerShell/
│           ├── Microsoft.PowerShell_profile.ps1
│           ├── posh-config.json       # Oh My Posh theme
│           ├── starship.toml          # Starship prompt config
│           ├── custom-modules/
│           ├── custom-scripts/
│           └── custom-themes/         # Oh My Posh theme files
├── ssh/                  # SSH configuration (planned)
├── terminals/            # Terminal emulator configs
│   ├── warp-terminal/
│   ├── wezterm/          # WezTerm config (.wezterm.lua)
│   └── windows-terminal/ # Windows Terminal settings.json
├── windows-cursors/      # Custom cursor schemes (planned)
└── wsl/                  # WSL distro configs
    ├── arch/
    ├── debian/
    ├── kali-linux/
    ├── parrot/
    └── ubuntu/
```

## Quick Start

### 1. Install the dev environment

Run in an **elevated (Admin) PowerShell** session:

```powershell
.\scripts\installer.ps1
```

This will install:

| Category | Tools |
|---|---|
| **Package Managers** | Chocolatey (auto), Scoop (manual) |
| **Dev Tools** | VS Code, Windows Terminal, Git, GitHub CLI, Python 3.12, Node.js LTS, Go, Rust, Docker Desktop, JetBrains Toolbox |
| **Node.js Globals** | pnpm, yarn |
| **Network / Recon** | Nmap, Wireshark, Masscan, Netcat |
| **Security** | Burp Suite Community, Maltego, Metasploit, OpenVPN |
| **WSL** | Updates WSL to the latest version |

Optional flags:

```powershell
.\scripts\installer.ps1 -GitName "Your Name" -GitEmail "you@example.com"
.\scripts\installer.ps1 -SkipGitConfig      # skip git global config
.\scripts\installer.ps1 -SkipWSL            # skip WSL update
.\scripts\installer.ps1 -SkipSecurityTools  # skip network/security tools
```

### 2. Deploy configuration files

```powershell
.\scripts\stow.ps1
```

This copies your config files to their expected locations:

| Config | Source | Destination |
|---|---|---|
| WezTerm | `terminals/wezterm/.wezterm.lua` | `~/.wezterm.lua` |
| Neovim | `editors/nvim/` | `$LOCALAPPDATA/nvim/` |
| VS Code | `editors/vscode/settings.json` | `$APPDATA/Code/User/settings.json` |
| Fonts | `fonts/fonts/` | Per-user font directory |

Optional flags:

```powershell
.\scripts\stow.ps1 -Force      # overwrite even if already deployed
.\scripts\stow.ps1 -SkipFonts  # skip font installation
.\scripts\stow.ps1 -WhatIf     # preview without making changes
```

### 3. Install fonts only

```powershell
.\fonts\install-fonts.ps1
```

Installs all fonts from `fonts/fonts/` to the per-user font directory (`$LOCALAPPDATA\Microsoft\Windows\Fonts`) with proper registry entries. No admin privileges required.

## Key Configurations

### Shell — PowerShell

The PowerShell profile (`shell/powershell/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`) includes:

- **Oh My Posh** prompt theming with a custom config
- **Starship** prompt config as an alternative
- **Terminal-Icons** for file icons in directory listings
- Automatic `$EDITOR` detection (nvim → vim → code → notepad++ → notepad)
- Admin detection in the window title
- Chocolatey tab-completion

### Terminal — WezTerm

The WezTerm config (`terminals/wezterm/.wezterm.lua`) features:

- **JetBrains Mono** font at 12pt
- **Catppuccin Mocha** color scheme
- Acrylic background with 95% opacity
- Custom key bindings and tab bar styling

### Editors & IDEs

The `editors/` directory includes tailored `settings.json` profiles for all modern code editors, unified around **relative line numbers**, **smooth animations**, and **Windows PowerShell** terminal integration:

- **VS Code** (`editors/vscode/`): Configured with `React Dev Theme (dark)`, `Material Icon Theme`, smooth caret animations, plus a curated `recommended-ext.json` extension pack (GitLens, Copilot, Remote SSH, Prettier, Python/Jupyter, and security/network utilities).
- **Antigravity IDE** (`editors/antigravity/`): Uses `One Dark Pro Night Flat` with `JetBrainsMono Nerd Font` and clean workspace hygiene rules (`files.trimTrailingWhitespace`, `insertFinalNewline`).
- **Cursor IDE** (`editors/cursor/`): Uses `SF Mono`/`JetBrains Mono` fonts with `One Dark Pro Night Flat` and optimized formatting preferences.
- **Kiro IDE** (`editors/kiro/`): Uses the `Hack The Box` theme with custom padding and status bar tweaks.
- **Zed** (`editors/zed/`): Native performance-tuned config featuring `Material Icon Theme`, `SF Pro Display` UI font, `JetBrainsMonoNL Nerd Font` buffer font, native `edit_predictions`, customized `Aura Dark` syntax overrides, and auto-install extensions for common languages.

### Registry Tweaks

Registry files in `registries/` are organized into `add/` and `remove/` pairs:

- Control Panel in File Explorer nav pane
- "Copy Contents to Clipboard" context menu entry
- Gallery / Home visibility in Explorer
- Recycle Bin and User Folder in the nav pane
- Folder groups in This PC
- Drive letter visibility

> **Tip:** Import one file at a time from an elevated PowerShell: `reg import <file.reg>`

## Included Fonts

The `fonts/` directory contains a curated collection of fonts including:

- **Coding:** JetBrains Mono, Fira Code, Cascadia Code/Mono, Geist Mono, Commit Mono, Cartograph CF, Fragment Mono, 0xProto — all with Nerd Font variants
- **Sans-serif:** Inter, Roboto, Montserrat, Poppins, DM Sans, Plus Jakarta Sans, Product Sans, Gotham, Neue Haas Display, IBM Plex Sans
- **Serif:** Merriweather, Alegreya, Neuton, New York, Rockwell Nova, Anthropic Sans/Serif, DM Serif Display
- **Display:** Clash Display, Anurati, Azonix, Orbitron, Aquatico, Arcade Classic

## WSL Distros

Placeholder directories exist for WSL distribution configs:

- Arch Linux
- Debian
- Kali Linux
- Parrot OS
- Ubuntu

## License

Personal configuration files. Use at your own risk.
