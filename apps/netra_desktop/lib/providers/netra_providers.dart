import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_models.dart';
import '../models/bluetooth_models.dart';
import '../models/hotspot_models.dart';
import '../models/network_models.dart';
import '../models/traffic_models.dart';
import '../services/netra_dbus_service.dart';

// UI Navigation and Theme Providers
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
final activeTabProvider = StateProvider<int>((ref) => 0);

final netraServiceProvider = Provider<NetraDbusService>((ref) {
  final service = NetraDbusService();
  service.init();
  return service;
});

// 1. Network State
class NetworkState {
  final bool isLoading;
  final List<AccessPoint> accessPoints;
  final InterfaceMetrics? currentMetrics;
  final String primaryIface;
  final String? error;

  NetworkState({
    this.isLoading = false,
    this.accessPoints = const [],
    this.currentMetrics,
    this.primaryIface = 'wlan0',
    this.error,
  });

  NetworkState copyWith({
    bool? isLoading,
    List<AccessPoint>? accessPoints,
    InterfaceMetrics? currentMetrics,
    String? primaryIface,
    String? error,
  }) {
    return NetworkState(
      isLoading: isLoading ?? this.isLoading,
      accessPoints: accessPoints ?? this.accessPoints,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      primaryIface: primaryIface ?? this.primaryIface,
      error: error,
    );
  }
}

class NetworkNotifier extends StateNotifier<NetworkState> {
  final NetraDbusService _service;
  Timer? _telemetryTimer;

  NetworkNotifier(this._service) : super(NetworkState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    await _service.init();
    final iface = await _service.getPrimaryInterface();
    state = state.copyWith(primaryIface: iface);
    await refreshScan();
    await updateMetrics();

    _telemetryTimer?.cancel();
    int ticks = 0;
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await updateMetrics();
      ticks++;
      if (ticks % 3 == 0) {
        try {
          final aps = await _service.getAccessPoints();
          if (aps.isNotEmpty) {
            state = state.copyWith(accessPoints: aps);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> refreshScan() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.scanWifi();
      await Future.delayed(const Duration(milliseconds: 600));
      final aps = await _service.getAccessPoints();
      state = state.copyWith(accessPoints: aps, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> connect(String ssid, String passphrase) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _service.connectWifi(ssid, passphrase);
      await refreshScan();
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> disconnect() async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _service.disconnectWifi();
      await refreshScan();
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> updateMetrics() async {
    try {
      final metricsList = await _service.getInterfaceMetrics();
      final current = metricsList.firstWhere(
        (m) => m.ifaceName == state.primaryIface,
        orElse: () => metricsList.isNotEmpty ? metricsList.first : InterfaceMetrics(
          ifaceName: state.primaryIface,
          state: 'Unknown',
          isWireless: true,
          rxBytes: 0,
          txBytes: 0,
          rxRateBps: 0,
          txRateBps: 0,
        ),
      );
      state = state.copyWith(currentMetrics: current);
    } catch (_) {}
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}

final networkStateProvider = StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  final service = ref.watch(netraServiceProvider);
  return NetworkNotifier(service);
});

// 2. Hotspot State
class HotspotState {
  final bool isLoading;
  final bool isActive;
  final String status;
  final HotspotConfig config;
  final List<ConnectedClient> clients;
  final String? error;

  HotspotState({
    this.isLoading = false,
    this.isActive = false,
    this.status = 'Inactive',
    required this.config,
    this.clients = const [],
    this.error,
  });

  HotspotState copyWith({
    bool? isLoading,
    bool? isActive,
    String? status,
    HotspotConfig? config,
    List<ConnectedClient>? clients,
    String? error,
  }) {
    return HotspotState(
      isLoading: isLoading ?? this.isLoading,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      config: config ?? this.config,
      clients: clients ?? this.clients,
      error: error,
    );
  }
}

class HotspotNotifier extends StateNotifier<HotspotState> {
  final NetraDbusService _service;
  Timer? _clientsTimer;

  HotspotNotifier(this._service)
      : super(HotspotState(
          config: HotspotConfig(
            ssid: 'Netra-Hotspot',
            passphrase: 'password1234',
            band: '2.4GHz',
          ),
        )) {
    init();
  }

  Future<void> init() async {
    final status = await _service.getHotspotStatus();
    state = state.copyWith(
      status: status,
      isActive: status == 'Active',
    );
    _clientsTimer?.cancel();
    _clientsTimer = Timer.periodic(const Duration(seconds: 2), (_) => refreshClients());
  }

  void updateConfig({String? ssid, String? passphrase, String? band}) {
    state = state.copyWith(
      config: HotspotConfig(
        ssid: ssid ?? state.config.ssid,
        passphrase: passphrase ?? state.config.passphrase,
        band: band ?? state.config.band,
      ),
    );
  }

  Future<void> toggleHotspot() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (state.isActive) {
        await _service.stopHotspot();
        state = state.copyWith(
          isActive: false,
          status: 'Inactive',
          isLoading: false,
          clients: [],
        );
      } else {
        await _service.startHotspot(
          state.config.ssid,
          state.config.passphrase,
          state.config.band,
        );
        state = state.copyWith(
          isActive: true,
          status: 'Active',
          isLoading: false,
        );
        await refreshClients();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshClients() async {
    if (!state.isActive) return;
    try {
      final clients = await _service.getConnectedClients();
      state = state.copyWith(clients: clients);
    } catch (_) {}
  }

  Future<void> setPriority(String mac, String priority) async {
    try {
      await _service.setClientPriority(mac, priority);
      await refreshClients();
    } catch (_) {}
  }

  @override
  void dispose() {
    _clientsTimer?.cancel();
    super.dispose();
  }
}

final hotspotStateProvider = StateNotifierProvider<HotspotNotifier, HotspotState>((ref) {
  final service = ref.watch(netraServiceProvider);
  return HotspotNotifier(service);
});

// 3. Bluetooth State
class BluetoothState {
  final bool isScanning;
  final List<BluetoothDeviceItem> devices;
  final BluetoothAdapterItem? adapter;
  final String? error;

  BluetoothState({
    this.isScanning = false,
    this.devices = const [],
    this.adapter,
    this.error,
  });

  BluetoothState copyWith({
    bool? isScanning,
    List<BluetoothDeviceItem>? devices,
    BluetoothAdapterItem? adapter,
    String? error,
  }) {
    return BluetoothState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      adapter: adapter ?? this.adapter,
      error: error,
    );
  }
}

class BluetoothNotifier extends StateNotifier<BluetoothState> {
  final NetraDbusService _service;
  Timer? _pollTimer;

  BluetoothNotifier(this._service) : super(BluetoothState()) {
    refreshDevices();
    refreshAdapter();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      refreshDevices();
      refreshAdapter();
    });
  }

  Future<void> refreshAdapter() async {
    try {
      final adapter = await _service.getBluetoothAdapterInfo();
      if (adapter != null) {
        state = state.copyWith(adapter: adapter);
      }
    } catch (_) {}
  }

  Future<void> refreshDevices() async {
    try {
      final devices = await _service.getBluetoothDevices();
      state = state.copyWith(devices: devices, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> startScan() async {
    state = state.copyWith(isScanning: true);
    await _service.startBluetoothDiscovery();
    await refreshDevices();
  }

  Future<void> stopScan() async {
    state = state.copyWith(isScanning: false);
    await _service.stopBluetoothDiscovery();
  }

  Future<void> connect(String address) async {
    await _service.connectBluetoothDevice(address);
    await refreshDevices();
  }

  Future<void> disconnect(String address) async {
    await _service.disconnectBluetoothDevice(address);
    await refreshDevices();
  }

  Future<void> pair(String address) async {
    await _service.pairBluetoothDevice(address);
    await refreshDevices();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final bluetoothStateProvider = StateNotifierProvider<BluetoothNotifier, BluetoothState>((ref) {
  final service = ref.watch(netraServiceProvider);
  return BluetoothNotifier(service);
});

// 4. Traffic & QoS State
class TrafficState {
  final List<ProcessTrafficItem> processes;
  final String? error;

  TrafficState({
    this.processes = const [],
    this.error,
  });

  TrafficState copyWith({
    List<ProcessTrafficItem>? processes,
    String? error,
  }) {
    return TrafficState(
      processes: processes ?? this.processes,
      error: error,
    );
  }
}

class TrafficNotifier extends StateNotifier<TrafficState> {
  final NetraDbusService _service;
  Timer? _timer;

  TrafficNotifier(this._service) : super(TrafficState()) {
    refreshTraffic();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => refreshTraffic());
  }

  Future<void> refreshTraffic() async {
    try {
      final list = await _service.getProcessTraffic();
      state = state.copyWith(processes: list, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final trafficStateProvider = StateNotifierProvider<TrafficNotifier, TrafficState>((ref) {
  final service = ref.watch(netraServiceProvider);
  return TrafficNotifier(service);
});

// 5. PipeWire Audio State
class AudioState {
  final List<AudioSinkItem> sinks;
  final List<AudioStreamItem> streams;
  final String? error;

  AudioState({
    this.sinks = const [],
    this.streams = const [],
    this.error,
  });

  AudioState copyWith({
    List<AudioSinkItem>? sinks,
    List<AudioStreamItem>? streams,
    String? error,
  }) {
    return AudioState(
      sinks: sinks ?? this.sinks,
      streams: streams ?? this.streams,
      error: error,
    );
  }
}

class AudioNotifier extends StateNotifier<AudioState> {
  final NetraDbusService _service;
  Timer? _timer;

  AudioNotifier(this._service) : super(AudioState()) {
    refreshAudio();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => refreshAudio());
  }

  Future<void> refreshAudio() async {
    try {
      final sinks = await _service.getAudioSinks();
      final streams = await _service.getAudioStreams();
      state = state.copyWith(sinks: sinks, streams: streams, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> routeStream(int streamId, int targetSinkId) async {
    await _service.routeAudioStream(streamId, targetSinkId);
    await refreshAudio();
  }

  Future<void> setVolume(int sinkId, int volumePercent) async {
    await _service.setSinkVolume(sinkId, volumePercent);
    await refreshAudio();
  }

  Future<void> setMute(int sinkId, bool isMuted) async {
    await _service.setSinkMute(sinkId, isMuted);
    await refreshAudio();
  }

  Future<void> setLatencyOffset(int sinkId, int offsetMs) async {
    await _service.setSinkLatencyOffset(sinkId, offsetMs);
    await refreshAudio();
  }

  Future<void> createDualAudio(String groupName, List<String> slaveNames) async {
    await _service.createMultiSink(groupName, slaveNames);
    await refreshAudio();
  }

  Future<void> destroyDualAudio(String groupName) async {
    await _service.destroyMultiSink(groupName);
    await refreshAudio();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final audioStateProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final service = ref.watch(netraServiceProvider);
  return AudioNotifier(service);
});
