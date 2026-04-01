#!/usr/bin/env sh
set -eu

DATA_DIR="${ABOUTME_DATA_DIR_PATH:-./external_example/data}"
REPO_NAME="${ABOUTME_DATA_GITHUB_REPO_NAME:-}"
TOKEN="${GITHUB_ACCESS_TOKEN:-}"
BRANCH="${ABOUTME_DATA_GITHUB_BRANCH:-main}"

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

