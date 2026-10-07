#!/usr/bin/env bash
# ==============================================================================
# Netra — Development Live Runner
# Runs the Rust backend daemon and Flutter desktop UI side-by-side.
# Gracefully terminates the daemon when the GUI exits.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DAEMON_BIN="${ROOT_DIR}/target/release/netra-daemon"
if [ ! -f "${DAEMON_BIN}" ]; then
    DAEMON_BIN="${ROOT_DIR}/target/debug/netra-daemon"
fi

if [ ! -f "${DAEMON_BIN}" ]; then
    echo "⚙️ Daemon binary not found, building debug binary..."
    cd "${ROOT_DIR}"
    cargo build -p netra-daemon
    DAEMON_BIN="${ROOT_DIR}/target/debug/netra-daemon"
fi

DAEMON_LOG="/tmp/netra-daemon-dev.log"
echo "=================================================="
echo "  ⚡ Launching Netra in Development Mode"
echo "=================================================="
echo "Daemon Binary: ${DAEMON_BIN}"
echo "Daemon Log:    ${DAEMON_LOG}"

# Start daemon in background
export RUST_LOG="info,netra_daemon=debug,netra_network=debug,netra_bluetooth=debug,netra_traffic=debug,netra_audio=debug"
"${DAEMON_BIN}" > "${DAEMON_LOG}" 2>&1 &
DAEMON_PID=$!

cleanup() {
    echo ""
    echo "🛑 Shutting down Netra development session..."
    if kill -0 "${DAEMON_PID}" 2>/dev/null; then
        kill "${DAEMON_PID}" 2>/dev/null || true
        wait "${DAEMON_PID}" 2>/dev/null || true
    fi
    echo "✓ Daemon stopped."
}

trap cleanup EXIT INT TERM

# Wait up to 3 seconds for D-Bus registration
echo "⏳ Waiting for netra-daemon D-Bus interface..."
sleep 0.8

if ! kill -0 "${DAEMON_PID}" 2>/dev/null; then
    echo "❌ Error: Daemon process exited immediately! Check log:"
    cat "${DAEMON_LOG}"
    exit 1
fi

echo "✓ Daemon active (PID: ${DAEMON_PID})"
echo "🚀 Launching Netra Desktop Flutter GUI..."

cd "${ROOT_DIR}/apps/netra_desktop"
flutter run -d linux "$@"
