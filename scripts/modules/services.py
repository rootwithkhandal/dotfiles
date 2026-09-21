"""System services management"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class ServiceManager:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load services configuration"""
        config_path = Path("config/settings.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def enable_all(self):
        """Enable and start all configured services"""
        services = self.config.get("services", [])
        
        for service in services:
            name = service["name"]
            action = service.get("action", "start")
            
            self.logger.info(f"Starting service: {name}")
            self.runner.run(
                f"sudo systemctl {action} {name}",
                shell=True,
                check=False
            )
            
            if service.get("enable"):
                self.logger.info(f"Enabling service: {name}")
                self.runner.run(
                    f"sudo systemctl enable {name}",
                    shell=True,
                    check=False
                )
