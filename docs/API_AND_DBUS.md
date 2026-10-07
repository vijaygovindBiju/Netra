# Netra — D-Bus & IPC API Specifications

> **Document Version:** 1.0.0  
> **Status:** Interface Contract  
> **Bus:** System Bus (`DBUS_BUS_SYSTEM`)  
> **Well-Known Name:** `org.netra.Control`  

---

## 1. D-Bus Object Hierarchy Overview

| Object Path | Interface Name | Primary Responsibility |
|---|---|---|
| `/org/netra/Network` | `org.netra.Network` | Wi-Fi scanning, connection control, interface statistics |
| `/org/netra/Hotspot` | `org.netra.Hotspot` | AP hotspot lifecycle, connected client registry, QoS limits |
| `/org/netra/Bluetooth` | `org.netra.Bluetooth` | Device pairing, trust, battery levels, profile controls |
| `/org/netra/Audio` | `org.netra.Audio` | PipeWire graph routing, multi-sink creation, volume/sync |
| `/org/netra/Traffic` | `org.netra.Traffic` | Per-process socket telemetry and real-time bandwidth |

---

## 2. Interface: `org.netra.Network`

Path: `/org/netra/Network`

### Methods

#### `ScanWifi(s interface_name) -> ()`
Initiates an active 802.11 scan on the specified wireless interface.
- **Parameters:** `interface_name` (e.g., `"wlan0"`).
- **Signals emitted:** `AccessPointsChanged` when scan results settle.

#### `GetAccessPoints(s interface_name) -> a(ssssqyb)`
Returns the list of currently visible Wi-Fi access points.
- **Returns:** Array of tuples:
  - `s`: SSID (network name)
  - `s`: BSSID (hardware MAC)
  - `s`: Security flags (e.g., `"WPA2-PSK"`, `"WPA3-SAE"`, `"OPEN"`)
  - `s`: Frequency band (`"2.4GHz"`, `"5GHz"`, `"6GHz"`)
  - `q`: Channel number (uint16)
  - `y`: Signal strength percentage (0–100 byte)
  - `b`: Connected (boolean, true if currently active)

#### `ConnectWifi(s interface_name, s ssid, s passphrase, b hidden) -> b`
Connects to a specific Wi-Fi network.
- **Parameters:**
  - `interface_name`: Name of device (`"wlan0"`).
  - `ssid`: Target network name.
  - `passphrase`: WPA/WPA2/WPA3 passphrase.
  - `hidden`: True if the network does not broadcast its SSID.
- **Returns:** `b`: Success boolean.

#### `DisconnectWifi(s interface_name) -> b`
Disconnects active Wi-Fi connection on the interface.

#### `GetInterfaceStats(s interface_name) -> (ttttt)`
Returns instantaneous network metrics.
- **Returns:** Tuple `(rx_bytes, tx_bytes, rx_rate_bps, tx_rate_bps, ping_latency_ms)`.

### Signals

#### `AccessPointsChanged(s interface_name)`
Emitted when new Wi-Fi scan results are available.

#### `ConnectionStatusChanged(s interface_name, s status, s ip_address)`
Emitted when an interface transitions between `Disconnected`, `Connecting`, `Connected`, or `Failed`.

---

## 3. Interface: `org.netra.Hotspot`

Path: `/org/netra/Hotspot`

### Methods

#### `StartHotspot(s ssid, s passphrase, s band, b ap_isolate) -> b`
Initializes and broadcasts a Wi-Fi Access Point hotspot.
- **Parameters:**
  - `ssid`: Hotspot network name (1–32 characters).
  - `passphrase`: WPA2/WPA3 passphrase (8–63 characters).
  - `band`: `"2.4GHz"` or `"5GHz"`.
  - `ap_isolate`: Whether connected clients should be blocked from talking to each other.
- **Returns:** `b`: True if successfully established.

#### `StopHotspot() -> b`
Tears down the active hotspot and restores standard Wi-Fi station mode.

#### `GetConnectedClients() -> a(ssssstt)`
Returns all currently connected client devices.
- **Returns:** Array of tuples:
  - `s`: Client MAC address (e.g., `"AA:BB:CC:DD:EE:FF"`)
  - `s`: Assigned IP address (e.g., `"10.42.0.55"`)
  - `s`: Resolved Hostname (e.g., `"Pixel-8-Pro"`)
  - `s`: Hardware Manufacturer (OUI lookup, e.g., `"Google LLC"`)
  - `s`: QoS Priority (`"High"`, `"Medium"`, `"Low"`)
  - `t`: Download rate in bytes/sec
  - `t`: Upload rate in bytes/sec

#### `SetClientQoS(s client_mac, s priority, t max_down_bps, t max_up_bps) -> b`
Applies Traffic Control (`tc`/`HTB`) bandwidth shaping and priority class to a specific client.
- **Parameters:**
  - `client_mac`: Target MAC address.
  - `priority`: `"High"`, `"Medium"`, or `"Low"`.
  - `max_down_bps`: Maximum download limit in bytes/sec (0 for unlimited).
  - `max_up_bps`: Maximum upload limit in bytes/sec (0 for unlimited).

#### `BlockClient(s client_mac) -> b`
Kicks and blacklists a client MAC from the hotspot.

### Properties

- `IsActive`: `b` (Read-only) — Hotspot running state.
- `SSID`: `s` (Read-only) — Active SSID.
- `Band`: `s` (Read-only) — Active band (`"2.4GHz"` / `"5GHz"`).
- `ClientCount`: `u` (Read-only) — Number of connected clients.

---

## 4. Interface: `org.netra.Bluetooth`

Path: `/org/netra/Bluetooth`

### Methods

#### `StartDiscovery() -> ()`
Begins scanning for nearby Classic and BLE Bluetooth devices.

#### `StopDiscovery() -> ()`
Stops background discovery scanning to conserve radio power.

#### `GetDevices() -> a(sssbyy)`
Returns discovered and paired Bluetooth devices.
- **Returns:** Array of tuples:
  - `s`: Device MAC address.
  - `s`: Friendly device name (e.g., `"Sony WH-1000XM5"`).
  - `s`: Device category (`"audio-headset"`, `"audio-speaker"`, `"phone"`, `"input-mouse"`).
  - `b`: Connected status.
  - `y`: Battery percentage (255 if unknown).
  - `y`: RSSI signal level (dBm converted to percentage).

#### `PairDevice(s device_address) -> b`
Initiates pairing with a remote device.

#### `ConnectDevice(s device_address) -> b`
Connects all supported profiles (A2DP, HFP, HID) for the device.

#### `DisconnectDevice(s device_address) -> b`
Disconnects active profiles for the device.

---

## 5. Interface: `org.netra.Audio`

Path: `/org/netra/Audio`

### Methods

#### `GetAudioSinks() -> a(ussdsba(s))`
Returns all physical and virtual audio sinks detected in PipeWire.
- **Returns:** Array of tuples:
  - `u`: PipeWire Node ID.
  - `s`: Device Name identifier (e.g., `"bluez_output.XX_XX_XX"`).
  - `s`: Human-readable description (e.g., `"Bose QuietComfort 45"`).
  - `d`: Volume level (0.0 to 1.5).
  - `s`: Current active codec (e.g., `"LDAC"`, `"aptX-HD"`, `"AAC"`, `"SBC"`).
  - `b`: Is virtual sink group.
  - `a(s)`: Supported audio profiles.

#### `CreateVirtualMultiSink(s name, au sink_node_ids) -> u`
Creates a synchronized virtual master sink in PipeWire that mirrors audio across multiple physical sinks.
- **Parameters:**
  - `name`: Display label (e.g., `"Dual Headphones Group"`).
  - `sink_node_ids`: Array of physical sink node IDs.
- **Returns:** `u`: Newly created virtual PipeWire Node ID.

#### `DestroyVirtualSink(u virtual_node_id) -> b`
Tears down a virtual multi-sink node.

#### `SetSinkLatencyOffset(u sink_node_id, i offset_millis) -> b`
Adjusts latency delay compensation (in milliseconds, e.g., -50ms to +150ms) to synchronize Bluetooth audio sinks with differing codec delays.

#### `RouteAppStream(u stream_node_id, u target_sink_node_id) -> b`
Directs a running application's audio playback stream to a specific physical or virtual sink.

---

## 6. Interface: `org.netra.Traffic`

Path: `/org/netra/Traffic`

### Methods

#### `GetTopProcesses(u count) -> a(usttss)`
Returns instantaneous bandwidth usage sorted by throughput.
- **Returns:** Array of tuples:
  - `u`: Process ID (PID).
  - `s`: Executable Name (e.g., `"firefox"`, `"steam"`).
  - `t`: Download rate (bytes/sec).
  - `t`: Upload rate (bytes/sec).
  - `s`: Total session bytes formatted.
  - `s`: Desktop application icon identifier.

---

## 7. High-Throughput Unix Domain Socket Telemetry

For buttery-smooth 60 FPS real-time graph rendering, the desktop UI connects directly to `/run/netra/telemetry.sock`.

### Packet Wire Protocol

```
┌──────────────┬──────────────┬───────────────────────────────┐
│ Magic Header │ Message Type │ Payload Length (Big Endian)   │
│  "NETRA"     │    1 Byte    │            4 Bytes            │
├──────────────┴──────────────┴───────────────────────────────┤
│ Payload: Compact Binary MessagePack / FlatBuffers Data      │
└─────────────────────────────────────────────────────────────┘
```

#### Message Types:
- `0x01` — **InterfaceRateUpdate:** Per-second RX/TX delta counters for network cards.
- `0x02` — **AppTrafficStream:** Real-time PID bandwidth telemetry tick.
- `0x03` — **AudioPeakMeters:** Real-time VU meter peak audio levels per node.
