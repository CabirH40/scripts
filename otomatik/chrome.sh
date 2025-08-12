#!/bin/bash
set -euo pipefail

# ================================
# Chromium (single container) + Host Caddy reverse proxy
# Domain served by host Caddy (no www)
# ================================

DOMAIN="${1:-root1.yusurh2009.uk}"   # تقدر تمرّر الدومين كأول باراميتر
PROFILE_NAME=""
HOMEPAGE_URL="https://www.google.com/"
CHROM_USER="d"
CHROM_PASS="d"

usage() {
  echo "Usage: $0 [domain] [--profile \"Profile 2\"] [--homepage \"https://example.com\"] [--user d] [--pass d]"
}

# ---- Parse optional flags ----
shift $(( $# > 0 ? 1 : 0 )) || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)  PROFILE_NAME="${2:-}"; shift 2;;
    --homepage) HOMEPAGE_URL="${2:-}"; shift 2;;
    --user)     CHROM_USER="${2:-}"; shift 2;;
    --pass)     CHROM_PASS="${2:-}"; shift 2;;
    -h|--help)  usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

echo "[*] Domain: ${DOMAIN}"

# ---- Base packages ----
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates gnupg lsb-release curl jq >/dev/null

# ---- Docker install if missing ----
if ! command -v docker >/dev/null 2>&1; then
  echo "[*] Installing Docker..."
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null
fi

# ---- Compose detection ----
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose"
else
  echo "[*] Installing docker-compose..."
  VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -L "https://github.com/docker/compose/releases/download/${VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  DC="docker-compose"
fi

groupadd docker 2>/dev/null || true
usermod -aG docker "$USER" || true

# ---- DNS sanity check ----
if ! getent ahostsv4 "$DOMAIN" >/dev/null; then
  echo "[!] ${DOMAIN} has no A record. Fix DNS, then re-run."
  exit 1
fi

# ---- Prepare app ----
APP_DIR="$HOME/chromium"
CONF_DIR="$APP_DIR/config"
mkdir -p "$CONF_DIR"
cd "$APP_DIR"

# ---- Build Chromium flags ----
CHROME_FLAGS="--no-first-run --no-default-browser-check"
[[ -n "$PROFILE_NAME" ]] && CHROME_FLAGS="$CHROME_FLAGS --profile-directory=\"${PROFILE_NAME}\""
CHROME_FLAGS="$CHROME_FLAGS ${HOMEPAGE_URL}"

# ---- docker-compose.yaml (Chromium only, loopback ports) ----
cat > docker-compose.yaml <<'YAML'
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=${CHROM_USER}
      - PASSWORD=${CHROM_PASS}
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Istanbul
      - CHROME_CLI=${CHROME_FLAGS}
    volumes:
      - ./config:/config
    ports:
      - "127.0.0.1:3010:3000"
      - "127.0.0.1:3011:3001"
    shm_size: "1gb"
    restart: unless-stopped
YAML

# ---- .env ----
cat > .env <<EOF
CHROME_FLAGS=${CHROME_FLAGS}
CHROM_USER=${CHROM_USER}
CHROM_PASS=${CHROM_PASS}
EOF

chown -R 1000:1000 "$CONF_DIR" || true

echo "[*] Starting Chromium container..."
$DC up -d

# ---- Host Caddy integration ----
if command -v caddy >/dev/null 2>&1; then
  echo "[*] Configuring host Caddy..."
  cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak.$(date +%s) 2>/dev/null || true

  # append (no www)
  cat >> /etc/caddy/Caddyfile <<EOF

# Chromium UI via ${DOMAIN}
${DOMAIN} {
    reverse_proxy 127.0.0.1:3010
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}
EOF

  caddy validate --config /etc/caddy/Caddyfile
  systemctl reload caddy
  echo "[✓] Caddy reloaded. Visit: https://${DOMAIN}"
else
  echo "[!] Host Caddy not found. Install Caddy on host OR proxy with another reverse proxy."
  echo "    Temporary local access: http://127.0.0.1:3010"
fi

echo "[✓] Done. Login: user=${CHROM_USER}  pass=${CHROM_PASS}"
