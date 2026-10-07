# Netra — Security Architecture & Threat Model

> **Document Version:** 1.0.0  
> **Status:** Security Specification  
> **Classification:** Public System Security Architecture  

---

## 1. Security Philosophy & Principles

Netra interfaces directly with critical Linux kernel and network infrastructure: packet queues, Wi-Fi radios in AP mode, routing tables, and audio server streams. Operating insecurely could expose the host system to privilege escalation, traffic eavesdropping, or denial-of-service.

Netra is engineered around four core security pillars:
1. **Zero-Root GUI:** The desktop user interface never executes with elevated (`root`) privileges.
2. **Polkit-Mediated Authorization:** Sensitive system actions require cryptographic verification of caller identity and session authorization via PolicyKit (`polkit`).
3. **Principle of Least Privilege (Capabilities):** The background daemon is locked down using Linux Capabilities (`CAP_NET_ADMIN`, `CAP_NET_RAW`) instead of running as unrestricted root.
4. **Memory Safety by Construction:** The entire core daemon is implemented in safe Rust, eliminating buffer overflows, use-after-free, and data races.

---

## 2. Privilege Separation Architecture

```
┌────────────────────────────────────────────────────────┐
│                   Desktop User Session                 │
│              (UID = 1000, GID = 1000, Unprivileged)    │
│  ┌──────────────────────────────────────────────────┐  │
│  │                Netra Flutter UI                  │  │
│  │  - Renders dashboard, visualizers, and controls  │  │
│  │  - Initiates unprivileged D-Bus method calls      │  │
│  │  - Sandboxed or non-sandboxed user session       │  │
│  └──────────────────────────┬───────────────────────┘  │
└─────────────────────────────┼──────────────────────────┘
                              │ IPC Call over D-Bus
                              ▼
┌────────────────────────────────────────────────────────┐
│                  Polkit Authorization Authority        │
│   - Validates caller PID, UID, and session ID          │
│   - Checks policy: /usr/share/polkit-1/actions/        │
│   - Prompts for admin auth only if required            │
└─────────────────────────────┬──────────────────────────┘
                              │ Polkit Auth Token Verified
                              ▼
┌────────────────────────────────────────────────────────┐
│               Netra Daemon (netrad.service)            │
│            Runs as dedicated user: `netra`             │
│        Scoped Linux Capabilities: CAP_NET_ADMIN        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  - Manages NetworkManager AP connections         │  │
│  │  - Applies Linux TC (HTB) and QoS filters        │  │
│  │  - Manages PipeWire multi-sink audio nodes       │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## 3. PolicyKit (Polkit) Action Definitions

Polkit rules define granular access control for Netra's actions, installed at `/usr/share/polkit-1/actions/org.netra.policy`.

| Action ID | Description | Default: Inactive Session | Default: Active Session |
|---|---|---|---|
| `org.netra.network.read` | View network stats, APs, and metrics | `no` | `yes` (Implicit) |
| `org.netra.network.configure` | Connect/Disconnect Wi-Fi, change profiles | `auth_admin` | `yes` (Implicit) |
| `org.netra.hotspot.manage` | Start/Stop Wi-Fi AP Hotspot | `auth_admin` | `yes` (Active user session) |
| `org.netra.hotspot.qos` | Apply bandwidth shaping or kick client | `auth_admin` | `yes` (Active user session) |
| `org.netra.bluetooth.manage` | Scan, pair, or connect Bluetooth devices | `auth_admin` | `yes` (Implicit) |
| `org.netra.audio.route` | Create virtual sinks, link audio streams | `no` | `yes` (User PipeWire session) |

### Sample Policy Configuration (`org.netra.policy`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
<policyconfig>
  <vendor>Netra Project</vendor>
  <vendor_url>https://github.com/netra/netra</vendor_url>

  <action id="org.netra.hotspot.manage">
    <description>Manage Netra Wi-Fi Hotspot</description>
    <message>Authentication is required to start or stop the Wi-Fi hotspot</message>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>yes</allow_active>
    </defaults>
  </action>

  <action id="org.netra.hotspot.qos">
    <description>Apply bandwidth shaping rules</description>
    <message>Authentication is required to modify network traffic control policies</message>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>yes</allow_active>
    </defaults>
  </action>
</policyconfig>
```

---

## 4. Linux Capabilities & Systemd Hardening

The `netra-daemon` system service drops all unnecessary root privileges at startup. In `netra-daemon.service`:

```ini
[Unit]
Description=Netra Connectivity and Audio Control Daemon
After=network.target dbus.service pipewire.service
Wants=network.target

[Service]
Type=notify
ExecStart=/usr/bin/netra-daemon
Restart=on-failure
RestartSec=3

# Privilege confinement
User=netra
Group=netra
SupplementaryGroups=networkmanager pipewire

# Grant only specific networking capabilities
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW

# Filesystem & Process Protection
ProtectSystem=strict
ProtectHome=read-only
ProtectKernelTunables=true
ProtectControlGroups=true
PrivateTmp=true
ProtectClock=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true

# Read-write runtime directory for telemetry socket
RuntimeDirectory=netra
RuntimeDirectoryMode=0750
```

---

## 5. IPC Security & D-Bus Bus Policy

The D-Bus configuration (`/usr/share/dbus-1/system.d/org.netra.Control.conf`) restricts interface claiming to the authorized `netra` daemon user, while permitting active local users to invoke methods:

```xml
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <!-- Only the netra daemon user can own the well-known bus name -->
  <policy user="netra">
    <allow own="org.netra.Control"/>
  </policy>

  <!-- Any local user can call methods, subject to Polkit enforcement in the daemon -->
  <policy context="default">
    <allow send_destination="org.netra.Control"/>
    <allow receive_sender="org.netra.Control"/>
  </policy>
</busconfig>
```

### High-Speed Telemetry Unix Socket Security
For the high-frequency telemetry socket (`/run/netra/telemetry.sock`):
- Socket permissions are strictly set to `0660` owned by `netra:netra` with ACLs granting the current active user group access.
- The daemon validates the peer process credentials on connect via `SO_PEERCRED` (checking that the peer UID matches an authorized active console user).

---

## 6. Threat Modeling & Mitigations

### 6.1. Threat: Malicious Command Injection via SSID or Passphrase
- **Attack Vector:** An attacker inputs crafted shell metacharacters (e.g., `NetraHotspot; rm -rf /`) into the Hotspot SSID or password fields.
- **Mitigation:**
  - Netra **never** passes parameters to shell strings (`sh -c`).
  - NetworkManager D-Bus API is called via strongly typed GVariant structs.
  - Strict input validation: SSIDs are validated to UTF-8 strings of 1-32 bytes; WPA2 passphrases must be 8-63 ASCII characters; WPA3 passphrases strictly conform to SAE specs.

### 6.2. Threat: Unauthorized Bandwidth Starvation (Denial-of-Service via QoS)
- **Attack Vector:** An unprivileged malicious local user script issues D-Bus calls to throttle all interfaces or connected devices to 0 kbps.
- **Mitigation:**
  - Every QoS modification method checks caller Polkit authorization (`org.netra.hotspot.qos`).
  - Hard lower limits are enforced in `netra-daemon` (minimum guaranteed rate floor of 128 kbps per class).

### 6.3. Threat: Rogue Wi-Fi AP Client Exploits (Hotspot Client Isolation)
- **Attack Vector:** A guest device connected to the Netra hotspot attempts to probe, exploit, or eavesdrop on other connected guest devices.
- **Mitigation:**
  - Netra enables **AP Isolation** (`802-11-wireless.ap-isolate = 1`) by default where supported by the wireless hardware driver.
  - Hotspot iptables/nftables forwarding rules strictly restrict client-to-client traffic while allowing client-to-WAN forwarding.

### 6.4. Threat: Memory Corruption in Audio Processing
- **Attack Vector:** Corrupted audio packet streams or maliciously formatted PipeWire metadata triggering heap corruption.
- **Mitigation:**
  - Memory-safe Rust implementation for graph state synchronization and string formatting.
  - Safe Rust abstractions over `libpipewire-sys` via `pipewire-rs`.
