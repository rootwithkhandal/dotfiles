#!/bin/bash
# Wrap apps that request a terminal into ghostty (or another terminal emulator)

# TERMINAL="ghostty start --"
TERMINAL="/usr/bin/ghostty start --"

mkdir -p ~/.local/share/applications

grep -rl '^Terminal=true' /usr/share/applications | while IFS= read -r file; do
    base=$(basename "$file")
    target="$HOME/.local/share/applications/$base"

    # Copy if not already in local overrides
    cp -n "$file" "$target"

    # Extract exact Exec line
    exec_line=$(grep -m1 '^Exec=' "$target")
    exec_cmd="${exec_line#Exec=}"

    # Replace Exec to wrap with custom terminal
    sed -i "s|^Exec=.*|Exec=${TERMINAL} ${exec_cmd}|g" "$target"

    # Disable GNOME terminal wrapping
    sed -i 's|^Terminal=true|Terminal=false|g' "$target"

    echo "✅ Patched: $target"
done
