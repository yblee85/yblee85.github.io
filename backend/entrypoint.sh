#!/usr/bin/env sh
set -eu

# Load local .env only for manual host runs (e.g. `sh entrypoint.sh`).
# Inside Docker, compose-provided env vars should be authoritative.
if [ -f ".env" ] && [ ! -f "/.dockerenv" ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

DATA_DIR="${ABOUTME_DATA_DIR_PATH:-./external_example/data}"
REPO_NAME="${ABOUTME_DATA_GITHUB_REPO_NAME:-}"
TOKEN="${GITHUB_ACCESS_TOKEN:-}"
BRANCH="${ABOUTME_DATA_GITHUB_BRANCH:-main}"
EMBEDDING_BASE_URL="${EMBEDDING_BASE_URL:-http://localhost:8080}"
EMBEDDING_STARTUP_TIMEOUT_SECS="${EMBEDDING_STARTUP_TIMEOUT_SECS:-120}"
EMBEDDING_PROVIDER="${EMBEDDING_PROVIDER:-tei}"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
sh "${SCRIPT_DIR}/script/sync_portfolio_data.sh"

if [ "$EMBEDDING_PROVIDER" = "tei" ]; then
  # Wait until embeddings service is reachable before booting app.
  echo "[startup] Waiting for embeddings service: ${EMBEDDING_BASE_URL}"
  health_url="${EMBEDDING_BASE_URL%/}/health"
  start_ts="$(date +%s)"
  while :; do
    if curl -fsS "$health_url" >/dev/null 2>&1; then
      echo "[startup] Embeddings service is ready"
      break
    fi

    now_ts="$(date +%s)"
    elapsed=$((now_ts - start_ts))
    if [ "$elapsed" -ge "$EMBEDDING_STARTUP_TIMEOUT_SECS" ]; then
      echo "[startup] ERROR: Embeddings service did not become ready within ${EMBEDDING_STARTUP_TIMEOUT_SECS}s"
      exit 1
    fi
    sleep 2
  done
else
  echo "[startup] Skipping local embeddings wait (EMBEDDING_PROVIDER=${EMBEDDING_PROVIDER})"
fi

PORT="${PORT:-3000}"
exec bundle exec puma -C /dev/null -b "tcp://0.0.0.0:${PORT}" config.ru
