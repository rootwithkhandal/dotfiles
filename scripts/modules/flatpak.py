"""Flatpak management"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class FlatpakManager:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load flatpak configuration"""
        config_path = Path("config/apps.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def setup(self):
        """Setup flatpak and flathub"""
        # Install flatpak if not present
        if not self._is_installed():
            self.logger.info("Installing Flatpak...")
            self.runner.run("sudo apt install -y flatpak", shell=True)
        else:
            self.logger.success("Flatpak already installed")

        # Add flathub repo
        try:
            result = self.runner.run("flatpak remotes", capture=True, check=False)
            remotes_output = ""
            
            if result and hasattr(result, 'stdout'):
                remotes_output = result.stdout if result.stdout else ""
            
            if "flathub" not in remotes_output:
                self.logger.info("Adding Flathub repository...")
                self.runner.run(
                    "flatpak remote-add --if-not-exists flathub "
                    "https://flathub.org/repo/flathub.flatpakrepo",
                    shell=True
                )
            else:
                self.logger.success("Flathub already configured")
        except Exception as e:
            self.logger.log_exception("Setting up Flathub", e)

    def _is_installed(self):
        """Check if flatpak is installed"""
        try:
            result = self.runner.run("which flatpak", capture=True, check=False)
            if result and hasattr(result, 'stdout'):
                return result.stdout and result.stdout.strip() != ""
            return False
        except Exception:
            return False

    def install_apps(self):
        """Install flatpak applications"""
        apps = self.config.get("flatpak_apps", [])
        failed_apps = []
        
        for app in apps:
            if self._is_app_installed(app):
                self.logger.success(f"{app} already installed")
            else:
                self.logger.info(f"Installing {app}...")
                try:
                    result = self.runner.run(
                        f"flatpak install -y flathub {app}",
                        shell=True,
                        check=False,
                        capture=True
                    )
                    
                    if result and result.returncode != 0:
                        error_output = result.stderr if hasattr(result, 'stderr') else str(result)
                        self.logger.log_package_error(app, f"Flatpak install failed: {error_output[:200]}")
                        failed_apps.append(app)
                        
                except Exception as e:
                    self.logger.log_exception(f"Installing flatpak {app}", e)
                    failed_apps.append(app)
        
        if failed_apps:
            self.logger.warning(f"{len(failed_apps)} Flatpak app(s) failed to install")
            self.logger.info("Check install.log for details")

    def _is_app_installed(self, app):
        """Check if flatpak app is installed"""
        try:
            result = self.runner.run("flatpak list --app", capture=True, check=False)
            if result and hasattr(result, 'stdout'):
                return app in (result.stdout if result.stdout else "")
            return False
        except Exception:
            return False
