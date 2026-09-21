#!/bin/bash
# Production readiness verification script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

print_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

ERRORS=0

print_header "Production Readiness Verification"

# Check Python files
print_header "Checking Python Files"
cd "$ROOT_DIR"

if python3 -m py_compile install.py 2>/dev/null; then
    print_success "install.py compiles"
else
    print_error "install.py has syntax errors"
    ERRORS=$((ERRORS + 1))
fi

for file in modules/*.py utils/*.py; do
    if [ -f "$file" ]; then
        if python3 -m py_compile "$file" 2>/dev/null; then
            print_success "$file compiles"
        else
            print_error "$file has syntax errors"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# Check for unwanted files
print_header "Checking for Unwanted Files"

if [ -d "__pycache__" ] || [ -d "modules/__pycache__" ] || [ -d "utils/__pycache__" ]; then
    print_error "Found __pycache__ directories"
    ERRORS=$((ERRORS + 1))
else
    print_success "No __pycache__ directories"
fi

if find . -name "*.pyc" -o -name "*.pyo" | grep -q .; then
    print_error "Found .pyc/.pyo files"
    ERRORS=$((ERRORS + 1))
else
    print_success "No .pyc/.pyo files"
fi

if find . -name "test_*.py" | grep -q .; then
    print_error "Found test files"
    ERRORS=$((ERRORS + 1))
else
    print_success "No test files"
fi

if find . -name "*stow*" -type f | grep -v ".git" | grep -q .; then
    print_warning "Found stow-related files (check if intentional)"
else
    print_success "No stow files"
fi

# Check executables
print_header "Checking Executables"

if [ -x "install.py" ]; then
    print_success "install.py is executable"
else
    print_error "install.py is not executable"
    ERRORS=$((ERRORS + 1))
fi

for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        print_success "$script is executable"
    else
        print_error "$script is not executable"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check required files
print_header "Checking Required Files"

REQUIRED_FILES=(
    "install.py"
    "requirements.txt"
    "README.md"
    ".gitignore"
    "config/apps.yaml"
    "config/distros.yaml"
    "config/settings.yaml"
    "config/vscode_extensions.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check Python dependencies
print_header "Checking Python Dependencies"

if python3 -c "import yaml" 2>/dev/null; then
    print_success "PyYAML is installed"
else
    print_warning "PyYAML not installed (run: pip3 install -r requirements.txt)"
fi

# Test installer help
print_header "Testing Installer"

if python3 install.py --help >/dev/null 2>&1; then
    print_success "Installer help works"
else
    print_error "Installer help failed"
    ERRORS=$((ERRORS + 1))
fi

if python3 install.py --list-profiles >/dev/null 2>&1; then
    print_success "List profiles works"
else
    print_error "List profiles failed"
    ERRORS=$((ERRORS + 1))
fi

# Check YAML syntax
print_header "Checking YAML Files"

for yaml_file in config/*.yaml; do
    if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
        print_success "$yaml_file is valid"
    else
        print_error "$yaml_file has syntax errors"
        ERRORS=$((ERRORS + 1))
    fi
done

# Summary
print_header "Summary"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════╗"
    echo "║   ✓ PRODUCTION READY                   ║"
    echo "║   All checks passed!                   ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 0
else
    echo -e "${RED}"
    echo "╔════════════════════════════════════════╗"
    echo "║   ✗ ISSUES FOUND: $ERRORS                     ║"
    echo "║   Please fix errors before deploying  ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
fi
