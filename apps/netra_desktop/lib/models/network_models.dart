class AccessPoint {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final int frequencyMhz;
  final String band;
  final String security;
  final bool isConnected;

  AccessPoint({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.frequencyMhz,
    required this.band,
    required this.security,
    required this.isConnected,
  });

  factory AccessPoint.fromJson(Map<String, dynamic> json) {
    return AccessPoint(
      ssid: json['ssid'] ?? '',
      bssid: json['bssid'] ?? '',
      signalStrength: (json['signal_strength'] as num?)?.toInt() ?? 0,
      frequencyMhz: (json['frequency_mhz'] as num?)?.toInt() ?? 2412,
      band: json['band'] is Map ? json['band'].keys.first : (json['band'] ?? 'Unknown').toString(),
      security: json['security'] is Map ? json['security'].keys.first : (json['security'] ?? 'Open').toString(),
      isConnected: json['is_connected'] ?? false,
    );
  }
}

class InterfaceMetrics {
  final String ifaceName;
  final String state;
  final bool isWireless;
  final int rxBytes;
  final int txBytes;
  final int rxRateBps;
  final int txRateBps;
  final String? ipAddress;
  final String? gateway;
  final List<String> dnsServers;
  final String? connectedSsid;

  InterfaceMetrics({
    required this.ifaceName,
    required this.state,
    required this.isWireless,
    required this.rxBytes,
    required this.txBytes,
    required this.rxRateBps,
    required this.txRateBps,
    this.ipAddress,
    this.gateway,
    this.dnsServers = const [],
    this.connectedSsid,
  });

  factory InterfaceMetrics.fromJson(Map<String, dynamic> json) {
    return InterfaceMetrics(
      ifaceName: json['iface_name'] ?? 'unknown',
      state: (json['state'] ?? 'Connected').toString(),
      isWireless: json['is_wireless'] ?? false,
      rxBytes: (json['rx_bytes'] as num?)?.toInt() ?? 0,
      txBytes: (json['tx_bytes'] as num?)?.toInt() ?? 0,
      rxRateBps: (json['rx_rate_bps'] as num?)?.toInt() ?? 0,
      txRateBps: (json['tx_rate_bps'] as num?)?.toInt() ?? 0,
      ipAddress: json['ip_address'],
      gateway: json['gateway'],
      dnsServers: (json['dns_servers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      connectedSsid: json['connected_ssid'],
    );
  }
}
