sudo pacman -Syu
# Pacman Packages
sudo pacman -S stow 
sudo pacman -S thermald qt5-webengine qt5-base qt5-webkit
sudo pacman -S base-devel git curl wget fuse2 dunst arp-scan
sudo pacman -S python python-pip python-virtualenv 
sudo pacman -S python-setuptools python-dnspython python-gobject
sudo pacman -S imagemagick ffmpeg pipx binutils gcc
sudo pacman -S util-linux cmatrix autojump sysstat ifstat
sudo pacman -S net-tools iftop python-requests pkgconf tzdata
sudo pacman -S libcurl-compat libedit icu ncurses sqlite libxml2 
sudo pacman -S speedtest-cli sd task ruby ruby-bundler
sudo pacman -S xorg-xrandr xdotool xclip xsel devilspie2 
sudo pacman -S libdbusmenu-gtk3 libdbusmenu-qt5 poppler aws-cli
sudo pacman -S neovim nano tmux go rust nodejs npm
sudo pacman -S htop btop screenfetch ranger fzf fd ripgrep eza 
sudo pacman -S zoxide direnv ttf-font-awesome
sudo pacman -S thefuck jq asciinema p7zip
sudo pacman -S gnome-system-monitor gnome-terminal 
sudo pacman -S nmap wireshark-cli tcpdump openvpn tor 
sudo pacman -S proxychains-ng traceroute gobuster dirb
sudo pacman -S netdiscover network-manager-applet lynx
sudo pacman -S hydra john hashcat aircrack-ng sqlmap nikto 
sudo pacman -S wfuzz metasploit seclists smbclient
sudo pacman -S gimp audacity vlc chromium ufw polybar
sudo pacman -S telegram-desktop discord obs-studio xournalpp 
sudo pacman -S gnome-logs gnome-font-viewer
sudo pacman -S git curl wget unzip python python-pip go ruby jq 
sudo pacman -S nmap nikto sqlmap wfuzz ufw atuin
sudo pacman -S kdeconnect cursor-bin chromium wireshark-qt

# ---
sudo pacman -Syu

# yay install
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si


# Yay packages
yay -S python-face-recognition-models
yay -S git-delta rustup feroxbuster burpsuite zaproxy # bloodhound 
yay -S crackmapexec smbmap enum4linux-ng 
yay -S cisco-auditing-tool apktool apkinfo 
yay -S macchanger thefuck 
yay -S zed wezterm-bin brave-bin ngrok spotify
yay -S zaproxy podman-desktop postman-bin zen-browser-bin 
yay -S todoist-appimage obsidian angryip-scanner toolblex
yay -S battery-stats-git --editmenu
yay -S crackmapexec # bloodhound 
yay -S seclists zaproxy impacket 
yay -S responder frida-tools apktool aws-cli
yay -S google-chromme kiro kiro-ide openvpn signal-desktop 
yay -S visual-studio-code-bin warp-terminal-bin wezterm 
yay -S tailscale antigravity bat powershell-bin 
yay -S vmware-workstation16 calamares plasma-framework5
yay -S airpwn --rebuild
yay -S openssl-1.0
yay -S localsend-bin

# ---
sudo pacman -Syu
# Blackarch apps
sudo pacman -S --needed blackarch-officials
# sudo pacman -S blackarch-recon
# sudo pacman -S blackarch-webapp
# sudo pacman -S autorecon
# sudo pacman -S blackarch-config-fluxbox blackarch-config-i3
sudo pacman -Sgg | grep blackarch | cut -d' ' -f2 | sort -u >> blackarch-apps.txt
# sudo pacman -S --needed $(cat blackarch-apps.txt)
# sudo pacman -Rdd impacket && sudo pacman -S impacket-ba
yay -S u3-tool samdump2 pyqt3 python2-esmre w3af xprobe2 grig morxkeyfmt python2-esmre python2-pynids

# yay -S $(cat blackarch-apps.txt) --ignore blackarch-config-calamares,malboxes,vmcloak,padoracle,brosec,shuji,wssip,loot,memfetch,qt3,qscintilla-qt3,pyqt3,rlogin-scanner,python2-pynids,replayproxy,snow,forkingportscanner,junkie,sqlpat,smtpmap,timegen,ssl-phuck3r,cisco7crack,mana,poison,sps,httpsniff,udptunnel,dnsbf,upnpscan,ncpds,mdcrack,bittwist,dhcdrop,smartphone-pentest-framework,mysql2sqlite,enumiax,blindelphant,smbbf,wol-e,maskprocessor,crackhor,python2-esmre,xprobe2,trixd00r,uatester,fprotlogpraser,videosnarf,sidguesser,rtlizer,webslayer,sb0x,ubitack,winexe,packet-0-matic,thc-smartbrute,sasm,missidentify,peach,secscan,sctpscan,fakenetbios,xssscan,hbad,redesktop-brute,uw-loveimap,voiphopper,statsprocessor,morxkeyfmt,uw-zone,grig,speedpwn,samdump2,swfintruder,bluelog,mboxgrep,synscan,lanmap2,protos-sip,truetrack,safecopy,thc-ppt-bruter,ssh-privkey-crack,dirb,arpalert,balbuzard,uw-udpscan,scrounge-ntfs,haka,stompy,tcpjunk,u3-tool,ftpmap,pemcracker,littelblackbox,dnsgoblin,dns2tcp,hasere.wlan2eth,rrs,rsmangler,beleth,ctunnel,radiography,flunym0us,neglected,wepbuster,idswakeup,urldigger,teardown,sherlocked,airpwn,msvpwn,levye,airpoison,osinterator,zulu,xspy,beholder,iisbruteforcer,dnsdrdos,clamscanlogpraser,owasp-bywaf,dirbuster-ng,uw-offish,nfex,sslnuke,thc-keyfinder,rtp-flood,ratproxy,nsoq,kraken,mausezahn

# sudo pacman -S $(cat blackarch-apps.txt) --ignore blackarch-config-calamares,malboxes,vmcloak,padoracle,brosec,shuji,wssip,loot,memfetch,qt3,qscintilla-qt3,pyqt3,rlogin-scanner,python2-pynids,replayproxy,snow,forkingportscanner,junkie,sqlpat,smtpmap,timegen,ssl-phuck3r,cisco7crack,mana,poison,sps,httpsniff,udptunnel,dnsbf,upnpscan,ncpds,mdcrack,bittwist,dhcdrop,smartphone-pentest-framework,mysql2sqlite,enumiax,blindelphant,smbbf,wol-e,maskprocessor,crackhor,python2-esmre,xprobe2,trixd00r,uatester,fprotlogpraser,videosnarf,sidguesser,rtlizer,webslayer,sb0x,ubitack,winexe,packet-0-matic,thc-smartbrute,sasm,missidentify,peach,secscan,sctpscan,fakenetbios,xssscan,hbad,redesktop-brute,uw-loveimap,voiphopper,statsprocessor,morxkeyfmt,uw-zone,grig,speedpwn,samdump2,swfintruder,bluelog,mboxgrep,synscan,lanmap2,protos-sip,truetrack,safecopy,thc-ppt-bruter,ssh-privkey-crack,dirb,arpalert,balbuzard,uw-udpscan,scrounge-ntfs,haka,stompy,tcpjunk,u3-tool,ftpmap,pemcracker,littelblackbox,dnsgoblin,dns2tcp,hasere.wlan2eth,rrs,rsmangler,beleth,ctunnel,radiography,flunym0us,neglected,wepbuster,idswakeup,urldigger,teardown,sherlocked,airpwn,msvpwn,levye,airpoison,osinterator,zulu,xspy,beholder,iisbruteforcer,dnsdrdos,clamscanlogpraser,owasp-bywaf,dirbuster-ng,uw-offish,nfex,sslnuke,thc-keyfinder,rtp-flood,ratproxy,nsoq,kraken,mausezahn

# sudo pacman -S blackarch-recon
# sudo pacman -S blackarch-osint
# sudo pacman -S blackarch-webapp
# sudo pacman -S blackarch-exploitation
# sudo pacman -S blackarch-wireless 
# sudo pacman -S blackarch-networking
# sudo pacman -S blackarch-forensic



# ---
sudo pacman -Syu
# Go Packages
echo "[*] Setting up Go environment..."
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
mkdir -p "$GOPATH"
if ! grep -q "GOPATH" "$HOME/.bashrc"; then
  echo 'export GOPATH=$HOME/go' >> "$HOME/.bashrc"
  echo 'export PATH=$PATH:$GOPATH/bin' >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
  if ! grep -q "GOPATH" "$HOME/.zshrc"; then
    echo 'export GOPATH=$HOME/go' >> "$HOME/.zshrc"
    echo 'export PATH=$PATH:$GOPATH/bin' >> "$HOME/.zshrc"
  fi
fi

# recon
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

# fuzzing
echo "[*] Installing ffuf..."
go install github.com/ffuf/ffuf@latest

echo "[*] Installing httpx..."
go install github.com/projectdiscovery/httpx/cmd/httpx@latest

echo "[*] Installing pdtm..."
go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest

echo "[*] Installing nuclei..."
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

echo "[*] Installing subfinder..."
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

echo "[*] Installing naabu..."
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest


# ---
# bb-tools
TOOLS_DIR="/resources/bbht"\
mkdir -p "$TOOLS_DIR"\
cd "$TOOLS_DIR"\

echo "[*] Installing Sublist3r..."
if [ ! -d "Sublist3r" ]; then
  git clone https://github.com/aboul3la/Sublist3r.git
fi
sudo pacman -S python3-argparse python3-dnspython python3-requests

echo "[*] Downloading SecLists..."
if [ ! -d "SecLists" ]; then
  git clone https://github.com/danielmiessler/SecLists.git
fi

echo "[*] Downloading pacu..."
if [ ! -d "pacu" ]; then
  git clone https://github.com/RhinoSecurityLabs/pacu.git
fi

echo "[*] Downloading MobSF..."
if [ ! -d "MobSF" ]; then
  git clone https://github.com/MobSF/Mobile-Security-Framework-MobSF.git MobSF
fi

cd 

# ---
# scripts
## omarchy
curl -fsSL https://omarchy.org/install | bash

## 1password
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
git clone https://aur.archlinux.org/1password.git
cd 1password
makepkg -si

## mise
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.bashrc

# ---
# fan configuration
sudo dmesg | grep -i msi
sudo dmidecode -s bios-version

yay -S msi-ec-dkms-git
sudo modprobe -r msi-ec
sudo modprobe msi-ec
cat /sys/devices/platform/msi-ec/shift_mode
sudo modprobe ec_sys write_support=1
yay -S mcontrolcenter-bin

# ---
# battery config
yay -S battery-stats-git --mflags "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

# ---
sudo pacman -Syu
# ufw config
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny forward
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 19683/tcp
sudo ufw logging on
sudo ufw enable
sudo sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw
sudo ufw --force reload
# Block common attack vectors
# sudo ufw deny from 10.0.0.0/8 comment 'Block private range 10.x'
# sudo ufw deny from 172.16.0.0/12 comment 'Block private range 172.16-31.x'
# sudo ufw deny from 192.168.0.0/16 comment 'Block private range 192.168.x'
# Block known malicious networks (example ranges)
# sudo ufw deny from 0.0.0.0/8 comment 'Block broadcast'
# sudo ufw deny from 127.0.0.0/8 comment 'Block loopback from external'
# sudo ufw deny from 224.0.0.0/4 comment 'Block multicast'
# sudo ufw deny from 240.0.0.0/5 comment 'Block reserved'
# Allow loopback
# sudo ufw allow in on lo
# sudo ufw allow out on lo
# sudo ufw allow 3000/tcp comment 'Dev port 3000'
# sudo ufw allow 8000/tcp comment 'Dev port 8000'
# sudo ufw allow 8080/tcp comment 'Dev port 8080'


# ---
# stow.sh

stow-sh(){
  # removing old packages
  cd $HOME
  rm -rf .config/alacritty .config/bat .config/bspwm .config/btop .config/Code .config/cursor
  rm -rf .config/dconf .config/dunst .config/geany .config/ghostty .config/htop .config/kiro
  rm -rf .config/kitty .config/Kvantum .config/neofetch .config/nitrogen .config/nvim
  rm -rf .config/openbox .config/plank .config/powershell .config/rofi .config/Thunar
  rm -rf .config/zed
  rm .config/MControlCenter.conf .config/picom.conf

  rm .bash_profile .bashrc .dmrc .fehbg .nvidia-settings-rc
  rm .tmux.conf
  rm .viminfo .vimrc
  rm .wezterm.lua
  
  rm -rf .zsh 
  rm .zsh_history .zshrc

  sleep 3

  # stowing my packages
  stow -d ~/dotfiles/stow -t ~ --no-folding config
  stow -d ~/dotfiles/stow -t ~ --no-folding shell
  stow -d ~/dotfiles/stow -t ~ --no-folding tmux
  stow -d ~/dotfiles/stow -t ~ --no-folding vim
  stow -d ~/dotfiles/stow -t ~ --no-folding wezterm
  stow -d ~/dotfiles/stow -t ~ --no-folding zsh
}

# stow-sh # - optional
