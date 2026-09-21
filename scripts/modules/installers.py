"""Custom application installers"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class CustomInstallers:
    def __init__(self, system, logger, dry_run=False):
        self.system = system
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load custom installers configuration"""
        config_path = Path("config/apps.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def install_all(self):
        """Install all enabled custom applications"""
        installers = self.config.get("custom_installers", {})
        
        for app_name, config in installers.items():
            if not config.get("enabled", True):
                self.logger.info(f"Skipping {app_name} (disabled)")
                continue
            
            self.logger.info(f"Installing {app_name}...")
            
            try:
                if config.get("type") == "apt_repo":
                    self._install_from_repo(app_name, config)
                elif "url" in config:
                    self._install_from_script(app_name, config["url"])
                else:
                    self.logger.warning(f"Unknown installer type for {app_name}")
            except Exception as e:
                self.logger.error(f"Failed to install {app_name}: {e}")
    
    def install_specific(self, app_name):
        """Install a specific custom application"""
        installers = self.config.get("custom_installers", {})
        
        if app_name not in installers:
            self.logger.warning(f"Custom installer '{app_name}' not found in configuration")
            return
        
        config = installers[app_name]
        
        if not config.get("enabled", True):
            self.logger.info(f"Skipping {app_name} (disabled in config)")
            return
        
        self.logger.info(f"Installing {app_name}...")
        
        try:
            if config.get("type") == "apt_repo":
                self._install_from_repo(app_name, config)
            elif "url" in config:
                self._install_from_script(app_name, config["url"])
            else:
                self.logger.warning(f"Unknown installer type for {app_name}")
        except Exception as e:
            self.logger.log_exception(f"Installing {app_name}", e)

    def _install_from_script(self, name, url):
        """Install from a shell script URL"""
        self.runner.run_script(url)
        self.logger.success(f"{name} installed")

    def _install_from_repo(self, name, config):
        """Install from APT repository"""
        keyring_path = f"/etc/apt/keyrings/{name}.gpg"
        
        # Add GPG key
        key_url = config.get("key_url")
        if key_url:
            self.logger.info(f"Adding GPG key for {name}...")
            
            # Download and convert key
            self.runner.run(
                f"curl -fsSL {key_url} | sudo gpg --yes --dearmor -o {keyring_path}",
                shell=True,
                check=False
            )
            
            # Set proper permissions
            self.runner.run(
                f"sudo chmod 644 {keyring_path}",
                shell=True,
                check=False
            )
        
        # Add repository
        repo = config.get("repo")
        if repo:
            self.logger.info(f"Adding repository for {name}...")
            
            # Ensure repo uses signed-by with keyring
            if "signed-by" not in repo and key_url:
                # Insert signed-by into repo string
                if repo.startswith("deb "):
                    repo = f"deb [signed-by={keyring_path}] {repo[4:]}"
            
            self.runner.run(
                f"echo '{repo}' | sudo tee /etc/apt/sources.list.d/{name}.list",
                shell=True
            )
        
        # Update and install
        self.runner.run("sudo apt update", shell=True, check=False)
        package = config.get("package", name)
        self.runner.run(f"sudo apt install -y {package}", shell=True)
        
        self.logger.success(f"{name} installed")
