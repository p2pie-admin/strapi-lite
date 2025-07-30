#!/bin/bash
eval "$(ssh-agent -s)"
ssh-add /Users/admin/.ssh/id_rsa
# Remote server details
REMOTE_USER="strapi"
REMOTE_HOST="10.0.0.191"
REMOTE_PATH="/"
BACKUP_DIR="./_backup"

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

# Function to _backup volumes
_backup_volumes() {
    echo "Backing up 'strapi_data' and 'strapi_public' volumes..."

    $SSH_CMD "docker run --rm -v strapi_data:/data -v strapi_public:/public -v /tmp:/_backup alpine \
        sh -c 'tar -czf /_backup/data.tar.gz -C / data && tar -czf /_backup/public.tar.gz -C / public'"

    echo "Downloading _backups to local machine..."
    scp "$REMOTE_USER@$REMOTE_HOST:/tmp/data.tar.gz" "$BACKUP_DIR/data.tar.gz"
    scp "$REMOTE_USER@$REMOTE_HOST:/tmp/public.tar.gz" "$BACKUP_DIR/public.tar.gz"

    echo "Cleaning up temporary files on server..."
    $SSH_CMD "rm /tmp/data.tar.gz /tmp/public.tar.gz"

    echo "Backup completed."
}

# Function to restore volumes
restore_volumes() {
    echo "Restoring 'strapi_data' and 'strapi_public' volumes..."

    if [[ ! -f "$BACKUP_DIR/data.tar.gz" || ! -f "$BACKUP_DIR/public.tar.gz" ]]; then
        echo "Backup files not found in $BACKUP_DIR. Please ensure _backups exist."
        return
    fi

    stop_containers

    echo "Uploading _backups to the server..."
    scp "$BACKUP_DIR/data.tar.gz" "$REMOTE_USER@$REMOTE_HOST:/tmp/data.tar.gz"
    scp "$BACKUP_DIR/public.tar.gz" "$REMOTE_USER@$REMOTE_HOST:/tmp/public.tar.gz"

    echo "Restoring volumes on the server..."
    $SSH_CMD "docker run --rm -v strapi_data:/data -v /tmp:/_backup alpine \
        sh -c 'rm -rf /data/* && tar -xzf /_backup/data.tar.gz -C /'; \
        docker run --rm -v strapi_public:/public -v /tmp:/_backup alpine \
        sh -c 'rm -rf /public/* && tar -xzf /_backup/public.tar.gz -C /'; \
        rm /tmp/data.tar.gz /tmp/public.tar.gz"

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
