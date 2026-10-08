class BluetoothDeviceItem {
  final String address;
  final String name;
  final String alias;
  final String category;
  final bool isPaired;
  final bool isConnected;
  final bool isTrusted;
  final int? batteryPercentage;
  final int? rssi;

  BluetoothDeviceItem({
    required this.address,
    required this.name,
    required this.alias,
    required this.category,
    required this.isPaired,
    required this.isConnected,
    required this.isTrusted,
    this.batteryPercentage,
    this.rssi,
  });

  factory BluetoothDeviceItem.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceItem(
      address: json['address'] ?? '',
      name: json['name'] ?? '',
      alias: json['alias'] ?? json['name'] ?? '',
      category: (json['category'] ?? 'Unknown').toString(),
      isPaired: json['is_paired'] ?? false,
      isConnected: json['is_connected'] ?? false,
      isTrusted: json['is_trusted'] ?? false,
      batteryPercentage: (json['battery_percentage'] as num?)?.toInt(),
      rssi: (json['rssi'] as num?)?.toInt(),
    );
  }
}

class BluetoothAdapterItem {
  final String address;
  final String name;
  final bool isPowered;
  final bool isDiscovering;
  final bool isPairable;
  final String manufacturer;
  final String chipsetName;
  final String bluetoothVersion;
  final int hciVersion;
  final int maxActiveConnections;
  final int maxRecommendedAudioStreams;
  final bool supportsLeAudio;
  final bool supports2mPhy;

  BluetoothAdapterItem({
    required this.address,
    required this.name,
    required this.isPowered,
    required this.isDiscovering,
    required this.isPairable,
    required this.manufacturer,
    required this.chipsetName,
    required this.bluetoothVersion,
    required this.hciVersion,
    required this.maxActiveConnections,
    required this.maxRecommendedAudioStreams,
    required this.supportsLeAudio,
    required this.supports2mPhy,
  });

  factory BluetoothAdapterItem.fromJson(Map<String, dynamic> json) {
    return BluetoothAdapterItem(
      address: json['address'] ?? '',
      name: json['name'] ?? '',
      isPowered: json['is_powered'] ?? false,
      isDiscovering: json['is_discovering'] ?? false,
      isPairable: json['is_pairable'] ?? false,
      manufacturer: json['manufacturer'] ?? 'Unknown',
      chipsetName: json['chipset_name'] ?? 'Bluetooth Adapter',
      bluetoothVersion: json['bluetooth_version'] ?? '5.0',
      hciVersion: (json['hci_version'] as num?)?.toInt() ?? 9,
      maxActiveConnections: (json['max_active_connections'] as num?)?.toInt() ?? 7,
      maxRecommendedAudioStreams: (json['max_recommended_audio_streams'] as num?)?.toInt() ?? 2,
      supportsLeAudio: json['supports_le_audio'] ?? false,
      supports2mPhy: json['supports_2m_phy'] ?? false,
    );
  }
}

