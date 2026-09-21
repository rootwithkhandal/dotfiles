#!/bin/bash
THRESHOLD=500 # in MB
AVAILABLE=$(free -m | awk '/Mem/ {print $7}')
if [ $AVAILABLE -lt $THRESHOLD ]; then
    echo "Low Memory Alert!"
fi