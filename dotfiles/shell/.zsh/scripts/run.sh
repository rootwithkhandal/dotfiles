#!/usr/bin/env bash
set -e

case "$1" in
  cpu) python monitoring/system/cpu_usage_monitoring.py ;;
  disk) bash monitoring/system/disk_space_monitoring.sh ;;
  logs) python monitoring/logs/elasticsearch_log_monitoring.py ;;
  dns) python monitoring/network/track_DNS_resolution_time.py ;;
  *) echo "Usage: ./run.sh {cpu|disk|logs|dns}" ;;
esac
