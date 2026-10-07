#!/usr/bin/env bash
# ==============================================================================
# Netra — System Installation Script
# Installs Netra Daemon and Desktop UI to Linux system directories with
# systemd, D-Bus system bus policies, Polkit rules, and desktop launcher.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this installation script as root (e.g. sudo ./scripts/install.sh)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=================================================="
echo "  📦 Netra: System-wide Linux Installation"
echo "=================================================="
echo "Repository Root: ${ROOT_DIR}"

DAEMON_BIN="${ROOT_DIR}/target/release/netra-daemon"
BUNDLE_DIR="${ROOT_DIR}/apps/netra_desktop/build/linux/x64/release/bundle"

# 1. Verify Binaries
if [ ! -f "${DAEMON_BIN}" ] || [ ! -f "${BUNDLE_DIR}/netra_desktop" ]; then
    echo "⚙️ Building missing release artifacts..."
    sudo -u "${SUDO_USER:-$USER}" "${ROOT_DIR}/scripts/build_all.sh"
fi

echo ""
echo "[1/6] Installing backend daemon (netrad)..."
install -d /usr/local/bin
install -m 755 "${DAEMON_BIN}" /usr/local/bin/netrad

echo "[2/6] Installing D-Bus system bus configuration..."
install -d /usr/share/dbus-1/system.d
install -m 644 "${ROOT_DIR}/data/dbus/org.netra.Control.conf" /usr/share/dbus-1/system.d/org.netra.Control.conf

echo "[3/6] Installing Polkit security policy..."
install -d /usr/share/polkit-1/actions
install -m 644 "${ROOT_DIR}/data/polkit/org.netra.policy" /usr/share/polkit-1/actions/org.netra.policy

echo "[4/6] Installing systemd daemon service..."
install -d /etc/systemd/system
install -m 644 "${ROOT_DIR}/data/systemd/netra-daemon.service" /etc/systemd/system/netra-daemon.service

echo "[5/6] Installing Flutter Desktop GUI to /opt/netra..."
rm -rf /opt/netra
install -d /opt/netra
cp -r "${BUNDLE_DIR}/"* /opt/netra/
chmod 755 /opt/netra/netra_desktop

# Create wrapper script for easy terminal invocation
cat << 'EOF' > /usr/local/bin/netra-desktop
#!/usr/bin/env bash
exec /opt/netra/netra_desktop "$@"
EOF
chmod 755 /usr/local/bin/netra-desktop

echo "[6/6] Installing desktop launcher & application icons..."
install -d /usr/share/applications
install -m 644 "${ROOT_DIR}/data/desktop/netra.desktop" /usr/share/applications/netra.desktop

install -d /usr/share/icons/hicolor/scalable/apps
install -m 644 "${ROOT_DIR}/data/icons/hicolor/scalable/apps/netra.svg" /usr/share/icons/hicolor/scalable/apps/netra.svg

# Reload systemd and D-Bus services
echo ""
echo "🔄 Reloading system services..."
systemctl daemon-reload
systemctl enable --now netra-daemon.service || true

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi

echo ""
echo "=================================================="
echo "  ✅ Netra Successfully Installed!"
echo "=================================================="
echo "  • Daemon Service:  systemctl status netra-daemon"
echo "  • Daemon Binary:   /usr/local/bin/netrad"
echo "  • GUI App Path:    /opt/netra/netra_desktop"
echo "  • CLI Launcher:    netra-desktop"
echo "  • Desktop Icon:    Available in your Application Menu"
echo "=================================================="
