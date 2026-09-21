import psutil
import smtplib
if psutil.cpu_percent(interval=1) > 80:
    print("High CPU Usage Alert!")