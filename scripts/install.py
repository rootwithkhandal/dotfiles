#!/usr/bin/env python3
"""
Modular dotfiles installer
Automates system setup across multiple Linux distributions
"""
import sys
import argparse
from pathlib import Path

from utils.logger import Logger
from utils.system import SystemDetector
from modules.package_manager import PackageManager
from modules.flatpak import FlatpakManager
from modules.docker import DockerManager
from modules.firewall import FirewallManager
from modules.services import ServiceManager
from modules.installers import CustomInstallers
from modules.vscode import VSCodeManager
from modules.terminal_patcher import TerminalPatcher


def list_available_profiles(logger):
    """List all available installation profiles"""
    logger.header("Available Installation Profiles")
    
    profiles = {
        "Application Categories": [
            ("dependencies", "Essential build tools and libraries"),
            ("editors", "Text editors (neovim, nano)"),
            ("terminals", "Terminal multiplexers (tmux)"),
            ("languages", "Programming languages (Go, Rust, Python, Node.js, Ruby)"),
            ("system-tools", "System utilities (htop, btop, fzf, ripgrep, etc.)"),
            ("network-tools", "Network utilities (nmap, wireshark, curl, wget, etc.)"),
            ("security-tools", "Security/pentesting tools (hydra, metasploit, burpsuite, etc.)"),
            ("media", "Media applications (gimp, audacity, vlc)"),
            ("browsers", "Web browsers (chromium)"),
            ("firewall", "Firewall tools (ufw)"),
            ("desktop", "Desktop tools (polybar)"),
        ],
        "Custom Installers": [
            ("custom-zed", "Zed editor"),
            ("custom-wezterm", "WezTerm terminal"),
            ("custom-brave", "Brave browser"),
            ("custom-spotify", "Spotify (via custom installer)"),
            ("custom-ngrok", "Ngrok tunneling"),
            ("custom-bbht", "Bug bounty hunting tools"),
        ],
        "System Components": [
            ("flatpak", "Flatpak apps installation"),
            ("docker", "Docker and containers"),
            ("vscode", "VSCode extensions"),
            ("services", "System services"),
            ("terminal-patch", "Terminal application patching"),
        ],
        "Special Profiles": [
            ("full", "Complete installation (default)"),
            ("minimal", "Only dependencies and essential tools"),
            ("developer", "Development tools (languages, editors, terminals)"),
            ("security", "Security and pentesting tools"),
        ]
    }
    
    for category, items in profiles.items():
        print(f"\n{category}:")
        for profile, description in items:
            print(f"  --profile {profile:20s} {description}")
    
    print("\nExamples:")
    print("  sudo python3 install.py --profile dependencies")
    print("  sudo python3 install.py --profile editors --profile languages")
    print("  sudo python3 install.py --profile custom-zed --profile custom-brave")
    print("  sudo python3 install.py --profile developer")


def should_install_profile(profiles, profile_name):
    """Check if a profile should be installed"""
    if "full" in profiles:
        return True
    return profile_name in profiles


def install_by_profiles(profiles, args, logger, system, pkg_mgr, flatpak_mgr, 
                       docker_mgr, firewall_mgr, service_mgr, custom_installers, 
                       vscode_mgr, terminal_patcher):
    """Install based on selected profiles"""
    
    # Handle special profiles
    if "minimal" in profiles:
        profiles.extend(["dependencies", "editors", "system-tools"])
    
    if "developer" in profiles:
        profiles.extend(["dependencies", "editors", "terminals", "languages", 
                        "system-tools", "vscode"])
    
    if "security" in profiles:
        profiles.extend(["dependencies", "security-tools", "network-tools"])
    
    # Dependencies
    if should_install_profile(profiles, "dependencies"):
        logger.section("Installing Dependencies")
        pkg_mgr.install_dependencies()
    
    # Application categories
    app_categories = {
        "editors": "editors",
        "terminals": "terminals",
        "languages": "languages",
        "system-tools": "system_tools",
        "network-tools": "network_tools",
        "security-tools": "security_tools",
        "media": "media",
        "browsers": "browsers",
        "firewall": "firewall",
        "desktop": "desktop",
    }
    
    for profile, category in app_categories.items():
        if should_install_profile(profiles, profile):
            logger.section(f"Installing {profile.replace('-', ' ').title()}")
            pkg_mgr.install_category(category)
    
    # Flatpak
    if should_install_profile(profiles, "flatpak") and not args.skip_flatpak:
        logger.section("Setting up Flatpak")
        flatpak_mgr.setup()
        flatpak_mgr.install_apps()
    
    # Custom installers
    custom_map = {
        "custom-zed": "zed",
        "custom-wezterm": "wezterm",
        "custom-brave": "brave",
        "custom-spotify": "spotify",
        "custom-ngrok": "ngrok",
        "custom-bbht": "bbht",
    }
    
    for profile, installer_name in custom_map.items():
        if should_install_profile(profiles, profile):
            logger.section(f"Installing {installer_name.title()}")
            custom_installers.install_specific(installer_name)
    
    # Docker
    if should_install_profile(profiles, "docker") and not args.skip_docker:
        logger.section("Setting up Docker")
        docker_mgr.install()
        docker_mgr.create_containers()
    
    # Services
    if should_install_profile(profiles, "services"):
        logger.section("Enabling Services")
        service_mgr.enable_all()
    
    # Firewall
    if should_install_profile(profiles, "firewall") and not args.skip_firewall:
        logger.section("Configuring Firewall")
        firewall_mgr.configure()
    
    # VSCode
    if should_install_profile(profiles, "vscode") and not args.skip_vscode:
        logger.section("Installing VSCode Extensions")
        vscode_mgr.install_extensions()
    
    # Terminal patching
    if should_install_profile(profiles, "terminal-patch") and not args.skip_terminal_patch:
        logger.section(f"Patching Terminal Applications ({args.terminal})")
        if args.terminal == "wezterm":
            terminal_patcher.patch_for_wezterm()
        elif args.terminal == "ghostty":
            terminal_patcher.patch_for_ghostty()


def main():
    parser = argparse.ArgumentParser(
        description="Automated dotfiles installer with profile-based installation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Profile-based Installation Examples:
  sudo python3 install.py                              # Full installation
  sudo python3 install.py --profile dependencies       # Only dependencies
  sudo python3 install.py --profile editors            # Only editors
  sudo python3 install.py --profile security-tools     # Only security tools
  sudo python3 install.py --profile custom-zed         # Only Zed editor
  sudo python3 install.py --profile custom-brave       # Only Brave browser
  
Multiple profiles:
  sudo python3 install.py --profile editors --profile languages
  
Available profiles:
  dependencies, editors, terminals, languages, system-tools, network-tools,
  security-tools, media, browsers, firewall, desktop, custom-zed, custom-wezterm,
  custom-brave, custom-spotify, custom-sublime, custom-ngrok, custom-bbht
        """
    )
    
    # Profile-based installation
    parser.add_argument("--profile", "-p", action="append", dest="profiles",
                       help="Install specific profile(s). Can be used multiple times.")
    
    # Legacy skip flags (for backward compatibility)
    parser.add_argument("--skip-flatpak", action="store_true", help="Skip Flatpak apps")
    parser.add_argument("--skip-docker", action="store_true", help="Skip Docker setup")
    parser.add_argument("--skip-firewall", action="store_true", help="Skip firewall config")
    parser.add_argument("--skip-vscode", action="store_true", help="Skip VSCode extensions")
    parser.add_argument("--skip-terminal-patch", action="store_true", help="Skip terminal patching")
    
    # Other options
    parser.add_argument("--terminal", choices=["wezterm", "ghostty"], default="wezterm", 
                       help="Terminal to use as default")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--list-profiles", action="store_true", help="List all available profiles")
    
    args = parser.parse_args()

    logger = Logger(verbose=args.verbose)
    
    # List profiles if requested
    if args.list_profiles:
        list_available_profiles(logger)
        sys.exit(0)
    
    logger.header("Dotfiles Installer")

    # Detect system
    system = SystemDetector()
    if not system.is_root():
        logger.error("Please run with sudo privileges")
        sys.exit(1)

    logger.info(f"Detected: {system.distro} ({system.package_manager})")
    
    # Determine what to install based on profiles
    profiles = args.profiles if args.profiles else ["full"]
    logger.info(f"Installation profiles: {', '.join(profiles)}")

    # Initialize managers
    pkg_mgr = PackageManager(system, logger, dry_run=args.dry_run)
    flatpak_mgr = FlatpakManager(logger, dry_run=args.dry_run)
    docker_mgr = DockerManager(system, logger, dry_run=args.dry_run)
    firewall_mgr = FirewallManager(logger, dry_run=args.dry_run)
    service_mgr = ServiceManager(logger, dry_run=args.dry_run)
    custom_installers = CustomInstallers(system, logger, dry_run=args.dry_run)
    vscode_mgr = VSCodeManager(logger, dry_run=args.dry_run)
    terminal_patcher = TerminalPatcher(logger, dry_run=args.dry_run)

    try:
        # Profile-based installation
        install_by_profiles(
            profiles, args, logger, system,
            pkg_mgr, flatpak_mgr, docker_mgr, firewall_mgr,
            service_mgr, custom_installers, vscode_mgr, terminal_patcher
        )

        logger.success("Installation completed successfully!")

    except KeyboardInterrupt:
        logger.warning("\nInstallation interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Installation failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
