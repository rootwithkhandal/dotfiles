"""Package manager abstraction"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class PackageManager:
    def __init__(self, system, logger, dry_run=False):
        self.system = system
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load package configuration"""
        config_path = Path("config/apps.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def _get_distro_config(self):
        """Get distribution-specific commands"""
        distro_path = Path("config/distros.yaml")
        with open(distro_path) as f:
            distros = yaml.safe_load(f)
        return distros.get(self.system.distro, distros.get("debian"))

    def update(self):
        """Update package lists"""
        distro_config = self._get_distro_config()
        self.logger.info("Updating package lists...")
        self.runner.run(f"sudo {distro_config['update_cmd']}", shell=True)

    def install_dependencies(self):
        """Install essential dependencies"""
        self.update()
        deps = self.config.get("dependencies", [])
        self._install_packages(deps, "dependencies")

    def install_applications(self):
        """Install all applications"""
        apps = self.config.get("applications", {})
        all_apps = []
        
        for category, packages in apps.items():
            self.logger.info(f"Installing {category}...")
            all_apps.extend(packages)
        
        self._install_packages(all_apps, "applications")
    
    def install_category(self, category):
        """Install applications from a specific category"""
        apps = self.config.get("applications", {})
        
        if category not in apps:
            self.logger.warning(f"Category '{category}' not found in configuration")
            return
        
        packages = apps[category]
        self.logger.info(f"Installing {len(packages)} packages from {category}")
        self._install_packages(packages, category)

    def _install_packages(self, packages, category):
        """Install a list of packages"""
        distro_config = self._get_distro_config()
        failed_packages = []
        
        for pkg in packages:
            try:
                self.logger.info(f"Installing {pkg}...")
                cmd = f"sudo {distro_config['install_cmd']} {pkg}"
                result = self.runner.run(cmd, shell=True, check=False, capture=True)
                
                # Check for common error patterns
                if result and result.returncode != 0:
                    error_output = result.stderr if hasattr(result, 'stderr') else str(result)
                    
                    # Detect specific error types
                    if "no installation candidate" in error_output.lower():
                        self.logger.log_package_error(pkg, "No installation candidate found")
                        failed_packages.append((pkg, "No installation candidate"))
                    elif "unable to locate package" in error_output.lower():
                        self.logger.log_package_error(pkg, "Package not found in repositories")
                        failed_packages.append((pkg, "Package not found"))
                    elif "package has no installation candidate" in error_output.lower():
                        self.logger.log_package_error(pkg, "Package has no installation candidate")
                        failed_packages.append((pkg, "No installation candidate"))
                    else:
                        self.logger.log_package_error(pkg, error_output[:200])
                        failed_packages.append((pkg, "Installation failed"))
                        
            except Exception as e:
                self.logger.log_exception(f"Installing {pkg}", e)
                failed_packages.append((pkg, str(e)))
        
        # Summary of failed packages
        if failed_packages:
            self.logger.warning(f"{len(failed_packages)} package(s) failed in {category}")
            self.logger.info(f"Check install.log for details")
