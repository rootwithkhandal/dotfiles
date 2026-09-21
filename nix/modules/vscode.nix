{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        bbenoist.nix
        rust-lang.rust-analyzer
        ms-python.python

        zhuangtongfa.material-theme
        pkief.material-product-icons
        pkief.material-icon-theme

        eamodio.gitlens
        github.copilot
        github.copilot-chat
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-vscode.remote-explorer

        gruntfuggly.todo-tree
        aaron-bond.better-comments
        usernamehw.errorlens
        wmaurer.change-case
        ms-python.python
        ms-python.black-formatter
        ms-python.debugpy
        ms-toolsai.jupyter
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint

        pranaygp.vscode-css-peek
        formulahendry.auto-close-tag
        formulahendry.auto-rename-tag
        zhuangtongfa.material-theme

        nomicfoundation.hardhat-solidity
        
        ms-azuretools.vscode-docker

        vscode-icons-team.vscode-icons
        ms-vscode.powershell

        ms-kubernetes-tools.vscode-kubernetes-tools

        redhat.vscode-yaml
        foxundermoon.shell-format
        golang.go
        bmewburn.vscode-intelephense-client
        rebornix.ruby
        timonwong.shellcheck
        mads-hartmann.bash-ide-vscode

        ms-azuretools.vscode-docker
        hashicorp.terraform
        redhat.vscode-yaml
        oderwat.indent-rainbow
        pkief.material-icon-theme
        naumovs.color-highlight
        spywhere.guides
        enkia.tokyo-night
        catppuccin.catppuccin-vsc
        ms-vscode.cpptools-extension-pack
        ms-python.vscode-pylance
      ];
    };
  };

  xdg.configFile."Code/User/settings.json" = {
    source = ../dotfiles/vscode/settings.json;
    force = true;
  };
}
