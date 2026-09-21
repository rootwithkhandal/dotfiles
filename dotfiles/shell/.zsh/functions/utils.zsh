unalias gsw 2>/dev/null

colormap() {
  for i in {0..255}; do
    print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f "
    (( i % 6 == 3 )) && print
  done
}

compress_media() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: compress_media <input> <output> [bitrate]"
    echo "Example: compress_media in.mp4 out.mp4 2M"
    return 1
  fi

  local input="$1"
  local output="$2"
  local bitrate="${3:-2M}"

  [[ -f "$input" ]] || { echo "Input file not found"; return 1; }

  echo "[*] Compressing $input → $output @ $bitrate"

  ffmpeg -y -i "$input" \
    -map 0:v:0 -map 0:a? \
    -c:v libx264 -preset medium -b:v "$bitrate" \
    -c:a aac -b:a 128k \
    "$output"

  [[ $? -eq 0 ]] && echo "[✓] Compression complete" || echo "[✗] Compression failed"
}

set_win_title() {
  print -Pn "\e]0;%n@%m: ${PWD/#$HOME/~}\a"
}
precmd_functions+=(set_win_title)

vn() {
  [[ -n "$1" ]] || { echo "Usage: vn <filename>"; return 1; }

  local inbox="$HOME/Vaults/00_inbox"
  mkdir -p "$inbox"

  nano "$inbox/$1.md"
}

gsw() {
  [[ -n "$1" ]] || { echo "Usage: gsw <branch>"; return 1; }
  git show-ref --verify --quiet "refs/heads/$1" \
    || { echo "Branch does not exist"; return 1; }

  git checkout "$1" && echo "[✓] Switched to $1"
}


get_ip() {
  local tun_ip
  tun_ip=$(ip -4 addr show tun0 2>/dev/null | awk '/inet/{print $2}' | cut -d/ -f1)

  [[ -n "$tun_ip" && "$tun_ip" == 10.* ]] && {
    echo "$tun_ip"
    return
  }

  ip route get 1.1.1.1 | awk '{print $7; exit}'
}

convert_webp() {
  shopt -s nullglob
  local files=(*.webp)

  [[ ${#files[@]} -gt 0 ]] || { echo "No .webp files found"; return 0; }

  for file in "${files[@]}"; do
    local base="${file%.webp}"
    echo "[*] Converting $file → $base.png"
    ffmpeg -y -i "$file" "$base.png"
  done
}

backup_files() {
  echo "[!] backup_files not implemented yet"
  echo "Hint: rsync -a --delete --progress"
}