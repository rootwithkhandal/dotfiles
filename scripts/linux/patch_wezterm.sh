#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/share/applications"

grep -rl '^Terminal=true' /usr/share/applications | while IFS= read -r file; do
  base="$(basename "$file")"
  target="$HOME/.local/share/applications/$base"

  cp -n "$file" "$target"

  exec_line="$(grep -m1 '^Exec=' "$target" || true)"
  exec_cmd="${exec_line#Exec=}"
  [[ -n "$exec_cmd" ]] || continue

  sed -i "s|^Exec=.*|Exec=wezterm start -- ${exec_cmd}|g" "$target"
  sed -i 's|^Terminal=true|Terminal=false|g' "$target"

  echo "Patched: $target"
done
