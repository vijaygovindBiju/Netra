import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  String _formatSpeed(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = NetraColors.of(context);
    final netState = ref.watch(networkStateProvider);
    final hsState = ref.watch(hotspotStateProvider);
    final trafficState = ref.watch(trafficStateProvider);

    final metrics = netState.currentMetrics;
    final rxSpeed = _formatSpeed(metrics?.rxRateBps ?? 0);
    final txSpeed = _formatSpeed(metrics?.txRateBps ?? 0);

    // Sort processes by total data consumption or current rate
    final sortedProcesses = List<ProcessTrafficItem>.from(trafficState.processes)
      ..sort((a, b) {
        final totalA = a.totalRxBytes + a.totalTxBytes;
        final totalB = b.totalRxBytes + b.totalTxBytes;
        return totalB.compareTo(totalA);
      });
    final topProcesses = sortedProcesses.take(5).toList();

    final maxBytes = topProcesses.isNotEmpty
        ? (topProcesses.first.totalRxBytes + topProcesses.first.totalTxBytes)
        : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interface: ${netState.primaryIface} • Engine: Linux Native Subsystems',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(networkStateProvider.notifier).refreshScan();
                  ref.read(trafficStateProvider.notifier).refreshTraffic();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Telemetry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surfaceCard,
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Top Metrics Cards (Uniform Row Layout)
          Row(
            children: [
              // Download Speed
              Expanded(
                child: _MetricCard(
                  title: 'Download Speed',
                  value: rxSpeed,
                  icon: Icons.arrow_downward,
                  iconColor: colors.primary,
                  subtext: 'Interface: ${netState.primaryIface}',
                ),
              ),
              const SizedBox(width: 16),

              // Upload Speed
              Expanded(
                child: _MetricCard(
                  title: 'Upload Speed',
                  value: txSpeed,
                  icon: Icons.arrow_upward,
                  iconColor: colors.secondary,
                  subtext: 'Active Link Telemetry',
                ),
              ),
              const SizedBox(width: 16),

              // Wi-Fi Status
              Expanded(
                child: _MetricCard(
                  title: 'Wi-Fi Network',
                  value: netState.accessPoints.any((a) => a.isConnected)
                      ? netState.accessPoints.firstWhere((a) => a.isConnected).ssid
                      : 'Disconnected',
                  icon: Icons.wifi,
                  iconColor: colors.green,
                  subtext: '${netState.accessPoints.length} Networks visible',
                ),
              ),
              const SizedBox(width: 16),

              // Hotspot Status
              Expanded(
                child: _MetricCard(
                  title: 'Smart Hotspot',
                  value: hsState.isActive ? 'Active' : 'Offline',
                  icon: Icons.local_fire_department,
                  iconColor: hsState.isActive ? colors.amber : colors.textMuted,
                  subtext: hsState.isActive
                      ? '${hsState.clients.length} Clients connected'
                      : 'Tap Hotspot tab to start',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Middle Section: Application Data Usage & Interface Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Application Data Usage Card
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.data_usage, color: colors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Application Data Usage',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => ref.read(activeTabProvider.notifier).state = 4,
                            icon: const Icon(Icons.arrow_forward, size: 14),
                            label: const Text('View All'),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (topProcesses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Scanning network sockets across processes...',
                              style: TextStyle(color: colors.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProcesses.length,
                          separatorBuilder: (_, __) => Divider(color: colors.border, height: 16),
                          itemBuilder: (context, idx) {
                            final proc = topProcesses[idx];
                            final totalBytes = proc.totalRxBytes + proc.totalTxBytes;
                            final ratio = (maxBytes > 0)
                                ? (totalBytes / maxBytes).clamp(0.05, 1.0)
                                : 0.05;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: colors.secondary.withValues(alpha: 0.15),
                                      child: Icon(Icons.memory, color: colors.secondary, size: 14),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  proc.name,
                                                  style: TextStyle(
                                                    color: colors.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colors.surface,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: colors.border),
                                                ),
                                                child: Text(
                                                  'PID ${proc.pid}',
                                                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '↓ ${_formatSpeed(proc.rxRateBps)} • ↑ ${_formatSpeed(proc.txRateBps)}',
                                            style: TextStyle(fontSize: 11, color: colors.textMuted),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatBytes(totalBytes),
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${proc.openSocketCount} sockets',
                                          style: TextStyle(color: colors.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 4,
                                    backgroundColor: colors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      idx == 0 ? colors.primary : colors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Network Connection Overview Card
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.router, color: colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Active Link Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Interface',
                        value: netState.primaryIface,
                        colors: colors,
                      ),
                      _DetailRow(
                        label: 'Connection State',
                        value: netState.accessPoints.any((a) => a.isConnected) ? 'Connected' : 'Standby',
                        colors: colors,
                        valueColor: netState.accessPoints.any((a) => a.isConnected) ? colors.green : colors.amber,
                      ),
                      _DetailRow(
                        label: 'Total Downloaded',
                        value: _formatBytes(metrics?.rxBytes ?? 0),
                        colors: colors,
                      ),
                      _DetailRow(
                        label: 'Total Uploaded',
                        value: _formatBytes(metrics?.txBytes ?? 0),
                        colors: colors,
                      ),
                      _DetailRow(
                        label: 'Hotspot Engine',
                        value: hsState.isActive ? 'AP Active' : 'Offline',
                        colors: colors,
                        valueColor: hsState.isActive ? colors.amber : colors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(activeTabProvider.notifier).state = 1,
                          icon: const Icon(Icons.wifi, size: 16),
                          label: const Text('Manage Wi-Fi Networks'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Bottom Row: Connected Devices & Visible Wi-Fi Networks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connected Hotspot Clients
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.devices, color: colors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hotspot Clients',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.border,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${hsState.clients.length} Active',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (hsState.clients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.wifi_off, size: 32, color: colors.textMuted.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text(
                                  hsState.isActive
                                      ? 'Hotspot is active • Waiting for clients'
                                      : 'Hotspot is offline • Enable in Hotspot tab',
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hsState.clients.length,
                          separatorBuilder: (_, __) => Divider(color: colors.border, height: 12),
                          itemBuilder: (context, idx) {
                            final c = hsState.clients[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: colors.primary.withValues(alpha: 0.15),
                                child: Icon(Icons.phone_android, color: colors.primary, size: 16),
                              ),
                              title: Text(
                                c.hostname ?? c.vendor ?? c.macAddress,
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${c.ipAddress} • ${c.macAddress}',
                                style: TextStyle(color: colors.textSecondary, fontSize: 11),
                              ),
                              trailing: Chip(
                                label: Text(c.priority, style: const TextStyle(fontSize: 10)),
                                backgroundColor: colors.surface,
                                side: BorderSide(color: colors.border),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Available Wi-Fi Preview
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wifi_find, color: colors.secondary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nearby Wi-Fi Networks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${netState.accessPoints.length} Found',
                            style: TextStyle(fontSize: 11, color: colors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (netState.accessPoints.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Scanning for wireless access points...',
                              style: TextStyle(color: colors.textMuted, fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: netState.accessPoints.take(4).length,
                          separatorBuilder: (_, __) => Divider(color: colors.border, height: 12),
                          itemBuilder: (context, idx) {
                            final ap = netState.accessPoints[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              leading: Icon(
                                ap.signalStrength > 60
                                    ? Icons.wifi
                                    : (ap.signalStrength > 30 ? Icons.wifi_2_bar : Icons.wifi_1_bar),
                                color: ap.isConnected ? colors.green : colors.textSecondary,
                                size: 18,
                              ),
                              title: Text(
                                ap.ssid,
                                style: TextStyle(
                                  color: ap.isConnected ? colors.green : colors.textPrimary,
                                  fontWeight: ap.isConnected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${ap.band} • ${ap.security}',
                                style: TextStyle(color: colors.textMuted, fontSize: 11),
                              ),
                              trailing: Text(
                                '${ap.signalStrength}%',
                                style: TextStyle(
                                  color: ap.isConnected ? colors.green : colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String subtext;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final NetraPalette colors;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
