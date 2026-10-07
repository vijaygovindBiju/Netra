# Netra (नेत्र) 👁️
### Unified Linux Connectivity & Audio Control Center

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(Wayland%20%2F%20X11)-orange.svg)]()
[![Backend: Rust](https://img.shields.io/badge/Backend-Rust%202021-red.svg)](https://www.rust-lang.org/)
[![Frontend: Flutter](https://img.shields.io/badge/Frontend-Flutter%20Desktop-02569B.svg)](https://flutter.dev/)
[![Audio: PipeWire](https://img.shields.io/badge/Audio-PipeWire%20%2B%20WirePlumber-brightgreen.svg)](https://pipewire.org/)

**Netra** is a modern Linux desktop application that unifies Wi-Fi, Hotspot/Tethering, Bluetooth, Audio routing, Network monitoring, and Device management into one clean, responsive, and visual interface.

No more switching between `nmcli`, `blueman`, `pavucontrol`, `qpwgraph`, `nethogs`, and arcane terminal commands.

---

## 🌟 Key Features

| Module | Features |
|---|---|
| **🌐 Network Dashboard** | • Real-time Wi-Fi scanning with RSSI signal meters & band detection (2.4/5/6 GHz)<br/>• Live upload/download bandwidth graph with microsecond polling<br/>• Network interface telemetry (IP, Gateway, DNS, MTU, packet drop diagnostics)<br/>• Connection history & captive portal alerts |
| **🔥 Smart Hotspot** | • One-click Wi-Fi hotspot creation with 2.4 GHz / 5 GHz band switching<br/>• Real-time connected client list with MAC, IP, hostname & device manufacturer<br/>• Per-client live data usage counters and bandwidth rates<br/>• **Smart QoS Priorities:** High (gaming/calls), Medium (streaming), Low (downloads)<br/>• Per-device download/upload speed limits |
| **📊 Per-App Network Usage** | • Real-time per-process upload and download bandwidth tracking<br/>• Historical data usage metrics by executable and desktop app name<br/>• Network task manager view: kill, throttle, or prioritize application sockets |
| **🎧 Multi-Bluetooth Audio** | • **Simultaneous Dual/Multi-Audio:** Stream the same audio to multiple Bluetooth headphones or speakers in sync<br/>• Independent per-device volume, codec (LDAC, aptX, AAC, SBC), and latency compensation<br/>• Device Audio Groups (e.g., "Living Room Group" or "Silent Disco") |
| **🎛️ PipeWire Audio Routing** | • Visual audio routing matrix without the complexity of graph patching<br/>• Per-app routing: send Spotify to speakers, Discord to headset, and games to both<br/>• Smart auto-switching: automatically move voice communications when a headset connects |
| **📶 Bluetooth Control Center** | • Unified pairing, connection, and trust management for Classic & BLE devices<br/>• Battery level reporting via BlueZ Battery1 and BLE GATT services<br/>• Auto-reconnect engine with presence detection |

---

## 🏗️ System Architecture

Netra uses a secure **privileged daemon + unprivileged UI** architecture:

```
┌────────────────────────────────────────────────────────┐
│               Netra Flutter Desktop UI                 │
│         (Responsive, Modern Linux Desktop App)         │
└───────────────────────────┬────────────────────────────┘
                            │ System D-Bus / Polkit
                            ▼
┌────────────────────────────────────────────────────────┐
│                 netra-daemon (Rust)                    │
│    (CAP_NET_ADMIN / System Service with Tokio Core)    │
├──────────────┬──────────────┬──────────────┬───────────┤
│ Network Mgr  │ Hotspot & QoS│ Bluetooth    │ PipeWire  │
│ Controller   │ Engine (tc)  │ Orchestrator │ Audio Hub │
└──────┬───────┴──────┬───────┴──────┬───────┴─────┬─────┘
       │              │              │             │
       ▼              ▼              ▼             ▼
  NetworkManager   Linux TC/       BlueZ 5.x    PipeWire /
  & Netlink        nftables        & BLE GATT   WirePlumber
```

---

## 📚 Detailed Documentation

Comprehensive architectural and engineering documentation is available in the [`docs/`](docs/) directory:

- 📑 [**Project Planning & Roadmap**](docs/PLANNING.md) — Detailed specifications, milestones, phases, and user stories.
- 🚀 [**Phase 1 (MVP) Implementation Plan**](docs/PHASE1_MVP_IMPLEMENTATION.md) — Step-by-step engineering blueprint and acceptance criteria for MVP.
- 🏛️ [**System Architecture**](docs/ARCHITECTURE.md) — Deep dive into daemon design, PipeWire graph management, and Netlink socket tracking.
- 📁 [**File & Project Structure**](docs/FILE_STRUCTURE.md) — Monorepo workspace organization, Rust crate layouts, and Flutter project structure.
- 🛡️ [**Security Architecture**](docs/SECURITY.md) — Polkit rules, Linux capabilities, privilege separation, and threat modeling.
- 🔌 [**D-Bus & IPC API Specifications**](docs/API_AND_DBUS.md) — Complete D-Bus interface contracts, method signatures, properties, and signals.

---

## 🚀 Quick Start (Development)

### Prerequisites

- **Linux Distribution:** Arch Linux, Fedora 38+, Ubuntu 22.04+, or Debian 12+
- **System Services:** `systemd`, `NetworkManager` (>= 1.30), `bluez` (>= 5.60), `pipewire` (>= 0.3.50), `wireplumber`
- **Build Tools:**
  - Rust 1.75+ (`cargo`, `rustc`)
  - Flutter SDK 3.19+ with Linux Desktop support enabled (`flutter config --enable-linux-desktop`)
  - `clang`, `pkg-config`, `libdbus-1-dev`, `libpipewire-0.3-dev`, `libclang-dev`

### Cloning and Building

```bash
# Clone the repository
git clone https://github.com/netra-linux/netra.git
cd netra

# One-command full build (Daemon + Desktop GUI)
./scripts/build_all.sh

# Run locally in development mode (starts daemon + UI side-by-side)
./scripts/run_dev.sh

# Install system-wide with systemd, Polkit, and D-Bus policies
sudo ./scripts/install.sh
```

### Packaging

- **Arch Linux:**
  ```bash
  cd packaging/archlinux
  makepkg -si
  ```
- **Debian / Ubuntu:**
  ```bash
  dpkg-buildpackage -us -uc -b
  ```

---

## 🗺️ Implementation Status

- [x] **Phase 0: Blueprints & Specifications** — Complete architecture, IPC contracts, Polkit policies, and threat model.
- [x] **Phase 1: MVP Core Networking** — NetworkManager D-Bus scanner, AP hotspot tethering, ARP/DHCP client discovery, and live bandwidth monitor.
- [x] **Phase 2: Bluetooth Orchestrator** — BlueZ 5.x pairing/trust/connect engine, BLE support, and battery telemetry.
- [x] **Phase 3: Traffic Analytics & Smart QoS** — `/proc` socket-to-process correlation, sub-second bandwidth tracker, and Linux Traffic Control (`tc`/`HTB`) bandwidth shaping.
- [x] **Phase 4: PipeWire Multi-Sink Audio Hub** — Sink & stream discovery, per-application matrix routing, per-sink latency compensation (±100ms), and synchronized multi-Bluetooth playback groups (`module-combine-sink`).
- [x] **Packaging & Deployment** — Arch Linux PKGBUILD, Debian packaging, XDG desktop entry, high-res scalable SVG icon, and automated installer/uninstaller scripts.

---

## 📄 License

Licensed under the [MIT License](LICENSE).
