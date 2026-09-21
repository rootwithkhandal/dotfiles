alias ipconfig="ip a"
alias netstat="ss -tulnp"
alias ports="ss -tulnp | grep LISTEN"

alias ping="ping -c 5"
alias trace="traceroute"

alias myip="curl ifconfig.me"
alias checkip="curl -s ipinfo.io"
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"

alias dnslookup="nslookup"
alias dnstrace="dig +trace google.com"
alias dnsflush="sudo resolvectl flush-caches"

alias wifi="nmtui"
alias sniff="sudo tcpdump -i any"
alias arp="arp -a"
alias iperf="iperf3"
