#!/bin/bash
eval "$(ssh-agent -s)"
ssh-add /Users/admin/.ssh/id_rsa

# Remote server details

# REMOTE_USER="strapi"
# REMOTE_HOST="10.0.0.190"
REMOTE_USER="root"
REMOTE_HOST="188.68.223.12"

REMOTE_PATH="/"
BACKUP_DIR="./_backup"

# Build volume names dynamically from REMOTE_USER
DATA_VOL="${REMOTE_USER}_data"
PUBLIC_VOL="${REMOTE_USER}_public"
CONFIG_SYNC_VOL="${REMOTE_USER}_config_sync"

# SSH command
SSH_CMD="ssh $REMOTE_USER@$REMOTE_HOST"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to stop all containers
stop_containers() {
    echo "Stopping all containers on the server..."
    $SSH_CMD "docker-compose down"
}

# Function to start all containers
start_containers() {
    echo "Starting all containers on the server..."
    $SSH_CMD "docker-compose up -d"
}

# Function to backup volumes
_backup_volumes() {
    echo "Backing up '$DATA_VOL', '$PUBLIC_VOL', and '$CONFIG_SYNC_VOL' volumes..."

    $SSH_CMD "docker run --rm \
        -v ${DATA_VOL}:/data \
        -v ${PUBLIC_VOL}:/public \
        -v ${CONFIG_SYNC_VOL}:/config_sync \
        -v /tmp:/_backup alpine \
        sh -c 'tar -czf /_backup/data.tar.gz -C / data && \
               tar -czf /_backup/public.tar.gz -C / public && \
               tar -czf /_backup/config_sync.tar.gz -C / config_sync'"

    echo "Downloading backups to local machine..."
    scp "$REMOTE_USER@$REMOTE_HOST:/tmp/data.tar.gz" "$BACKUP_DIR/data.tar.gz"
    scp "$REMOTE_USER@$REMOTE_HOST:/tmp/public.tar.gz" "$BACKUP_DIR/public.tar.gz"
    scp "$REMOTE_USER@$REMOTE_HOST:/tmp/config_sync.tar.gz" "$BACKUP_DIR/config_sync.tar.gz"

    echo "Cleaning up temporary files on server..."
    $SSH_CMD "rm /tmp/data.tar.gz /tmp/public.tar.gz /tmp/config_sync.tar.gz"

    echo "Backup completed."
}

# Function to restore volumes
restore_volumes() {
    echo "Restoring '$DATA_VOL', '$PUBLIC_VOL', and '$CONFIG_SYNC_VOL' volumes..."

    if [[ ! -f "$BACKUP_DIR/data.tar.gz" || ! -f "$BACKUP_DIR/public.tar.gz" || ! -f "$BACKUP_DIR/config_sync.tar.gz" ]]; then
        echo "Backup files not found in $BACKUP_DIR. Please ensure backups exist."
        return
    fi

    stop_containers

    echo "Uploading backups to the server..."
    scp "$BACKUP_DIR/data.tar.gz" "$REMOTE_USER@$REMOTE_HOST:/tmp/data.tar.gz"
    scp "$BACKUP_DIR/public.tar.gz" "$REMOTE_USER@$REMOTE_HOST:/tmp/public.tar.gz"
    scp "$BACKUP_DIR/config_sync.tar.gz" "$REMOTE_USER@$REMOTE_HOST:/tmp/config_sync.tar.gz"

    echo "Restoring volumes on the server..."
    $SSH_CMD "docker run --rm -v ${DATA_VOL}:/data -v /tmp:/_backup alpine \
        sh -c 'rm -rf /data/* && tar -xzf /_backup/data.tar.gz -C /'; \
        docker run --rm -v ${PUBLIC_VOL}:/public -v /tmp:/_backup alpine \
        sh -c 'rm -rf /public/* && tar -xzf /_backup/public.tar.gz -C /'; \
        docker run --rm -v ${CONFIG_SYNC_VOL}:/config_sync -v /tmp:/_backup alpine \
        sh -c 'rm -rf /config_sync/* && tar -xzf /_backup/config_sync.tar.gz -C /'; \
        rm /tmp/data.tar.gz /tmp/public.tar.gz /tmp/config_sync.tar.gz"

    start_containers

    echo "Restore completed."
}

# Main menu
while true; do
    echo "Select an option:"
    echo "1) Backup volumes"
    echo "2) Restore volumes"
    echo "3) Exit"
    read -rp "Enter your choice: " choice

    case $choice in
        1)
            _backup_volumes
            ;;
        2)
            restore_volumes
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
    echo ""
done
