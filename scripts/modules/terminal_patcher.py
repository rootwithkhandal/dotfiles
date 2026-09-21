"""Terminal application patcher for WezTerm"""
import os
import shutil
import subprocess
from pathlib import Path
from utils.runner import CommandRunner


class TerminalPatcher:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.runner = CommandRunner(logger, dry_run)
        self.dry_run = dry_run
        self.local_apps_dir = Path.home() / ".local/share/applications"
        self.system_apps_dir = Path("/usr/share/applications")

    def patch_for_wezterm(self):
        """Patch all terminal applications to use WezTerm as wrapper"""
        self.logger.info("Patching terminal applications to use WezTerm...")
        
        # Create local applications directory
        self._ensure_local_apps_dir()
        
        # Find all .desktop files with Terminal=true
        terminal_apps = self._find_terminal_apps()
        
        if not terminal_apps:
            self.logger.warning("No terminal applications found to patch")
            return
        
        patched_count = 0
        for app_file in terminal_apps:
            if self._patch_desktop_file(app_file):
                patched_count += 1
        
        self.logger.success(f"Patched {patched_count} terminal applications")
        
        # Update desktop database
        self._update_desktop_database()

    def _ensure_local_apps_dir(self):
        """Create local applications directory"""
        if self.dry_run:
            self.logger.info(f"[DRY RUN] Would create: {self.local_apps_dir}")
            return
        
        # Remove and recreate to ensure clean state
        if self.local_apps_dir.exists():
            self.logger.debug(f"Cleaning existing directory: {self.local_apps_dir}")
        
        self.local_apps_dir.mkdir(parents=True, exist_ok=True)
        self.logger.debug(f"Created: {self.local_apps_dir}")

    def _find_terminal_apps(self):
        """Find all .desktop files with Terminal=true"""
        terminal_apps = []
        
        if not self.system_apps_dir.exists():
            self.logger.warning(f"System applications directory not found: {self.system_apps_dir}")
            return terminal_apps
        
        try:
            # Use grep to find files with Terminal=true
            result = subprocess.run(
                ["grep", "-rl", "Terminal=true", str(self.system_apps_dir)],
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.returncode == 0 and result.stdout:
                terminal_apps = [Path(line.strip()) for line in result.stdout.split('\n') if line.strip()]
                self.logger.info(f"Found {len(terminal_apps)} terminal applications")
            else:
                self.logger.debug("No terminal applications found with grep")
                
        except Exception as e:
            self.logger.error(f"Error finding terminal apps: {e}")
        
        return terminal_apps

    def _patch_desktop_file(self, source_file):
        """Patch a single .desktop file"""
        try:
            base_name = source_file.name
            target_file = self.local_apps_dir / base_name
            
            if self.dry_run:
                self.logger.info(f"[DRY RUN] Would patch: {base_name}")
                return True
            
            # Copy file to local directory (only if not exists)
            if not target_file.exists():
                shutil.copy2(source_file, target_file)
                self.logger.debug(f"Copied: {base_name}")
            
            # Read the file
            with open(target_file, 'r') as f:
                lines = f.readlines()
            
            # Extract original Exec line
            exec_cmd = None
            modified_lines = []
            
            for line in lines:
                if line.startswith('Exec='):
                    exec_cmd = line.replace('Exec=', '').strip()
                    # Wrap with wezterm
                    modified_lines.append(f'Exec=wezterm start -- {exec_cmd}\n')
                elif line.startswith('Terminal=true'):
                    # Disable GNOME's terminal wrapping
                    modified_lines.append('Terminal=false\n')
                else:
                    modified_lines.append(line)
            
            if exec_cmd:
                # Write modified content
                with open(target_file, 'w') as f:
                    f.writelines(modified_lines)
                
                self.logger.success(f"✓ Patched: {base_name}")
                return True
            else:
                self.logger.warning(f"No Exec line found in: {base_name}")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to patch {source_file.name}: {e}")
            return False

    def _update_desktop_database(self):
        """Update desktop database to apply changes"""
        if self.dry_run:
            self.logger.info("[DRY RUN] Would update desktop database")
            return
        
        try:
            self.runner.run(
                f"update-desktop-database {self.local_apps_dir}",
                shell=True,
                check=False
            )
            self.logger.debug("Desktop database updated")
        except Exception as e:
            self.logger.warning(f"Could not update desktop database: {e}")

    def patch_for_ghostty(self):
        """Patch all terminal applications to use Ghostty as wrapper"""
        self.logger.info("Patching terminal applications to use Ghostty...")
        
        # Similar implementation but with ghostty command
        self._ensure_local_apps_dir()
        terminal_apps = self._find_terminal_apps()
        
        if not terminal_apps:
            self.logger.warning("No terminal applications found to patch")
            return
        
        patched_count = 0
        for app_file in terminal_apps:
            if self._patch_desktop_file_ghostty(app_file):
                patched_count += 1
        
        self.logger.success(f"Patched {patched_count} terminal applications for Ghostty")
        self._update_desktop_database()

    def _patch_desktop_file_ghostty(self, source_file):
        """Patch a single .desktop file for Ghostty"""
        try:
            base_name = source_file.name
            target_file = self.local_apps_dir / base_name
            
            if self.dry_run:
                self.logger.info(f"[DRY RUN] Would patch: {base_name}")
                return True
            
            if not target_file.exists():
                shutil.copy2(source_file, target_file)
            
            with open(target_file, 'r') as f:
                lines = f.readlines()
            
            exec_cmd = None
            modified_lines = []
            
            for line in lines:
                if line.startswith('Exec='):
                    exec_cmd = line.replace('Exec=', '').strip()
                    modified_lines.append(f'Exec=ghostty -e {exec_cmd}\n')
                elif line.startswith('Terminal=true'):
                    modified_lines.append('Terminal=false\n')
                else:
                    modified_lines.append(line)
            
            if exec_cmd:
                with open(target_file, 'w') as f:
                    f.writelines(modified_lines)
                
                self.logger.success(f"✓ Patched: {base_name}")
                return True
            else:
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to patch {source_file.name}: {e}")
            return False
