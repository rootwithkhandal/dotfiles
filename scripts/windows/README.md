# Dotfiles

A collection of configuration files for WezTerm, Neovim, and VS Code on Windows.

## Quick Install

The easiest way to install everything is to run the automated installer:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer.ps1
```

This script will:
1. Install all fonts from the `fonts` folder.
2. Copy the WezTerm configuration.
3. Copy the Neovim configuration (replaces existing `appdata\local\nvim`).
4. Copy the VS Code `settings.json`.

---

## Requirements

Install these tools before applying the configs:

- Windows PowerShell or PowerShell 7 for the copy/install commands
- Git, required by `lazy.nvim` to download Neovim plugins
- Create a `.env` file in the `scripts` folder with `GIT_USER_NAME` and `GIT_USER_EMAIL` for Git configuration (and any other sensitive vars).
- WezTerm, for `wezterm\.wezterm.lua`
- Neovim, for the `nvim\` config
- WSL with a `Kali-linux` distro, because WezTerm starts `wsl -d Kali-linux /bin/bash`
- `JetBrains Mono`, used by the WezTerm config
- `zig`, used as the preferred Treesitter compiler
- Go toolchain, `gopls`, and `gofumpt`, used by the Go LazyVim extras and custom Go LSP settings
- `yamlfmt`, used by the YAML formatter override
- `opencode`, required for the configured `opencode.nvim` workflow

Optional but useful:

- Docker, Helm, Terraform, Node.js, npm, and TypeScript tooling for the enabled LazyVim language extras

## Install fonts

Install all supported fonts from the `fonts` folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-fonts.ps1
```

The script installs `.ttf`, `.otf`, `.ttc`, and `.fon` files recursively for the current Windows user.

Useful options:

```powershell
# Preview what would be installed
powershell -ExecutionPolicy Bypass -File .\install-fonts.ps1 -WhatIf

# Reinstall fonts that already exist
powershell -ExecutionPolicy Bypass -File .\install-fonts.ps1 -Force

# Install fonts from another folder
powershell -ExecutionPolicy Bypass -File .\install-fonts.ps1 -FontsPath "C:\path\to\fonts"
```

## WezTerm

This repo includes a Windows WezTerm config at `wezterm\.wezterm.lua`.

Install it by copying the file to your Windows home directory:

```powershell
Copy-Item .\wezterm\.wezterm.lua $HOME\.wezterm.lua
```

The config currently sets:

- Font: `JetBrains Mono` at `12.0`
- Color scheme: `Catppuccin Mocha`
- Hidden tab bar and no window decorations
- Slightly transparent background
- `Ctrl+q` toggles fullscreen
- `Ctrl+'` clears scrollback and viewport
- `Ctrl+Left Click` opens links under the cursor
- Default shell: Kali Linux through WSL with `wsl -d Kali-linux /bin/bash`

Install the fonts first if WezTerm cannot find `JetBrains Mono`.

## Neovim

This repo includes a LazyVim-based Neovim config in `nvim\`.

Install it by copying the folder to Neovim's Windows config directory:

```powershell
Copy-Item .\nvim $env:LOCALAPPDATA\nvim -Recurse -Force
```

The config currently includes:

- LazyVim bootstrapped through `lazy.nvim`
- LazyVim extras for Docker, Go, Helm, JSON, Markdown, Terraform, TypeScript, YAML, DAP, Harpoon 2, Mini Files, and Mini Surround
- Treesitter compiler preference set to `zig`
- Wrapped lines and manual folding
- Insert-mode `jj` and `jk` escape mappings
- Go LSP tuning for `gopls`, including staticcheck, placeholders, auto-import completion, and `gofumpt`
- YAML formatting through `yamlfmt` with Kubernetes-friendly indentless arrays
- `mini.surround` mappings such as `sa`, `sd`, and `gsr`
- `opencode.nvim` integration under `<leader>o` mappings

Neovim will install plugins on first launch through `lazy.nvim`. Make sure `git` is available in your PATH.

## Visual Studio Code

This repo includes a VS Code configuration in `Vscode\User\settings.json`.

Install it by copying the file to VS Code's Windows user settings directory:

```powershell
Copy-Item .\Vscode\User\settings.json $env:APPDATA\Code\User\settings.json -Force
```

The config currently includes:

- Theme: `React Dev Theme (dark)`
- Font: `Cascadia Code` and `Cascadia Mono` with ligatures enabled
- Sidebar moved to the `right`
- Relative line numbers
- Hidden status bar, breadcrumbs, and minimap for a cleaner UI
- Auto-save enabled (`afterDelay`)
- Word wrap enabled
- Smooth scrolling and mouse wheel zoom enabled
- Integrated terminal tuned for PowerShell (Windows) and zsh (Linux/OSX)
- Language-specific formatting:
  - Python: `black-formatter` with custom rulers
  - HTML: `prettier`
  - JSON: default VS Code features
- File nesting for cleaner explorer view
- Custom UI tweaks via `apc.stylesheet` (if the APC Extension is installed)
