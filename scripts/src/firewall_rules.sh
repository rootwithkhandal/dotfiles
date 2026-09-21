firerules=(
    disable
    allow ssh/tcp
    limit ssh/tcp
    allow 19683/tcp
    logging on
    enable
    status
)