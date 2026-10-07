class ConnectedClient {
  final String macAddress;
  final String ipAddress;
  final String? hostname;
  final String? vendor;
  final String priority;
  final int connectedDurationSecs;
  final int rxRateBps;
  final int txRateBps;
  final int totalRxBytes;
  final int totalTxBytes;

  ConnectedClient({
    required this.macAddress,
    required this.ipAddress,
    this.hostname,
    this.vendor,
    required this.priority,
    required this.connectedDurationSecs,
    required this.rxRateBps,
    required this.txRateBps,
    required this.totalRxBytes,
    required this.totalTxBytes,
  });

  factory ConnectedClient.fromJson(Map<String, dynamic> json) {
    return ConnectedClient(
      macAddress: json['mac_address'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      hostname: json['hostname'],
      vendor: json['vendor'],
      priority: (json['priority'] ?? 'Medium').toString(),
      connectedDurationSecs: (json['connected_duration_secs'] as num?)?.toInt() ?? 0,
      rxRateBps: (json['rx_rate_bps'] as num?)?.toInt() ?? 0,
      txRateBps: (json['tx_rate_bps'] as num?)?.toInt() ?? 0,
      totalRxBytes: (json['total_rx_bytes'] as num?)?.toInt() ?? 0,
      totalTxBytes: (json['total_tx_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class HotspotConfig {
  final String ssid;
  final String passphrase;
  final String band;
  final bool apIsolate;

  HotspotConfig({
    required this.ssid,
    required this.passphrase,
    this.band = '2.4GHz',
    this.apIsolate = false,
  });
}
