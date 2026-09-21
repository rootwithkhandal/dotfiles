"""VSCode extensions management"""
import yaml
from pathlib import Path
from utils.runner import CommandRunner


class VSCodeManager:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.config = self._load_config()

    def _load_config(self):
        """Load VSCode extensions configuration"""
        config_path = Path("config/vscode_extensions.yaml")
        with open(config_path) as f:
            return yaml.safe_load(f)

    def _is_vscode_installed(self):
        """Check if VSCode is installed"""
        try:
            result = self.runner.run("which code", capture=True, check=False)
            if result and hasattr(result, 'stdout'):
                return result.stdout and result.stdout.strip() != ""
            return False
        except Exception:
            return False

    def install_extensions(self):
        """Install all VSCode extensions"""
        if not self._is_vscode_installed():
            self.logger.warning("VSCode 'code' command not found. Skipping extensions.")
            self.logger.info("To fix: Open VSCode → Ctrl+Shift+P → 'Shell Command: Install code command in PATH'")
            return

        extensions = self.config.get("vscode_extensions", [])
        total = len(extensions)
        failed_extensions = []
        
        self.logger.info(f"Installing {total} VSCode extensions...")
        
        for idx, ext in enumerate(extensions, 1):
            self.logger.info(f"[{idx}/{total}] Installing {ext}...")
            try:
                result = self.runner.run(
                    f"code --install-extension {ext} --force",
                    shell=True,
                    check=False,
                    capture=True
                )
                
                if result and result.returncode != 0:
                    error_output = result.stderr if hasattr(result, 'stderr') else str(result)
                    if "not found" in error_output.lower() or "failed" in error_output.lower():
                        self.logger.log_package_error(ext, f"Extension install failed: {error_output[:200]}")
                        failed_extensions.append(ext)
                        
            except Exception as e:
                self.logger.log_exception(f"Installing VSCode extension {ext}", e)
                failed_extensions.append(ext)
        
        if failed_extensions:
            self.logger.warning(f"{len(failed_extensions)} VSCode extension(s) failed to install")
            self.logger.info("Check install.log for details")
        
        self.logger.success(f"VSCode extensions installation completed!")

    def list_installed(self):
        """List currently installed extensions"""
        if not self._is_vscode_installed():
            self.logger.warning("VSCode not found")
            return []
        
        try:
            result = self.runner.run("code --list-extensions", capture=True, check=False)
            if result and hasattr(result, 'stdout') and result.stdout:
                return result.stdout.strip().split('\n')
            return []
        except Exception:
            return []
