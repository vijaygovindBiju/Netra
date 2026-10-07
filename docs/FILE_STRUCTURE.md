# Netra — Project File & Directory Structure

> **Document Version:** 1.0.0  
> **Status:** Directory Structure Specification  
> **Pattern:** Cargo Workspaces Monorepo + Flutter Desktop Application  

---

## 1. Top-Level Repository Overview

Netra is organized as a unified monorepo containing both the Rust backend daemon crates and the Flutter desktop client application.

```
netra/
├── .github/                      # CI/CD Workflows, GitHub Actions, Issue Templates
│   └── workflows/
│       ├── ci.yml                # Cargo test, clippy, flutter test, formatting checks
│       └── release.yml           # Multi-distro build (PKGBUILD, Flatpak, Deb, AppImage)
├── apps/                         # Desktop User Interface Applications
│   └── netra_desktop/            # Modern Flutter Desktop Client (Linux)
├── crates/                       # Modular Rust Backend Crates (Cargo Workspace)
│   ├── netra-common/             # Shared data models, protocol types, serialization
│   ├── netra-network/            # NetworkManager, Wi-Fi scanner, Hotspot & QoS (tc)
│   ├── netra-bluetooth/          # BlueZ 5.x D-Bus orchestrator & BLE GATT client
│   ├── netra-audio/              # PipeWire native audio graph & multi-sink engine
│   ├── netra-traffic/            # Netlink sock_diag process socket & bandwidth tracker
│   ├── netra-client/             # D-Bus & IPC client bindings for frontend communication
│   └── netra-daemon/             # Main executable daemon (netrad) with Polkit security
├── data/                         # Linux System Integration Files
│   ├── dbus/                     # D-Bus service & security configuration files
│   ├── polkit/                   # Polkit privilege authorization policies (.policy)
│   ├── systemd/                  # Systemd service unit files (.service)
│   ├── icons/                    # App icons (SVG, PNG: 16x16 up to 512x512)
│   └── desktop/                  # XDG Desktop Entry file (org.netra.Netra.desktop)
├── packaging/                    # Distribution-Specific Packaging Recipes
│   ├── arch/                     # Arch Linux PKGBUILD & AUR scripts
│   ├── flatpak/                  # Flatpak manifest (org.netra.Netra.yaml)
│   └── debian/                   # Debian/Ubuntu control, rules, and changelog
├── docs/                         # Comprehensive Engineering Documentation
│   ├── PLANNING.md               # Product Roadmap & Requirements Document
│   ├── ARCHITECTURE.md           # Systems Architecture & Deep Subsystem Design
│   ├── FILE_STRUCTURE.md         # Repository Layout & Crate Boundaries (This file)
│   ├── SECURITY.md               # Privilege Separation, Polkit, & Threat Model
│   └── API_AND_DBUS.md           # D-Bus Interface Specifications & Wire Protocol
├── scripts/                      # Developer Helper Scripts & Environment Setup
│   ├── setup_dev_env.sh          # Installs dependencies on Arch/Ubuntu/Fedora
│   └── generate_dbus_codegen.sh  # Generates Rust D-Bus bindings from XML interfaces
├── Cargo.toml                    # Root Cargo Workspace definition
├── Cargo.lock                    # Rust dependency lockfile
├── LICENSE                       # MIT Open Source License
└── README.md                     # Project Overview, Badges, and Quick Start Guide
```

---

## 2. Flutter Desktop Application (`apps/netra_desktop/`)

The desktop client is constructed using Flutter for Linux, following the Riverpod architecture pattern with clean separation of presentation, domain, and data layers.

```
apps/netra_desktop/
├── linux/                        # Native Linux Runner & CMake Configuration
│   ├── CMakeLists.txt            # CMake build configuration for Linux desktop
│   ├── my_application.cc         # C++ application entry point (GTK header)
│   └── packaging/                # Linux runner assets
├── lib/                          # Flutter Dart Source Code
│   ├── main.dart                 # Application entry point, theme & provider scope
│   ├── app.dart                  # Root MaterialApp with routing and window chrome
│   ├── core/                     # Core application infrastructure
│   │   ├── constants/            # UI constants, route names, icon assets
│   │   ├── theme/                # Cyber-sleek dark theme, colors, typography
│   │   ├── utils/                # Formatters (bytes to MB/GB, speed, duration)
│   │   └── ipc/                  # Low-level D-Bus / Unix socket IPC bridge
│   ├── features/                 # Modular Feature Slices
│   │   ├── dashboard/            # Unified Overview Dashboard
│   │   │   ├── presentation/     # Overview widgets, quick-toggle status cards
│   │   │   └── providers/        # Combined system state riverpod providers
│   │   ├── network/              # Wi-Fi & Ethernet Module
│   │   │   ├── models/           # AccessPoint, InterfaceStats, NetworkProfile
│   │   │   ├── presentation/     # Wi-Fi list, signal graphs, IP details widget
│   │   │   └── providers/        # NetworkStateNotifier, scan stream providers
│   │   ├── hotspot/              # Smart Hotspot & QoS Module
│   │   │   ├── models/           # HotspotConfig, ConnectedClient, QoSPriority
│   │   │   ├── presentation/     # Hotspot toggle, client table, priority badges
│   │   │   └── providers/        # HotspotController, client bandwidth notifier
│   │   ├── bluetooth/            # Bluetooth Control Center
│   │   │   ├── models/           # BluetoothDevice, BatteryInfo, AudioCodec
│   │   │   ├── presentation/     # Device cards, pairing dialog, codec selector
│   │   │   └── providers/        # BluetoothDeviceListNotifier, scan provider
│   │   ├── audio/                # PipeWire Audio Routing & Multi-Sink Module
│   │   │   ├── models/           # AudioNode, AudioPort, VirtualSink, AppStream
│   │   │   ├── presentation/     # Visual routing matrix, dual-sink sync panel, sliders
│   │   │   └── providers/        # PipeWireGraphNotifier, multiSinkController
│   │   └── traffic/              # Per-App Bandwidth & Process Tracker
│   │       ├── models/           # ProcessTrafficEntry, SocketEndpoint
│   │       ├── presentation/     # Live network task manager, speed charts
│   │       └── providers/        # TrafficRateStreamNotifier
│   └── shared/                   # Shared Reusable UI Widgets
│       ├── widgets/              # Gauges, speed charts, custom buttons, modals
│       └── layout/               # Sidebar navigation, titlebar, glassmorphic cards
├── test/                         # Flutter Unit & Widget Tests
└── pubspec.yaml                  # Dart dependencies (flutter_riverpod, dbus, fl_chart)
```

---

## 3. Rust Backend Crates (`crates/`)

The backend is decomposed into specialized crates to enforce clean API boundaries, ensure fast incremental compilation, and allow independent unit testing.

```
crates/
├── netra-common/                 # Shared Data Models & IPC Protocols
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── models/               # Shared struct definitions (serde Serialize/Deserialize)
│       │   ├── network.rs        # InterfaceInfo, WifiAP, IpConfig
│       │   ├── hotspot.rs        # HotspotStatus, ClientDevice, QosClass
│       │   ├── bluetooth.rs      # BtDevice, BtBattery, AudioProfile
│       │   ├── audio.rs          # SinkInfo, StreamRoute, VirtualGroup
│       │   └── traffic.rs        # AppTrafficStat, SocketMetric
│       └── error.rs              # Unified NetraError enum across crates
│
├── netra-network/                # NetworkManager, Wi-Fi & Hotspot QoS
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── manager.rs            # NetworkManager D-Bus proxy & event listener
│       ├── wifi.rs               # Wi-Fi scanner, connect/disconnect, RSSI tracking
│       ├── hotspot.rs            # AP mode creation, band (2.4/5GHz) selection
│       ├── dhcp_leases.rs        # DHCP leases file parser & inotify watcher
│       ├── neighbor.rs           # Kernel neighbor table (ARP) via rtnetlink
│       └── qos/                  # Linux Traffic Control (tc) engine
│           ├── mod.rs
│           ├── htb.rs            # Hierarchical Token Bucket qdisc builder
│           └── filters.rs        # IP-based u32 classifier filters
│
├── netra-bluetooth/              # BlueZ 5.x D-Bus Orchestrator
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── adapter.rs            # BlueZ Adapter1 proxy (Discovery, Power, Pairable)
│       ├── device.rs             # Device1 proxy (Connect, Pair, Trust, RSSI)
│       ├── battery.rs            # Battery1 & BLE GATT battery level parser
│       ├── agent.rs              # BlueZ Pairing Agent implementation (PIN/Passkey)
│       └── profiles.rs           # A2DP / HFP / HSP profile negotiation tracking
│
├── netra-audio/                  # PipeWire Native Audio Engine
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── context.rs            # PipeWire Core & Context lifecycle
│       ├── graph.rs              # Registry listener: tracking nodes, ports, links
│       ├── virtual_sink.rs       # Dynamic combine-sink / loopback node generator
│       ├── routing.rs            # Per-app stream port linking & auto-switching
│       ├── sync.rs               # Clock synchronization & latency delay compensation
│       └── volume.rs             # SPA audio props volume and mute controls
│
├── netra-traffic/                # Netlink sock_diag & Process Tracker
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── netlink_diag.rs       # NETLINK_INET_DIAG socket dumper
│       ├── procfs_scanner.rs     # Inode-to-PID /proc/[pid]/fd scanner
│       ├── process_meta.rs       # Resolves executable name, icon, and cmdline
│       └── rate_engine.rs        # Differential bandwidth calculator (RX/TX bytes/sec)
│
├── netra-client/                 # Client Library for D-Bus & IPC
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── dbus_client.rs        # Strongly-typed zbus proxy for org.netra.Control
│       └── socket_stream.rs      # High-throughput Unix socket telemetry reader
│
└── netra-daemon/                 # Main System Executable (netrad)
    ├── Cargo.toml
    └── src/
        ├── main.rs               # Entry point, CLI args, logger init
        ├── service.rs            # Tokio async event loop & graceful shutdown
        ├── polkit.rs             # Polkit authorization authority client
        ├── dbus_server/          # D-Bus interfaces implementation
        │   ├── mod.rs
        │   ├── network_iface.rs  # org.netra.Network implementation
        │   ├── hotspot_iface.rs  # org.netra.Hotspot implementation
        │   ├── bt_iface.rs       # org.netra.Bluetooth implementation
        │   ├── audio_iface.rs    # org.netra.Audio implementation
        │   └── traffic_iface.rs  # org.netra.Traffic implementation
        └── telemetry_server.rs   # Unix domain socket high-speed telemetry broadcaster
```

---

## 4. Linux System Integration (`data/`)

```
data/
├── polkit/
│   └── org.netra.policy          # Polkit policy defining permissions for netra actions
├── dbus/
│   ├── org.netra.Control.conf    # D-Bus system bus security permissions for netra-daemon
│   └── org.netra.Control.service # D-Bus system service activation file
├── systemd/
│   └── netra-daemon.service      # Systemd system service unit definition
├── desktop/
│   └── org.netra.Netra.desktop   # XDG desktop launcher specification
└── icons/
    └── hicolor/                  # Freedesktop compliant icon theme structure
        ├── scalable/apps/netra.svg
        └── 256x256/apps/netra.png
```

---

## 5. Architectural Boundaries & Dependencies

| Crate | Permitted Dependencies | Forbidden Dependencies |
|---|---|---|
| `netra-common` | `serde`, `thiserror` | GUI, D-Bus, IO, network libraries |
| `netra-network` | `netra-common`, `zbus`, `rtnetlink` | `pipewire`, `bluez` |
| `netra-bluetooth` | `netra-common`, `zbus` | `pipewire`, `rtnetlink` |
| `netra-audio` | `netra-common`, `pipewire-rs`, `libpipewire-sys` | `NetworkManager`, `bluez` |
| `netra-traffic` | `netra-common`, `nix`, `rtnetlink` | GUI, `pipewire` |
| `netra-daemon` | All crates, `tokio`, `tracing`, `polkit` | Flutter / GUI code |
| `netra_desktop` | Dart / Flutter libraries, `dbus` | Direct C kernel APIs |
