# Step 1: Update & Core Tool Installation
core_tools() {
  echo "┌─────────────────────────────────┐"
  echo "│    [+] Installing Core Tools    │"
  echo "└──────────────────────────╴ marine"

  sudo apt update && sudo apt full-upgrade -y
  sudo apt install -y \
  build-essential git curl wget python3 python3-pip python3-venv \
  nmap sqlmap nikto metasploit-framework hydra wfuzz gobuster dirb feroxbuster \
  john hashcat aircrack-ng crunch hash-identifier dnsenum enum4linux \
  smbclient smbmap crackmapexec bloodhound neo4j seclists \
  wireshark tshark tcpdump openvpn tor proxychains4 macchanger \
  network-manager-gnome \
  openvas gnome-system-monitor gnome-terminal gnome-screenshot
}
hashcat_setup() {
  echo "┌─────────────────────────────────┐"
  echo "│   [+] Installing Hashcat Tool   │"
  echo "└──────────────────────────╴ marine"
  sudo apt install -y hashcat
}
openvas_setup() {
  echo "┌─────────────────────────────────┐"
  echo "│   [+] Installing OpenVAS Tool   │"
  echo "└──────────────────────────╴ marine"
  sudo apt update
  sudo apt install -y openvas
  sudo gvm-setup
  sudo gvm-check-setup
  sudo gvm-start
  google-chrome https://127.0.0.1:9392
  sudo greenbone-nvt-sync
  sudo greenbone-scapdata-sync
  sudo greenbone-certdata-sync
}
anonymity_setup() {
  echo "┌──────────────────────────────────┐"
  echo "│   [+] Installing Anonymity App   │"
  echo "└───────────────────────────╴ marine"
  sudo systemctl start tor
  sudo systemctl enable tor
  systemctl status tor
}
proxychain_setup() {
  echo "┌──────────────────────────────┐"
  echo "│   [+] SettingUp Proxychain   │"
  echo "└──────────────────────── marine"
  
  sudo echo "[ProxyList]" >> /etc/proxychains4.conf
  sudo echo "# add this if missing:" >> /etc/proxychains4.conf
  sudo echo "socks5  127.0.0.1 9050" >> /etc/proxychains4.conf
  
  sudo nano /etc/proxychains4.conf

  proxychains4 curl https://check.torproject.org/
}
vpn_setup() {
  echo "┌────────────────────────┐"
  echo "│   [+] Installing VPN   │"
  echo "└─────────────────╴ marine"

  sudo apt install -y openvpn network-manager-openvpn-gnome
  # sudo openvpn --config /etc/openvpn/yourvpnfile.ovpn

  # MAC address spoofing with macchanger
  sudo ifconfig wlan0 down
  sudo macchanger -r wlan0
  sudo ifconfig wlan0 up
  ip link show wlan0
}
logging_setup() {
  echo "┌─────────────────────────────────┐"
  echo "│   [+] Installing Logging Apps   │"
  echo "└──────────────────────────╴ marine"

  sudo apt install auditd audispd-plugins
  sudo systemctl enable auditd
  sudo systemctl start auditd
}
zap_setup() {
  echo "┌────────────────────────────┐"
  echo "│   [+] Installing ZAP App   │"
  echo "└─────────────────────╴ marine"
  sudo apt update
  sudo apt install -y zaproxy
}
mobile_tools() {
  echo "┌─────────────────────────────────┐"
  echo "│   [+] Installing Mobile Tools   │"
  echo "└──────────────────────────╴ marine"
  sudo apt install -y adb

  # MobSF (Mobile Security Framework) — automated mobile app testing (Android/iOS):
  git clone https://github.com/MobSF/Mobile-Security-F  ramework-MobSF.git $HOME/.hacking/MobSF
  ./$HOME/.hacking/MobSF/setup.sh
  ./$HOME/.hacking/MobSF/run.sh

  sudo apt install -y frida-tools
  sudo apt install -y apktool
}
cloud_tools() {
  echo "┌────────────────────────────────┐"
  echo "│   [+] Installing Cloud Tools   │"
  echo "└─────────────────────────╴ marine"
  
  sudo apt install -y awscli
  aws configure

  pip3 install scoutsuite

  git clone https://github.com/RhinoSecurityLabs/pacu.git $HOME/.hacking/pacu
  python3 -m venv $HOME/.hacking/pacu/.pyenv
  source ./$HOME/.hacking/pacu/.pyenv/bin/activate
  pip3 install -r requirements.txt
  python3 $HOME/.hacking/pacu/pacu.py

  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

  sudo apt install -y google-cloud-sdk
}
ad_tools() {
  echo "┌───────────────────────────────────────────┐"
  echo "│   [+] Installing Active-Directory Tools   │"
  echo "└────────────────────────────────────╴ marine"

  sudo apt install -y impacket-scripts
  sudo apt install -y crackmapexec
  sudo neo4j start
  sudo apt install -y responder
  sudo apt install -y powersploit
  sudo apt install -y krb5-user
}

bbht_tools() {
  # Tools Installing
  go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
  go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
  # Tools Setup
  ## pdtm
  pdtm -install-all
  ## httpx
  httpx --auth
  httpx -auth
  httpx -dashboard
  httpx -l target.txt -dashboard
  httpx --auth 3ddfdfa3-2ecf-4ab4-aa40-b2019b71c10c
  ## nuclei
  nuclei -auth
  nuclei -target http://honey.scanme.sh -cloud-upload\
}

core_tools 
hashcat_setup
openvas_setup
anonymity_setup
vpn_setup
logging_setup
zap_setup
mobile_tools
cloud_tools
ad_tools