class AudioSinkItem {
  final int id;
  final String name;
  final String description;
  final int volumePercent;
  final bool isMuted;
  final bool isDefault;
  final bool isBluetooth;
  final bool isVirtual;
  final int latencyOffsetMs;

  AudioSinkItem({
    required this.id,
    required this.name,
    required this.description,
    required this.volumePercent,
    required this.isMuted,
    this.isDefault = false,
    required this.isBluetooth,
    required this.isVirtual,
    required this.latencyOffsetMs,
  });

  factory AudioSinkItem.fromJson(Map<String, dynamic> json) {
    return AudioSinkItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      volumePercent: (json['volume_percent'] as num?)?.toInt() ?? 100,
      isMuted: json['is_muted'] ?? false,
      isDefault: json['is_default'] ?? false,
      isBluetooth: json['is_bluetooth'] ?? false,
      isVirtual: json['is_virtual'] ?? false,
      latencyOffsetMs: (json['latency_offset_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

class AudioStreamItem {
  final int id;
  final String name;
  final String appName;
  final String binaryName;
  final int currentSinkId;
  final int volumePercent;
  final bool isMuted;

  AudioStreamItem({
    required this.id,
    required this.name,
    required this.appName,
    required this.binaryName,
    required this.currentSinkId,
    required this.volumePercent,
    required this.isMuted,
  });

  factory AudioStreamItem.fromJson(Map<String, dynamic> json) {
    return AudioStreamItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      appName: json['app_name'] ?? json['name'] ?? '',
      binaryName: json['binary_name'] ?? '',
      currentSinkId: (json['current_sink_id'] as num?)?.toInt() ?? 0,
      volumePercent: (json['volume_percent'] as num?)?.toInt() ?? 100,
      isMuted: json['is_muted'] ?? false,
    );
  }
}
