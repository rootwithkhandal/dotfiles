"""Docker management"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class DockerManager:
    def __init__(self, system, logger, dry_run=False):
        self.system = system
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load docker configuration"""
        config_path = Path("config/settings.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def install(self):
        """Install Docker and Docker Compose"""
        self.logger.info("Installing Docker...")
        
        if self.system.package_manager == "apt":
            self.runner.run("sudo apt install -y docker.io docker-compose", shell=True)
        elif self.system.package_manager == "dnf":
            self.runner.run("sudo dnf install -y docker docker-compose", shell=True)
        elif self.system.package_manager == "pacman":
            self.runner.run("sudo pacman -S --noconfirm docker docker-compose", shell=True)
        
        # Add user to docker group
        user = self.system.get_user()
        self.runner.run(f"sudo usermod -aG docker {user}", shell=True, check=False)
        
        self.logger.success("Docker installed")

    def create_containers(self):
        """Create Docker containers"""
        containers = self.config.get("docker", {}).get("containers", {})
        
        for name, config in containers.items():
            self.logger.info(f"Creating container: {name}")
            
            # Create volume if needed
            if "portainer_data" in str(config.get("volumes", [])):
                self.runner.run("sudo docker volume create portainer_data", shell=True, check=False)
            
            # Build docker run command
            cmd = ["sudo", "docker", "run", "-d"]
            cmd.append(f"--name={name}")
            
            # Add ports
            for port in config.get("ports", []):
                cmd.extend(["-p", port])
            
            # Add volumes
            for volume in config.get("volumes", []):
                cmd.extend(["-v", volume])
            
            # Add restart policy
            if config.get("restart"):
                cmd.append(f"--restart={config['restart']}")
            
            # Add image
            cmd.append(config["image"])
            
            self.runner.run(cmd, check=False)
