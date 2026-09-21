#!/bin/bash
# Safer patch: wrap original Exec in wezterm

rm -rf ~/.local/share/applications
mkdir -p ~/.local/share/applications

grep -rl "Terminal=true" /usr/share/applications | while read file; do
    base=$(basename "$file")
    target="$HOME/.local/share/applications/$base"

    # Copy if not already in local overrides
    cp -n "$file" "$target"

    # Extract original Exec line
    exec_cmd=$(grep '^Exec=' "$target" | sed 's/^Exec=//')

    # Replace Exec to wrap with wezterm
    sed -i "s|^Exec=.*|Exec=wezterm start -- ${exec_cmd}|g" "$target"

    # Disable GNOME's terminal wrapping
    sed -i 's|^Terminal=true|Terminal=false|g' "$target"

    echo "✅ Patched: $target"
done
