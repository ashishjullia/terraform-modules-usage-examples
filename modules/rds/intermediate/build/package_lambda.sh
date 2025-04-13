#!/bin/bash
# Exit script on any error, unset variable, or pipe failure
set -euo pipefail

# --- Configuration ---
BUILD_DIR="$1"
NODE_VERSION="18"
# NPM_PACKAGES variable is NOT needed when using package-lock.json

# --- Input Validation ---
if [ -z "$BUILD_DIR" ]; then
  echo "Error: Build directory argument is required." >&2
  echo "Usage: $0 <build-directory-path>" >&2
  exit 1
fi

echo "--- Preparing Lambda Package in ${BUILD_DIR} using package-lock.json ---"

echo "[1/4] Ensuring directory exists and changing to it: ${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}" # Change directory *after* ensuring it exists

# --- Ensure required files exist BEFORE running Docker ---
# These should be placed here by the calling process/workflow/git checkout
echo "[2/4] Verifying required source files (index.js, package.json, package-lock.json)..."
if [ ! -f "index.js" ]; then echo "Error: index.js not found in build directory $(pwd)." >&2; exit 1; fi
if [ ! -f "package.json" ]; then echo "Error: package.json not found in build directory $(pwd)." >&2; exit 1; fi
if [ ! -f "package-lock.json" ]; then echo "Error: package-lock.json not found in build directory $(pwd)." >&2; exit 1; fi
echo "Required source files found."

# --- Clean previous node_modules ---
# npm ci often handles this, but being explicit is safer for idempotency
echo "[3/4] Cleaning previous node_modules directory..."
find . -maxdepth 1 -name 'node_modules' -exec rm -rf {} +
echo "Cleanup complete."
# --- End Cleanup ---


echo "[4/4] Running npm ci via Docker (using existing package-lock.json)..."
# Use $(pwd) which is now BUILD_DIR for the volume mount
docker run \
  --platform linux/amd64 \
  --rm \
  --entrypoint "" \
  -v "$(pwd):/app" \
  -w /app \
  "node:${NODE_VERSION}" \
  bash -c "set -e && npm ci && chown -R $(id -u):$(id -g) node_modules"
  # Note: npm ci installs production dependencies by default.
  # Only need to chown node_modules as package*.json shouldn't change.

# --- Verification ---
if [ ! -d "node_modules" ]; then
   echo "Error: node_modules directory not found after npm ci in $(pwd)." >&2
   exit 1
fi
# Specific check for the problematic package
if [ ! -d "node_modules/pg" ]; then
   echo "Error: 'pg' package directory not found in node_modules after npm ci in $(pwd)." >&2
   exit 1
fi
echo "Verification passed: node_modules and 'pg' package exist."


echo "--- Lambda package dependency installation complete."
echo "--- Lambda package preparation finished for ${BUILD_DIR} ---"

exit 0