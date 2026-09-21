#!/bin/bash

# Shield.sh - Advanced UFW Firewall Configuration Script
# Author: System Administrator
# Description: Comprehensive firewall setup with security hardening

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/shield.log"
BACKUP_DIR="/etc/ufw/backup_$(date +%Y%m%d_%H%M%S)"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SHIELD]${NC} $1"
}

# Function to log actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Backup current UFW configuration
backup_config() {
    print_status "Creating backup of current UFW configuration..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r /etc/ufw/* "$BACKUP_DIR/" 2>/dev/null || true
    log_action "Configuration backed up to $BACKUP_DIR"
}

# Reset UFW to defaults
reset_firewall() {
    print_status "Resetting UFW to default state..."
    sudo ufw --force reset
    log_action "UFW reset to defaults"
}

# Configure basic UFW policies
configure_basic_policies() {
    print_status "Configuring basic firewall policies..."
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw default deny forward
    
    log_action "Basic policies configured: deny incoming, allow outgoing, deny forward"
}

# Configure essential services
configure_essential_services() {
    print_status "Configuring essential services..."
    
    # SSH (customize port as needed)
    read -p "Enter SSH port (default 22): " ssh_port
    ssh_port=${ssh_port:-22}
    sudo ufw allow "$ssh_port"/tcp comment 'SSH'
    
    # HTTP/HTTPS for web services
    read -p "Allow HTTP/HTTPS? (y/n): " allow_web
    if [[ $allow_web =~ ^[Yy]$ ]]; then
        sudo ufw allow 80/tcp comment 'HTTP'
        sudo ufw allow 443/tcp comment 'HTTPS'
        log_action "HTTP/HTTPS allowed"
    fi
    
    log_action "Essential services configured"
} 
# Configure advanced security rules
configure_advanced_security() {
    print_status "Configuring advanced security rules..."
    
    # Rate limiting for SSH
    sudo ufw limit "$ssh_port"/tcp comment 'SSH rate limit'
    
    # Block common attack vectors
    sudo ufw deny from 10.0.0.0/8 comment 'Block private range 10.x'
    sudo ufw deny from 172.16.0.0/12 comment 'Block private range 172.16-31.x'
    sudo ufw deny from 192.168.0.0/16 comment 'Block private range 192.168.x'
    
    # Block known malicious networks (example ranges)
    sudo ufw deny from 0.0.0.0/8 comment 'Block broadcast'
    sudo ufw deny from 127.0.0.0/8 comment 'Block loopback from external'
    sudo ufw deny from 224.0.0.0/4 comment 'Block multicast'
    sudo ufw deny from 240.0.0.0/5 comment 'Block reserved'
    
    # Allow loopback
    sudo ufw allow in on lo
    sudo ufw allow out on lo
    
    log_action "Advanced security rules configured"
}

# Configure application-specific rules
configure_applications() {
    print_status "Configuring application-specific rules..."
    
    # Common applications
    read -p "Allow FTP (21)? (y/n): " allow_ftp
    if [[ $allow_ftp =~ ^[Yy]$ ]]; then
        sudo ufw allow 21/tcp comment 'FTP'
    fi
    
    read -p "Allow SMTP (25, 587)? (y/n): " allow_smtp
    if [[ $allow_smtp =~ ^[Yy]$ ]]; then
        sudo ufw allow 25/tcp comment 'SMTP'
        sudo ufw allow 587/tcp comment 'SMTP Submission'
    fi
    
    read -p "Allow DNS (53)? (y/n): " allow_dns
    if [[ $allow_dns =~ ^[Yy]$ ]]; then
        sudo ufw allow 53/tcp comment 'DNS TCP'
        sudo ufw allow 53/udp comment 'DNS UDP'
    fi
    
    read -p "Allow NTP (123)? (y/n): " allow_ntp
    if [[ $allow_ntp =~ ^[Yy]$ ]]; then
        sudo ufw allow out 123/udp comment 'NTP'
    fi
    
    # Development ports
    read -p "Allow development ports (3000, 8000, 8080)? (y/n): " allow_dev
    if [[ $allow_dev =~ ^[Yy]$ ]]; then
        sudo ufw allow 3000/tcp comment 'Dev port 3000'
        sudo ufw allow 8000/tcp comment 'Dev port 8000'
        sudo ufw allow 8080/tcp comment 'Dev port 8080'
    fi
    
    log_action "Application-specific rules configured"
}

# Configure logging
configure_logging() {
    print_status "Configuring UFW logging..."
    
    # Enable logging
    sudo ufw logging on
    
    # Configure log level
    read -p "Select log level (low/medium/high/full) [medium]: " log_level
    log_level=${log_level:-medium}
    sudo ufw logging "$log_level"
    
    log_action "UFW logging configured: $log_level"
}

# Configure IP whitelisting
configure_whitelist() {
    print_status "Configuring IP whitelist..."
    
    read -p "Add trusted IP addresses? (y/n): " add_whitelist
    if [[ $add_whitelist =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter trusted IP (or 'done' to finish): " trusted_ip
            if [[ $trusted_ip == "done" ]]; then
                break
            fi
            if ed_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                sudo ufw allow from "$trusted_ip" comment "Trusted IP: $trusted_ip"
                log_action "Whitelisted IP: $trusted_ip"
            else
                print_warning "Invalid IP format: $trusted_ip"
            fi
        done
    fi
}

# Configure port knocking (basic implementation)
configure_port_knocking() {
    print_status "Configuring basic port knocking protection..."
    
  ead -p "Enable port knocking for SSH? (y/n): " enable_knocking
    if [[ $enable_knocking =~ ^[Yy]$ ]]; then
        # This is a simplified version - full port knocking requires additional tools
        print_warning "Port knocking requires additional configuration with knockd"
        print_warning "Consider installing and configuring knockd for full port knocking"
        log_action "Port knocking configuration noted"
    fi
}

# Enable IPv6 protection
configure_ipv6() {
    print_status "Configuring IPv6 protection
    # Enable IPv6 in UFW
    sudo sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw
    
    # Apply same rules to IPv6
    sudo ufw --force reload
    
    log_action "IPv6 protection enabled"
}

# Display current status
show_status() {
    print_header "Current Firewall Status:"
    sudo ufw status verbose
    echo
    print_header "Active Rules:"
    sudo ufw status numbered
}

# Main menu
show_menu() {
    echo
    print_header "Shield.sh - Advanced UFW Firewall Manager"
    echo "1. Full Setup (Recommended)"
    echo "2. Basic Setup"
    echo "3. Reset Firewall"
    echo "4. Show Status"
    echo "5. Add Custom Rule"
    echo "6. Remove Rule"
    echo "7. Enable Firewall"
    echo "8. Disable Firewall"
    echo "9. Exit"
    echo
}

# Add custom rule
add_custom_rule() {   print_status "Adding custom rule..."
    read -p "Enter rule (e.g., 'allow 8080/tcp'): " custom_rule
    if [[ -n $custom_rule ]]; then
        sudo ufw $custom_rule
        log_action "Custom rule added: $custom_rule"
    fi
}

# Remove rule by numr
remove_rule() {
    print_status "Current rules:"
    sudo ufw status numbered
    read -p "Enter rule number to remove: " rule_num
    if [[ $rule_num =~ ^[0-9]+$ ]]; then
        sudo ufw --force delete "$rule_num"
        log_action "Rule $rule_num removed"
    fi
}

# Full setup function
full_setup() {
    print_header "Starting full firewall setup..."
    
    backup_config
    reset_firewall
    configure_basic_policies
    configure_essential_services
    configure_advanced_security
    configure_applications
    configure_logging
    configure_whitelist
    configure_ipv6
    
    print_status "Enabling firewall..."
    sudo ufw --force enable
    
    show_status
    print_header "Full setup completed successfully!"
    log_action "Full firewall setup completed"
}

# Basic setup function
basic_setup() {
    print_header "Starting basic firewall setup..."
    
    backup_config
    configure_basic_policies
    configure_essential_services
    
    print_status "Enabling firewall..."
    sudo ufw --force enable
    
    show_status
    print_header "Basic setup completed!"
    log_action "Basic firewall setup completed"
}

# Main execution
main() {
    check_root
    
    # Create log file if it doesn't exist
    sudo touch "$LOG_FILE"
    log_action "Shield.sh started"
    
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option [1-9]: " choice
            
            case $choice in
                1) full_setup ;;
                2) basic_setup ;;
                3) reset_firewall && print_status "Firewall reset completed" ;;
                4) show_status ;;
                5) add_custom_rule ;;
                6) remove_rule ;;
                7) sudo ufw --force enable && print_status "Firewall enabled" ;;
                8) sudo ufw --force disable && print_warning "Firewall disabled" ;;
                9) print_status "Exiting Shield.sh"; exit 0 ;;
                *) print_error "Invalid option. Please try again." ;;
            esac
            
            read -p Enter to continue..."
        done
    else
        # Command line mode
        case $1 in
            "full") full_setup ;;
            "basic") basic_setup ;;
            "reset") reset_firewall ;;
            "status") show_status ;;
            "enable") sudo ufw --force enable ;;
            "disable") sudo ufw --force disable ;;
            *) 
                echo "Usage: $0 [full|basic|reset|status|enable|disable]"
                echo "Run without arguments for interactive mode"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"