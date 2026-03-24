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

if [ -n "$REPO_NAME" ] && [ -n "$TOKEN" ]; then
  echo "[startup] Fetching portfolio data from GitHub repo: ${REPO_NAME} (branch: ${BRANCH})"
  TMP_DIR="/tmp/aboutme-data-repo"
  rm -rf "$TMP_DIR"

  AUTH_B64="$(printf "x-access-token:%s" "$TOKEN" | base64 | tr -d '\n')"
  GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git \
    -c credential.helper= \
    -c "http.extraHeader=Authorization: Basic ${AUTH_B64}" \
    clone --depth 1 --branch "$BRANCH" \
    "https://github.com/${REPO_NAME}.git" "$TMP_DIR"

  SRC_DIR="${TMP_DIR}/data"
  if [ ! -d "$SRC_DIR" ]; then
    echo "[startup] ERROR: Expected data dir not found in repo: data/"
    exit 1
  fi

  mkdir -p "$DATA_DIR"
  rm -rf "${DATA_DIR:?}/"*
  cp -R "$SRC_DIR"/. "$DATA_DIR"/
  echo "[startup] Data sync complete -> ${DATA_DIR}"
else
  echo "[startup] GitHub data sync skipped (set GITHUB_ACCESS_TOKEN and ABOUTME_DATA_GITHUB_REPO_NAME to enable)"
fi

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

exec bundle exec puma -C /dev/null -p 3000 config.ru
