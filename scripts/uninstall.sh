#!/usr/bin/env bash
# ==============================================================================
# Netra — Uninstallation Script
# Removes Netra Daemon, services, polkit policies, and desktop applications.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this uninstallation script as root (e.g. sudo ./scripts/uninstall.sh)"
    exit 1
fi

echo "=================================================="
echo "  🗑️ Netra: System Uninstallation"
echo "=================================================="

echo "🛑 Stopping and disabling netra-daemon.service..."
systemctl stop netra-daemon.service 2>/dev/null || true
systemctl disable netra-daemon.service 2>/dev/null || true

echo "🧹 Removing files..."
rm -f /usr/local/bin/netrad
rm -f /usr/local/bin/netra-desktop
rm -rf /opt/netra
rm -f /etc/systemd/system/netra-daemon.service
rm -f /usr/share/dbus-1/system.d/org.netra.Control.conf
rm -f /usr/share/polkit-1/actions/org.netra.policy
rm -f /usr/share/applications/netra.desktop
rm -f /usr/share/icons/hicolor/scalable/apps/netra.svg

echo "🔄 Reloading system daemons..."
systemctl daemon-reload

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi

echo "=================================================="
echo "  ✓ Netra has been completely removed from system."
echo "=================================================="
