"""System detection utilities"""
import os
import platform
import subprocess


class SystemDetector:
    def __init__(self):
        self.distro = self._detect_distro()
        self.package_manager = self._detect_package_manager()

    def _detect_distro(self):
        """Detect Linux distribution"""
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("ID="):
                        return line.split("=")[1].strip().strip('"')
        except FileNotFoundError:
            pass
        return "unknown"

    def _detect_package_manager(self):
        """Detect available package manager"""
        managers = {
            "apt": ["debian", "ubuntu", "mint"],
            "dnf": ["fedora", "rhel", "centos"],
            "pacman": ["arch", "manjaro"],
            "zypper": ["opensuse"],
        }
        
        for mgr, distros in managers.items():
            if self.distro in distros:
                return mgr
        
        # Fallback: check if command exists
        for mgr in managers.keys():
            if self._command_exists(mgr):
                return mgr
        
        return "unknown"

    def _command_exists(self, cmd):
        """Check if command exists"""
        return subprocess.run(
            ["which", cmd],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        ).returncode == 0

    def is_root(self):
        """Check if running as root"""
        return os.geteuid() == 0

    def get_user(self):
        """Get the actual user (not root)"""
        return os.environ.get("SUDO_USER", os.environ.get("USER"))
