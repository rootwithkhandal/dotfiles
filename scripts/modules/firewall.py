"""Firewall configuration"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class FirewallManager:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load firewall configuration"""
        config_path = Path("config/settings.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def configure(self):
        """Configure UFW firewall"""
        rules = self.config.get("firewall", {}).get("rules", [])
        
        for rule in rules:
            self.logger.info(f"Applying rule: {rule}")
            self.runner.run(f"sudo ufw {rule}", shell=True, check=False)
        
        self.logger.success("Firewall configured")
