#!/bin/bash
# Quick script to view installation errors from log file

LOG_FILE="install.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "No log file found at $LOG_FILE"
    exit 1
fi

echo "=== Installation Error Summary ==="
echo

# Count errors
PACKAGE_ERRORS=$(grep -c "PACKAGE_ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
EXCEPTIONS=$(grep -c "EXCEPTION" "$LOG_FILE" 2>/dev/null || echo "0")
TOTAL_ERRORS=$(grep -c "\[ERROR\]" "$LOG_FILE" 2>/dev/null || echo "0")

echo "Total Errors: $TOTAL_ERRORS"
echo "Package Errors: $PACKAGE_ERRORS"
echo "Exceptions: $EXCEPTIONS"
echo

if [ "$PACKAGE_ERRORS" -gt 0 ]; then
    echo "=== Package Installation Errors ==="
    grep "PACKAGE_ERROR" "$LOG_FILE" | tail -20
    echo
fi

if [ "$EXCEPTIONS" -gt 0 ]; then
    echo "=== Exceptions ==="
    grep "EXCEPTION" "$LOG_FILE" | tail -10
    echo
fi

echo "=== Recent Errors (last 10) ==="
grep "\[ERROR\]" "$LOG_FILE" | tail -10

echo
echo "To view full log: cat $LOG_FILE"
echo "To view all package errors: grep 'PACKAGE_ERROR' $LOG_FILE"
