#!/bin/bash
# ============================================================================
# nanobot cloud entrypoint.sh
# Single entrypoint — routes to squad or plain cloud at startup.
#
#   ☁️  Plain cloud  → detect platform, init storage, launch nanobot
#   🦁 Squad Legion → delegate to deploy/huggingface/launch.sh
#
# Set SQUAD_LEGION=true in Dockerfile for squad deployments.
# ============================================================================
set -e

echo "🚀 nanobot cloud entrypoint starting..."

# ── 0. Basic environment ──────────────────────────────────────────
export HOME="/home/nanobot"
export PATH="/home/nanobot/.local/bin:$PATH"
export PYTHONPATH="/app:${PYTHONPATH}"
export PYTHONDONTWRITEBYTECODE=1

# ── 1. Route to squad if Legion layer present ─────────────────────
if [ -x /app/deploy/huggingface/launch.sh ]; then
    echo "🦁 Squad Legion layer detected — delegating to launch.sh"
    exec /app/deploy/huggingface/launch.sh
fi

# ── 2. Platform detection ─────────────────────────────────────────
echo "🔍 Detecting cloud platform..."
eval "$(python3 /app/deploy/cloud/platform_setup.py)"
echo "✅ Platform: ${DEPLOY_PLATFORM:-unknown}"

# ── 3. First-run config seed ────────────────────────────────────────
DATA_ROOT="${DATA_ROOT:-/data}"
echo "📂 data_root = $DATA_ROOT"

INSTANCE_DIR="$DATA_ROOT/instances/default"
CONFIG_FILE="$INSTANCE_DIR/config.json"
TEMPLATE="/app/deploy/cloud/config.template.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "🆕 First run — creating default config from template"
    mkdir -p "$INSTANCE_DIR" "$INSTANCE_DIR/workspace"
    cp "$TEMPLATE" "$CONFIG_FILE"
    echo "   Customize: edit $CONFIG_FILE then restart"
fi

mkdir -p "$HOME/.nanobot"
ln -sfn "$DATA_ROOT/instances" "$HOME/.nanobot/instances" 2>/dev/null || true
echo "✅ Storage linked"

# ── 4. Launch ─────────────────────────────────────────────────────
echo "☁️  Starting nanobot gateway..."
exec nanobot gateway --config "$CONFIG_FILE" --workspace "$DATA_ROOT/instances" --port 7860
