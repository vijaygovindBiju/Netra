class ProcessTrafficItem {
  final int pid;
  final String name;
  final String cmdline;
  final int rxRateBps;
  final int txRateBps;
  final int totalRxBytes;
  final int totalTxBytes;
  final int openSocketCount;

  ProcessTrafficItem({
    required this.pid,
    required this.name,
    required this.cmdline,
    required this.rxRateBps,
    required this.txRateBps,
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.openSocketCount,
  });

  factory ProcessTrafficItem.fromJson(Map<String, dynamic> json) {
    return ProcessTrafficItem(
      pid: (json['pid'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? 'unknown',
      cmdline: json['cmdline'] ?? '',
      rxRateBps: (json['rx_rate_bps'] as num?)?.toInt() ?? 0,
      txRateBps: (json['tx_rate_bps'] as num?)?.toInt() ?? 0,
      totalRxBytes: (json['total_rx_bytes'] as num?)?.toInt() ?? 0,
      totalTxBytes: (json['total_tx_bytes'] as num?)?.toInt() ?? 0,
      openSocketCount: (json['open_socket_count'] as num?)?.toInt() ?? 0,
    );
  }
}
