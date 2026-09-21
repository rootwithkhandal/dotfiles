"""Command execution utilities"""
import subprocess
import shlex


class CommandRunner:
    def __init__(self, logger, dry_run=False):
        self.logger = logger
        self.dry_run = dry_run

    def run(self, cmd, shell=False, check=True, capture=False):
        """Execute a command"""
        if isinstance(cmd, str) and not shell:
            cmd = shlex.split(cmd)

        self.logger.debug(f"Running: {cmd if isinstance(cmd, str) else ' '.join(cmd)}")

        if self.dry_run:
            self.logger.info(f"[DRY RUN] Would execute: {cmd}")
            return None

        try:
            result = subprocess.run(
                cmd,
                shell=shell,
                check=check,
                capture_output=capture,
                text=True
            )
            
            if capture:
                return result
            else:
                return result.stdout if hasattr(result, 'stdout') else result
                
        except subprocess.CalledProcessError as e:
            error_msg = f"Command failed with exit code {e.returncode}"
            if hasattr(e, 'stderr') and e.stderr:
                error_msg += f": {e.stderr[:200]}"
            
            self.logger.error(error_msg)
            
            if check:
                raise
            
            # Return result object even on failure for error checking
            return e if capture else None

    def run_script(self, script_url):
        """Download and execute a script"""
        cmd = f"curl -fsSL {script_url} | sh"
        return self.run(cmd, shell=True)
