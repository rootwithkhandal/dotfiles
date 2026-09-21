#!/bin/bash
LOG_DIR="/var/log/app/"
tar -czf $LOG_DIR/archive_$(date +%F).tar.gz $LOG_DIR/*.log
rm $LOG_DIR/*.log