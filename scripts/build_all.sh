#!/usr/bin/env bash
# ==============================================================================
# Netra — Full Project Build Script
# Compiles the Rust backend daemon and the Flutter Desktop Linux GUI.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=================================================="
echo "  🚀 Netra: Building Full Production Release"
echo "=================================================="
echo "Root directory: ${ROOT_DIR}"

# 1. Check prerequisites
echo ""
echo "[1/4] Checking build tools..."
command -v cargo >/dev/null 2>&1 || { echo "❌ cargo is required but not installed."; exit 1; }
command -v rustc >/dev/null 2>&1 || { echo "❌ rustc is required but not installed."; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "❌ flutter is required but not installed."; exit 1; }
command -v clang >/dev/null 2>&1 || { echo "❌ clang is required but not installed."; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo "❌ cmake is required but not installed."; exit 1; }
command -v ninja >/dev/null 2>&1 || { echo "❌ ninja is required but not installed."; exit 1; }
echo "✓ All compiler toolchains detected."

# 2. Build Rust Daemon
echo ""
echo "[2/4] Compiling Rust backend workspace (release mode)..."
cd "${ROOT_DIR}"
cargo build --release --workspace

if [ ! -f "${ROOT_DIR}/target/release/netra-daemon" ]; then
    echo "❌ Build failed: target/release/netra-daemon not found."
    exit 1
fi
echo "✓ Rust daemon built: target/release/netra-daemon ($(ls -lh target/release/netra-daemon | awk '{print $5}'))"

# 3. Build Flutter Desktop Application
echo ""
echo "[3/4] Compiling Flutter Linux desktop bundle (release mode)..."
cd "${ROOT_DIR}/apps/netra_desktop"
flutter pub get
flutter build linux --release

BUNDLE_DIR="${ROOT_DIR}/apps/netra_desktop/build/linux/x64/release/bundle"
if [ ! -f "${BUNDLE_DIR}/netra_desktop" ]; then
    echo "❌ Flutter build failed: ${BUNDLE_DIR}/netra_desktop not found."
    exit 1
fi
echo "✓ Flutter desktop bundle built successfully in ${BUNDLE_DIR}"

# 4. Summary
echo ""
echo "[4/4] Build complete!"
echo "=================================================="
echo "Artifacts generated:"
echo "  1. Backend Daemon: ${ROOT_DIR}/target/release/netra-daemon"
echo "  2. Desktop Client: ${BUNDLE_DIR}/netra_desktop"
echo "=================================================="
echo "To test locally without installing:  ./scripts/run_dev.sh"
echo "To install system-wide to Linux:     sudo ./scripts/install.sh"
echo "=================================================="
