#!/bin/bash
# Standalone script: Patch terminal applications to use WezTerm
# This wraps all Terminal=true applications with wezterm

echo "🔧 Patching terminal applications for WezTerm..."

# Clean and create local applications directory
rm -rf ~/.local/share/applications
mkdir -p ~/.local/share/applications

# Find and patch all terminal applications
grep -rl "Terminal=true" /usr/share/applications 2>/dev/null | while read file; do
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
    
    echo "✅ Patched: $base"
done

# Update desktop database
update-desktop-database ~/.local/share/applications 2>/dev/null

echo "✨ Terminal patching completed!"
