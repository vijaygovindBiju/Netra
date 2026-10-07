import 'dart:convert';
import 'package:dbus/dbus.dart';
import '../models/audio_models.dart';
import '../models/bluetooth_models.dart';
import '../models/hotspot_models.dart';
import '../models/network_models.dart';
import '../models/traffic_models.dart';

class NetraDbusService {
  DBusClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<bool> init() async {
    // 1. Try system bus first
    try {
      final sysClient = DBusClient.system();
      final obj = DBusRemoteObject(
        sysClient,
        name: 'org.netra.Control',
        path: DBusObjectPath('/org/netra/Network'),
      );
      await obj.callMethod('org.netra.Network', 'GetPrimaryInterface', []);
      _client = sysClient;
      _isConnected = true;
      return true;
    } catch (_) {
      // 2. Try session bus fallback
      try {
        final sesClient = DBusClient.session();
        final obj = DBusRemoteObject(
          sesClient,
          name: 'org.netra.Control',
          path: DBusObjectPath('/org/netra/Network'),
        );
        await obj.callMethod('org.netra.Network', 'GetPrimaryInterface', []);
        _client = sesClient;
        _isConnected = true;
        return true;
      } catch (_) {
        _isConnected = false;
        return false;
      }
    }
  }

  DBusRemoteObject _getObj(String path) {
    return DBusRemoteObject(
      _client ?? DBusClient.session(),
      name: 'org.netra.Control',
      path: DBusObjectPath(path),
    );
  }

  // --- Network Methods ---
  Future<void> scanWifi() async {
    await _getObj('/org/netra/Network').callMethod('org.netra.Network', 'ScanWifi', []);
  }

  Future<List<AccessPoint>> getAccessPoints() async {
    try {
      final res = await _getObj('/org/netra/Network').callMethod('org.netra.Network', 'GetAccessPointsJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => AccessPoint.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> connectWifi(String ssid, String passphrase) async {
    final res = await _getObj('/org/netra/Network').callMethod(
      'org.netra.Network',
      'ConnectWifi',
      [DBusString(ssid), DBusString(passphrase)],
    );
    if (res.values.isNotEmpty && res.values[0] is DBusBoolean) {
      return (res.values[0] as DBusBoolean).value;
    }
    return true;
  }

  Future<bool> disconnectWifi() async {
    final res = await _getObj('/org/netra/Network').callMethod('org.netra.Network', 'DisconnectWifi', []);
    if (res.values.isNotEmpty && res.values[0] is DBusBoolean) {
      return (res.values[0] as DBusBoolean).value;
    }
    return true;
  }

  Future<List<InterfaceMetrics>> getInterfaceMetrics() async {
    try {
      final res = await _getObj('/org/netra/Network').callMethod('org.netra.Network', 'GetInterfaceMetricsJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => InterfaceMetrics.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String> getPrimaryInterface() async {
    try {
      final res = await _getObj('/org/netra/Network').callMethod('org.netra.Network', 'GetPrimaryInterface', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        return (res.values[0] as DBusString).value;
      }
      return 'wlan0';
    } catch (_) {
      return 'wlan0';
    }
  }

  // --- Hotspot Methods ---
  Future<bool> startHotspot(String ssid, String passphrase, String band) async {
    final res = await _getObj('/org/netra/Hotspot').callMethod(
      'org.netra.Hotspot',
      'StartHotspot',
      [DBusString(ssid), DBusString(passphrase), DBusString(band)],
    );
    if (res.values.isNotEmpty && res.values[0] is DBusBoolean) {
      return (res.values[0] as DBusBoolean).value;
    }
    return true;
  }

  Future<bool> stopHotspot() async {
    final res = await _getObj('/org/netra/Hotspot').callMethod('org.netra.Hotspot', 'StopHotspot', []);
    if (res.values.isNotEmpty && res.values[0] is DBusBoolean) {
      return (res.values[0] as DBusBoolean).value;
    }
    return true;
  }

  Future<String> getHotspotStatus() async {
    try {
      final res = await _getObj('/org/netra/Hotspot').callMethod('org.netra.Hotspot', 'GetHotspotStatus', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        return (res.values[0] as DBusString).value;
      }
      return 'Inactive';
    } catch (_) {
      return 'Inactive';
    }
  }

  Future<List<ConnectedClient>> getConnectedClients() async {
    try {
      final res = await _getObj('/org/netra/Hotspot').callMethod('org.netra.Hotspot', 'GetConnectedClientsJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => ConnectedClient.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> setClientPriority(String mac, String priority) async {
    final res = await _getObj('/org/netra/Hotspot').callMethod(
      'org.netra.Hotspot',
      'SetClientPriority',
      [DBusString(mac), DBusString(priority)],
    );
    if (res.values.isNotEmpty && res.values[0] is DBusBoolean) {
      return (res.values[0] as DBusBoolean).value;
    }
    return true;
  }

  // --- Bluetooth Methods ---
  Future<bool> startBluetoothDiscovery() async {
    final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'StartDiscovery', []);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> stopBluetoothDiscovery() async {
    final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'StopDiscovery', []);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<List<BluetoothDeviceItem>> getBluetoothDevices() async {
    try {
      final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'GetDevicesJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => BluetoothDeviceItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> connectBluetoothDevice(String address) async {
    final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'ConnectDevice', [DBusString(address)]);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> disconnectBluetoothDevice(String address) async {
    final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'DisconnectDevice', [DBusString(address)]);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> pairBluetoothDevice(String address) async {
    final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'PairDevice', [DBusString(address)]);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> removeBluetoothDevice(String address) async {
    final res = await _getObj('/org/netra/Bluetooth').callMethod('org.netra.Bluetooth', 'RemoveDevice', [DBusString(address)]);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  // --- Traffic & QoS Methods ---
  Future<List<ProcessTrafficItem>> getProcessTraffic() async {
    try {
      final res = await _getObj('/org/netra/Traffic').callMethod('org.netra.Traffic', 'GetProcessTrafficJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => ProcessTrafficItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> initTrafficQos(String iface) async {
    final res = await _getObj('/org/netra/Traffic').callMethod('org.netra.Traffic', 'InitQos', [DBusString(iface)]);
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> assignTrafficPriority(String iface, String ip, String priority) async {
    final res = await _getObj('/org/netra/Traffic').callMethod(
      'org.netra.Traffic',
      'AssignIpPriority',
      [DBusString(iface), DBusString(ip), DBusString(priority)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  // --- PipeWire Audio Methods ---
  Future<List<AudioSinkItem>> getAudioSinks() async {
    try {
      final res = await _getObj('/org/netra/Audio').callMethod('org.netra.Audio', 'GetSinksJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => AudioSinkItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<AudioStreamItem>> getAudioStreams() async {
    try {
      final res = await _getObj('/org/netra/Audio').callMethod('org.netra.Audio', 'GetStreamsJson', []);
      if (res.values.isNotEmpty && res.values[0] is DBusString) {
        final raw = (res.values[0] as DBusString).value;
        final List decoded = jsonDecode(raw);
        return decoded.map((e) => AudioStreamItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> routeAudioStream(int streamId, int targetSinkId) async {
    final res = await _getObj('/org/netra/Audio').callMethod(
      'org.netra.Audio',
      'RouteStream',
      [DBusUint32(streamId), DBusUint32(targetSinkId)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> setSinkVolume(int sinkId, int volumePercent) async {
    final res = await _getObj('/org/netra/Audio').callMethod(
      'org.netra.Audio',
      'SetSinkVolume',
      [DBusUint32(sinkId), DBusByte(volumePercent)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> setSinkMute(int sinkId, bool isMuted) async {
    final res = await _getObj('/org/netra/Audio').callMethod(
      'org.netra.Audio',
      'SetSinkMute',
      [DBusUint32(sinkId), DBusBoolean(isMuted)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<bool> setSinkLatencyOffset(int sinkId, int offsetMs) async {
    final res = await _getObj('/org/netra/Audio').callMethod(
      'org.netra.Audio',
      'SetSinkLatencyOffset',
      [DBusUint32(sinkId), DBusInt32(offsetMs)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }

  Future<int> createMultiSink(String groupName, List<String> slaveNames) async {
    final slavesJson = jsonEncode(slaveNames);
    final res = await _getObj('/org/netra/Audio').callMethod(
      'org.netra.Audio',
      'CreateMultiSink',
      [DBusString(groupName), DBusString(slavesJson)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusUint32 ? (res.values[0] as DBusUint32).value : 0;
  }

  Future<bool> destroyMultiSink(String groupName) async {
    final res = await _getObj('/org/netra/Audio').callMethod(
      'org.netra.Audio',
      'DestroyMultiSink',
      [DBusString(groupName)],
    );
    return res.values.isNotEmpty && res.values[0] is DBusBoolean ? (res.values[0] as DBusBoolean).value : true;
  }
}
