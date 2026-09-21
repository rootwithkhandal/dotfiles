app_permissions=(
    systemctl start docker --now
    systemctl start ngrok.service
    # service mysql start              
    # service nginx start             
    # service postgresql start      
    # service ssh start              
    service bluetooth start
    systemctl enable bluetooth
)