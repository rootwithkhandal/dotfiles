"""Logging utilities with colored output"""
from datetime import datetime
from pathlib import Path


class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'


class Logger:
    def __init__(self, verbose=False, log_file="install.log"):
        self.verbose = verbose
        self.log_file = Path(log_file)
        self._init_log_file()

    def _init_log_file(self):
        """Initialize log file with header"""
        try:
            with open(self.log_file, 'a') as f:
                f.write(f"\n{'='*80}\n")
                f.write(f"Installation Log - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"{'='*80}\n\n")
        except Exception as e:
            print(f"Warning: Could not initialize log file: {e}")

    def _write_to_log(self, level, message):
        """Write message to log file"""
        try:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            with open(self.log_file, 'a') as f:
                f.write(f"[{timestamp}] [{level}] {message}\n")
        except Exception as e:
            print(f"Warning: Could not write to log file: {e}")

    def _log(self, message, color="", prefix="", level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"{color}[{timestamp}] {prefix}{message}{Colors.END}")
        
        # Write to log file (without color codes)
        self._write_to_log(level, f"{prefix}{message}")

    def header(self, message):
        print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*60}")
        print(f"  {message}")
        print(f"{'='*60}{Colors.END}\n")
        self._write_to_log("HEADER", message)

    def section(self, message):
        print(f"\n{Colors.BOLD}{Colors.BLUE}▶ {message}{Colors.END}")
        self._write_to_log("SECTION", message)

    def info(self, message):
        self._log(message, Colors.CYAN, "ℹ ", "INFO")

    def success(self, message):
        self._log(message, Colors.GREEN, "✓ ", "SUCCESS")

    def warning(self, message):
        self._log(message, Colors.YELLOW, "⚠ ", "WARNING")

    def error(self, message):
        self._log(message, Colors.RED, "✗ ", "ERROR")

    def debug(self, message):
        if self.verbose:
            self._log(message, "", "→ ", "DEBUG")
    
    def log_package_error(self, package, error_msg):
        """Log package installation error with details"""
        error_detail = f"Failed to install package '{package}': {error_msg}"
        self.error(error_detail)
        self._write_to_log("PACKAGE_ERROR", f"Package: {package} | Error: {error_msg}")
    
    def log_exception(self, context, exception):
        """Log exception with context"""
        error_msg = f"{context}: {str(exception)}"
        self.error(error_msg)
        self._write_to_log("EXCEPTION", f"Context: {context} | Exception: {type(exception).__name__}: {str(exception)}")
