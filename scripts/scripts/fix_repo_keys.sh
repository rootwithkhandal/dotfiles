#!/bin/bash
# Fix repository GPG key issues

echo "🔧 Fixing repository GPG keys..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (sudo)${NC}"
    exit 1
fi

echo ""
echo "=== Fixing WezTerm Repository ==="
if [ -f "/etc/apt/sources.list.d/wezterm.list" ]; then
    echo "Removing old WezTerm repository..."
    rm -f /etc/apt/sources.list.d/wezterm.list
    rm -f /etc/apt/keyrings/wezterm-fury.gpg
    
    echo "Re-adding WezTerm repository with correct key..."
    curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    chmod 644 /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | tee /etc/apt/sources.list.d/wezterm.list
    echo -e "${GREEN}✓ WezTerm repository fixed${NC}"
else
    echo -e "${YELLOW}WezTerm repository not found, skipping${NC}"
fi

echo ""
echo "=== Fixing Ngrok Repository ==="
if [ -f "/etc/apt/sources.list.d/ngrok.list" ]; then
    echo "Removing old Ngrok repository..."
    rm -f /etc/apt/sources.list.d/ngrok.list
    rm -f /etc/apt/trusted.gpg.d/ngrok.asc
    rm -f /etc/apt/keyrings/ngrok.gpg
    
    echo "Re-adding Ngrok repository with correct key..."
    curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | gpg --yes --dearmor -o /etc/apt/keyrings/ngrok.gpg
    chmod 644 /etc/apt/keyrings/ngrok.gpg
    echo "deb [signed-by=/etc/apt/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list
    echo -e "${GREEN}✓ Ngrok repository fixed${NC}"
else
    echo -e "${YELLOW}Ngrok repository not found, skipping${NC}"
fi

echo ""
echo "=== Fixing Sublime Text Repository ==="
if [ -f "/etc/apt/sources.list.d/sublime-text.list" ]; then
    echo "Removing Sublime Text repository (disabled in config)..."
    rm -f /etc/apt/sources.list.d/sublime-text.list
    rm -f /etc/apt/trusted.gpg.d/sublimehq-archive.gpg
    rm -f /etc/apt/keyrings/sublime-text.gpg
    echo -e "${GREEN}✓ Sublime Text repository removed${NC}"
else
    echo -e "${YELLOW}Sublime Text repository not found, skipping${NC}"
fi

echo ""
echo "=== Updating package lists ==="
apt update

echo ""
echo -e "${GREEN}✨ Repository keys fixed!${NC}"
echo ""
echo "You can now run:"
echo "  sudo apt update"
echo "  sudo apt install wezterm ngrok"
