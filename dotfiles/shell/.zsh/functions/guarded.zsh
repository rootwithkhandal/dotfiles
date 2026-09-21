unalias nmap 2>/dev/null
unalias ping 2>/dev/null
unalias sqlmap 2>/dev/null
unalias gpsh 2>/dev/null
unalias docker 2>/dev/null
unalias drm 2>/dev/null
unalias drmi 2>/dev/null
unalias pyserver 2>/dev/null


nmap() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: nmap <target> [options]"
    return 1
  fi

  echo "[*] Running safe default scan (-sC -sV)"
  command nmap -sC -sV "$@"
}

drm() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: drm <container_id|name>"
    return 1
  fi
  command docker rm "$@"
}

drmi() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: drmi <image_id>"
    return 1
  fi
  command docker rmi "$@"
}

dstop-all() {
  echo "[!] This will stop ALL running containers."
  read "?Proceed? (y/N): " confirm
  [[ "$confirm" == "y" ]] || return 1

  command docker stop $(docker ps -q)
}

ping() {
  if [[ $# -eq 1 ]]; then
    command ping -c 5 "$1"
  else
    command ping "$@"
  fi
}

sqlmap() {
  if [[ "$*" != *"-u"* ]]; then
    echo "sqlmap requires -u <URL>"
    return 1
  fi

  echo "[*] Running sqlmap with safe defaults"
  command sqlmap --batch --random-agent "$@"
}

rm() {
  echo "[!] rm called with: $*"
  read "?Confirm delete? (y/N): " confirm
  [[ "$confirm" == "y" ]] || return 1

  command rm "$@"
}

pyserver() {
  local port=${1:-4445}

  if ss -tuln | grep -q ":$port "; then
    echo "[!] Port $port already in use"
    return 1
  fi

  echo "[*] Serving HTTP on port $port"
  python3 -m http.server "$port"
}

gpsh() {
  branch=$(git branch --show-current 2>/dev/null)

  if [[ -z "$branch" ]]; then
    echo "[!] Not in a git repo"
    return 1
  fi

  echo "[*] Pushing branch: $branch"
  read "?Proceed? (y/N): " confirm
  [[ "$confirm" == "y" ]] || return 1

  command git push
}
