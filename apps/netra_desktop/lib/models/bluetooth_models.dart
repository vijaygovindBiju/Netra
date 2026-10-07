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
