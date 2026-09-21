#!/bin/bash
# ================================================
# Bug Bounty Tools Installer for Bash & Zsh
# ================================================

set -e

echo "[*] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[*] Installing dependencies..."
sudo apt install -y git curl wget unzip python3 python3-pip golang-go ruby-full jq nmap

# Setup GOPATH
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
mkdir -p $GOPATH

# Tools directory
TOOLS_DIR=$HOME/bugbounty-tools
mkdir -p $TOOLS_DIR
cd $TOOLS_DIR

# -----------------------------------------------
# Recon Tools
# -----------------------------------------------
echo "[*] Installing Sublist3r..."
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
#pip3 install -r requirements.txt
cd ..

echo "[*] Installing assetfinder..."
go install github.com/tomnomnom/assetfinder@latest

echo "[*] Installing amass..."
go install github.com/OWASP/Amass/v3/...@latest

echo "[*] Installing httprobe..."
go install github.com/tomnomnom/httprobe@latest

echo "[*] Installing gau..."
go install github.com/lc/gau/v2/cmd/gau@latest

echo "[*] Installing waybackurls..."
go install github.com/tomnomnom/waybackurls@latest

# -----------------------------------------------
# Scanning Tools
# -----------------------------------------------
echo "[*] Installing nmap..."
sudo apt install -y nmap

echo "[*] Installing nikto..."
sudo apt install -y nikto

echo "[*] Installing sqlmap..."
sudo apt install -y sqlmap

# -----------------------------------------------
# Fuzzing & Wordlists
# -----------------------------------------------
echo "[*] Installing wfuzz..."
sudo apt install -y wfuzz

echo "[*] Installing ffuf..."
go install github.com/ffuf/ffuf@latest

echo "[*] Downloading SecLists..."
git clone https://github.com/danielmiessler/SecLists.git

# -----------------------------------------------
# Linking to bash and zsh
# -----------------------------------------------
# echo "[*] Linking PATH for bash and zsh..."
# BASHRC="$HOME/.bashrc"
# ZSHRC="$HOME/.zshrc"

# echo 'export GOPATH=$HOME/go' >> $BASHRC
# echo 'export PATH=$PATH:$GOPATH/bin:$HOME/bugbounty-tools' >> $BASHRC

# echo 'export GOPATH=$HOME/go' >> $ZSHRC
# echo 'export PATH=$PATH:$GOPATH/bin:$HOME/bugbounty-tools' >> $ZSHRC

# echo "[*] Reloading shells..."
# source $BASHRC
# source $ZSHRC

echo "[*] Installation completed!"
echo "[*] Check your tools: sublist3r, assetfinder, amass, httprobe, gau, waybackurls, ffuf, wfuzz, nmap, nikto, sqlmap"

