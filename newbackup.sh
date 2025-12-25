#!/bin/bash
set -euo pipefail
set -x  # trace

# --- SERVER (active) ---
REMOTE_USER="root"
REMOTE_HOST="172.16.12.91"
REMOTE_PORT=22
PASS='@p00l4z'

# --- Local paths ---
SSH_KEY="/Users/admin/.ssh/id_rsa"
BACKUP_DIR="./_backup"

# --- Volumes (derived from user) ---
DATA_VOL="${REMOTE_USER}_data"
PUBLIC_VOL="${REMOTE_USER}_public"
CONFIG_SYNC_VOL="${REMOTE_USER}_config_sync"

# --- SSH/SCP (password mode) ---
SSH_CMD=(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$REMOTE_PORT" -4 "$REMOTE_USER@$REMOTE_HOST")
SCP_CMD=(sshpass -p "$PASS" scp -P "$REMOTE_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

mkdir -p "$BACKUP_DIR"

# --- Helpers ---
run_remote() { "${SSH_CMD[@]}" 'bash -s'; }  # pipe a script via stdin
compose_down() { "${SSH_CMD[@]}" "docker-compose down" || "${SSH_CMD[@]}" "docker compose down"; }
compose_up() { "${SSH_CMD[@]}" "docker-compose up -d" || "${SSH_CMD[@]}" "docker compose up -d"; }

# --- Connectivity test ---
"${SSH_CMD[@]}" "echo 'SSH OK on $(hostname) -> $REMOTE_HOST'"

# --- Ops ---
stop_containers() {
  echo "Stopping containers..."
  compose_down
}

start_containers() {
  echo "Starting containers..."
  compose_up
}

_backup_volumes() {
  echo "Backing up '${DATA_VOL}', '${PUBLIC_VOL}', '${CONFIG_SYNC_VOL}' on ${REMOTE_HOST}..."

  run_remote <<REMOTE
set -euo pipefail
docker run --rm \
  -v ${DATA_VOL}:/data \
  -v ${PUBLIC_VOL}:/public \
  -v ${CONFIG_SYNC_VOL}:/config_sync \
  -v /tmp:/_backup alpine sh -c '
    set -e
    tar -czf /_backup/data.tar.gz -C / data &&
    tar -czf /_backup/public.tar.gz -C / public &&
    tar -czf /_backup/config_sync.tar.gz -C / config_sync
  '
ls -lh /tmp/data.tar.gz /tmp/public.tar.gz /tmp/config_sync.tar.gz
REMOTE

  echo "Downloading backups..."
  "${SCP_CMD[@]}" "$REMOTE_USER@$REMOTE_HOST:/tmp/data.tar.gz"        "$BACKUP_DIR/data.tar.gz"
  "${SCP_CMD[@]}" "$REMOTE_USER@$REMOTE_HOST:/tmp/public.tar.gz"      "$BACKUP_DIR/public.tar.gz"
  "${SCP_CMD[@]}" "$REMOTE_USER@$REMOTE_HOST:/tmp/config_sync.tar.gz" "$BACKUP_DIR/config_sync.tar.gz"

  echo "Cleaning remote tmp..."
  "${SSH_CMD[@]}" "rm -f /tmp/data.tar.gz /tmp/public.tar.gz /tmp/config_sync.tar.gz"

  echo "Backup done."
}

restore_volumes() {
  echo "Restoring '${DATA_VOL}', '${PUBLIC_VOL}', '${CONFIG_SYNC_VOL}' to ${REMOTE_HOST}..."

  [[ -f "$BACKUP_DIR/data.tar.gz" && -f "$BACKUP_DIR/public.tar.gz" && -f "$BACKUP_DIR/config_sync.tar.gz" ]]

  stop_containers

  echo "Uploading archives..."
  "${SCP_CMD[@]}" "$BACKUP_DIR/data.tar.gz"        "$REMOTE_USER@$REMOTE_HOST:/tmp/data.tar.gz"
  "${SCP_CMD[@]}" "$BACKUP_DIR/public.tar.gz"      "$REMOTE_USER@$REMOTE_HOST:/tmp/public.tar.gz"
  "${SCP_CMD[@]}" "$BACKUP_DIR/config_sync.tar.gz" "$REMOTE_USER@$REMOTE_HOST:/tmp/config_sync.tar.gz"

  echo "Restoring on remote..."
  run_remote <<REMOTE
set -euo pipefail
ls -lh /tmp/data.tar.gz /tmp/public.tar.gz /tmp/config_sync.tar.gz
docker run --rm -v ${DATA_VOL}:/data -v /tmp:/_backup alpine sh -c '
  set -e
  rm -rf /data/* && tar -xzf /_backup/data.tar.gz -C /
'
docker run --rm -v ${PUBLIC_VOL}:/public -v /tmp:/_backup alpine sh -c '
  set -e
  rm -rf /public/* && tar -xzf /_backup/public.tar.gz -C /
'
docker run --rm -v ${CONFIG_SYNC_VOL}:/config_sync -v /tmp:/_backup alpine sh -c '
  set -e
  rm -rf /config_sync/* && tar -xzf /_backup/config_sync.tar.gz -C /
'
rm -f /tmp/data.tar.gz /tmp/public.tar.gz /tmp/config_sync.tar.gz
REMOTE

  start_containers
  echo "Restore done."
}

# --- Menu ---
while true; do
  echo "Select an option:"
  echo "1) Backup volumes"
  echo "2) Restore volumes"
  echo "3) Exit"
  read -rp "Enter your choice: " choice

  case "$choice" in
    1) _backup_volumes ;;
    2) restore_volumes ;;
    3) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid choice. Try again." ;;
  esac
  echo ""
done
