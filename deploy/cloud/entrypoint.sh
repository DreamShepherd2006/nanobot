#!/bin/bash
# ============================================================================
# nanobot cloud entrypoint.sh
# Platform-aware entrypoint for cloud spaces (HF Spaces, ModelScope, local).
# No multi-agent squad logic — use nanobot-legion overlay for that.
# ============================================================================
set -e

echo "🚀 nanobot cloud entrypoint starting..."

# ── 0. Basic environment ──────────────────────────────────────────
export HOME="/home/nanobot"
export PATH="/home/nanobot/.local/bin:$PATH"
export PYTHONPATH="/app:${PYTHONPATH}"
export PYTHONDONTWRITEBYTECODE=1

# ── 1. Platform detection & setup ─────────────────────────────────
echo "🔍 [Platform] Detecting cloud platform..."
eval "$(python3 /app/deploy/cloud/platform_setup.py)"
echo "✅ [Platform] Running on: ${DEPLOY_PLATFORM:-unknown}"

# ── 2. Storage-first: seed → persistent ───────────────────────────
DATA_ROOT="${DATA_ROOT:-/data}"
echo "📂 [Storage] data_root = $DATA_ROOT"

# Copy seed instances to persistent storage on first run
PERSIST_INSTANCES="$DATA_ROOT/instances"
SEED_INSTANCES="/app/seed/instances"
if [ -d "$SEED_INSTANCES" ] && [ ! -d "$PERSIST_INSTANCES/_template" ]; then
    echo "📋 [Storage] First run — seeding instances to $PERSIST_INSTANCES"
    mkdir -p "$PERSIST_INSTANCES"
    cp -r "$SEED_INSTANCES"/* "$PERSIST_INSTANCES/"
fi

# Link persistent storage to nanobot's expected path
DIR="$HOME/.nanobot"
mkdir -p "$DIR"
if [ -d "$DATA_ROOT" ]; then
    mkdir -p "$DATA_ROOT/instances"
    ln -sfn "$DATA_ROOT/instances" "$DIR/instances"
    echo "✅ [Storage] Linked $DATA_ROOT/instances → $DIR/instances"
fi

# ── 3. Launch nanobot ─────────────────────────────────────────────
echo "🟢 Starting nanobot..."
exec nanobot run
