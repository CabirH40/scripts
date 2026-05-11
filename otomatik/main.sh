#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/root/script"
NODES_DIR_SOURCE="/root/.humanode"

log() { echo "[$(date '+%F %T')] $*"; }

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

if [[ ! -d "$NODES_DIR_SOURCE" ]]; then
  echo "Missing source directory: $NODES_DIR_SOURCE" >&2
  exit 1
fi

# 1) Create users only if they do not already exist.
for i in {1..11}; do
  username="node$i"
  if id -u "$username" >/dev/null 2>&1; then
    log "User $username already exists, skipping creation"
  else
    useradd -m -s /bin/bash "$username"
    echo "$username:4Y8z1eblEJ" | chpasswd
    usermod -aG sudo "$username"
    log "Created user $username and granted sudo"
  fi
done

# 2) Ensure .humanode exists for each user and set ownership.
for i in {1..11}; do
  username="node$i"
  target_dir="/home/$username/.humanode"

  rm -rf "$target_dir"
  cp -r "$NODES_DIR_SOURCE" "$target_dir"
  chown -R "$username:$username" "$target_dir"
  log "Copied .humanode to $target_dir"
done

# 3) Ensure script directory exists.
mkdir -p "$SCRIPT_DIR"
cd "$SCRIPT_DIR"

# 4) Download required scripts with basic failure handling.
urls=(
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/caddy.sh"
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/checkpeer.sh"
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/peer.sh"
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/port-ayar.sh"
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/script.sh"
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/whatsbotservis.sh"
  "https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/configure_nodes.sh"
)

for url in "${urls[@]}"; do
  file_name="$(basename "$url")"
  log "Downloading $file_name"
  curl -fsSL "$url" -o "$file_name"
done

# 5) Run scripts in order.
chmod +x ./*.sh
for script in caddy.sh checkpeer.sh peer.sh port-ayar.sh whatsbotservis.sh configure_nodes.sh; do
  log "Running $script"
  "./$script"
done

log "Completed successfully: users configured, scripts downloaded and executed"
