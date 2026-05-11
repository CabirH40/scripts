#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/root/script"

log() { echo "[$(date '+%F %T')] $*"; }
warn() { echo "[$(date '+%F %T')] WARN: $*" >&2; }

log "Installing base packages (jq, curl, wget)..."
apt-get update -y
apt-get install -y jq curl wget

mkdir -p "$SCRIPT_DIR"

# Ordered script list and source URLs.
declare -A scripts=(
  [web_sayfa_hmnd.sh]="https://github.com/CabirH40/script.sh/raw/main/web_sayfa_hmnd.sh"
  [whatsbotPythonayarlar.sh]="https://github.com/CabirH40/script.sh/raw/main/whatsbotPythonayarlar.sh"
  [check_process-humanode2.sh]="https://github.com/CabirH40/script.sh/raw/main/check_process-humanode2.sh"
  [get_auth_url.sh]="https://github.com/CabirH40/script.sh/raw/main/get_auth_url.sh"
  [script.sh]="https://github.com/CabirH40/script.sh/raw/main/script2.sh"
  [whatsbot2.sh]="https://github.com/CabirH40/script.sh/raw/main/whatsbot2.sh"
)

ORDER=(
  web_sayfa_hmnd.sh
  whatsbotPythonayarlar.sh
  check_process-humanode2.sh
  get_auth_url.sh
  script.sh
  whatsbot2.sh
)

FAILED_SCRIPTS=()

run_script_in_order() {
  local name="$1"
  local url="${scripts[$name]:-}"

  if [[ -z "$url" ]]; then
    warn "No URL configured for $name"
    FAILED_SCRIPTS+=("$name")
    return
  fi

  log "Downloading $name from $url"
  if wget -q -O "$SCRIPT_DIR/$name" "$url"; then
    chmod +x "$SCRIPT_DIR/$name"
    log "Running $SCRIPT_DIR/$name"
    if ! "$SCRIPT_DIR/$name"; then
      warn "$name downloaded but failed during execution"
      FAILED_SCRIPTS+=("$name")
    else
      log "$name finished successfully"
    fi
  else
    warn "Failed to download $name"
    FAILED_SCRIPTS+=("$name")
  fi

  log "Sleeping 15 seconds before next script"
  sleep 15
}

for script in "${ORDER[@]}"; do
  run_script_in_order "$script"
done

log "Updating crontab entries without wiping unrelated jobs"
existing_cron="$(crontab -l 2>/dev/null || true)"
updated_cron="$(
  printf '%s\n' "$existing_cron" \
  | grep -v -F '/root/script/get_auth_url.sh' \
  | grep -v -F '/root/script/script.sh' \
  || true
)"

{
  printf '%s\n' "$updated_cron" | sed '/^[[:space:]]*$/d'
  echo '* * * * * /root/script/get_auth_url.sh'
  echo '*/10 * * * * /root/script/script.sh'
} | crontab -

if [ ${#FAILED_SCRIPTS[@]} -eq 0 ]; then
  log "Installation completed: all scripts ran successfully"
else
  warn "Some scripts failed: ${FAILED_SCRIPTS[*]}"
  exit 1
fi

exit 0
