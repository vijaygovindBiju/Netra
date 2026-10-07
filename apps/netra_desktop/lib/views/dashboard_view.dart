import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  String _formatSpeed(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netState = ref.watch(networkStateProvider);
    final hsState = ref.watch(hotspotStateProvider);

    final metrics = netState.currentMetrics;
    final rxSpeed = _formatSpeed(metrics?.rxRateBps ?? 0);
    final txSpeed = _formatSpeed(metrics?.txRateBps ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Control Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NetraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Interface: ${netState.primaryIface} • Engine: Linux Native',
                    style: const TextStyle(
                      color: NetraColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(networkStateProvider.notifier).refreshScan(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Telemetry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NetraColors.surfaceCard,
                  foregroundColor: NetraColors.cyan,
                  side: const BorderSide(color: NetraColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Top Metrics Cards Grid
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              // 1. Download Speed
              _MetricCard(
                title: 'Download Speed',
                value: rxSpeed,
                icon: Icons.arrow_downward,
                iconColor: NetraColors.cyan,
                subtext: 'Interface: ${netState.primaryIface}',
              ),

              // 2. Upload Speed
              _MetricCard(
                title: 'Upload Speed',
                value: txSpeed,
                icon: Icons.arrow_upward,
                iconColor: NetraColors.violet,
                subtext: 'Active Link',
              ),

              // 3. Wi-Fi Status
              _MetricCard(
                title: 'Wi-Fi Network',
                value: netState.accessPoints.any((a) => a.isConnected)
                    ? netState.accessPoints.firstWhere((a) => a.isConnected).ssid
                    : 'Disconnected',
                icon: Icons.wifi,
                iconColor: NetraColors.green,
                subtext: '${netState.accessPoints.length} Networks visible',
              ),

              // 4. Hotspot Status
              _MetricCard(
                title: 'Smart Hotspot',
                value: hsState.isActive ? 'Active' : 'Offline',
                icon: Icons.local_fire_department,
                iconColor: hsState.isActive ? NetraColors.amber : NetraColors.textMuted,
                subtext: hsState.isActive
                    ? '${hsState.clients.length} Clients connected'
                    : 'Tap Hotspot tab to start',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Quick Action Cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connected Hotspot Clients Quick View
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: NetraColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NetraColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.devices, color: NetraColors.cyan, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Connected Devices',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: NetraColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: NetraColors.border,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${hsState.clients.length} Active',
                              style: const TextStyle(fontSize: 12, color: NetraColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (hsState.clients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.wifi_off, size: 36, color: NetraColors.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                const Text(
                                  'No devices currently connected to hotspot',
                                  style: TextStyle(color: NetraColors.textMuted, fontSize: 13),
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
                          separatorBuilder: (_, __) => const Divider(color: NetraColors.border),
                          itemBuilder: (context, idx) {
                            final c = hsState.clients[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: NetraColors.cyan.withOpacity(0.15),
                                child: const Icon(Icons.phone_android, color: NetraColors.cyan, size: 18),
                              ),
                              title: Text(
                                c.hostname ?? c.vendor ?? c.macAddress,
                                style: const TextStyle(color: NetraColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${c.ipAddress} • ${c.macAddress}',
                                style: const TextStyle(color: NetraColors.textSecondary, fontSize: 12),
                              ),
                              trailing: Chip(
                                label: Text(c.priority, style: const TextStyle(fontSize: 11)),
                                backgroundColor: NetraColors.surface,
                                side: const BorderSide(color: NetraColors.border),
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
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: NetraColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NetraColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wifi_find, color: NetraColors.violet, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Visible Wi-Fi Networks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: NetraColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (netState.accessPoints.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              'Scanning for wireless networks...',
                              style: TextStyle(color: NetraColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: netState.accessPoints.take(5).length,
                          separatorBuilder: (_, __) => const Divider(color: NetraColors.border),
                          itemBuilder: (context, idx) {
                            final ap = netState.accessPoints[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                ap.signalStrength > 60
                                    ? Icons.wifi
                                    : (ap.signalStrength > 30 ? Icons.wifi_2_bar : Icons.wifi_1_bar),
                                color: ap.isConnected ? NetraColors.green : NetraColors.textSecondary,
                              ),
                              title: Text(
                                ap.ssid,
                                style: TextStyle(
                                  color: ap.isConnected ? NetraColors.green : NetraColors.textPrimary,
                                  fontWeight: ap.isConnected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                '${ap.band} • ${ap.security}',
                                style: const TextStyle(color: NetraColors.textSecondary, fontSize: 12),
                              ),
                              trailing: Text(
                                '${ap.signalStrength}%',
                                style: const TextStyle(color: NetraColors.textSecondary, fontSize: 13),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NetraColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NetraColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: NetraColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: NetraColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtext,
            style: const TextStyle(
              color: NetraColors.textMuted,
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
