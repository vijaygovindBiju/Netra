import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

class TrafficView extends ConsumerStatefulWidget {
  const TrafficView({super.key});

  @override
  ConsumerState<TrafficView> createState() => _TrafficViewState();
}

class _TrafficViewState extends ConsumerState<TrafficView> {
  String _search = '';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    final trafficState = ref.watch(trafficStateProvider);
    final notifier = ref.read(trafficStateProvider.notifier);

    final filtered = trafficState.processes.where((p) {
      if (_search.isEmpty) return true;
      return p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.pid.toString().contains(_search);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Per-App Network Monitor',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NetraColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Real-time socket inspection and bandwidth consumption by process',
                    style: TextStyle(color: NetraColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.refreshTraffic(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Sockets'),
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

          // Search Field
          TextField(
            onChanged: (val) => setState(() => _search = val),
            style: const TextStyle(color: NetraColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filter processes by name or PID...',
              hintStyle: const TextStyle(color: NetraColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: NetraColors.textSecondary),
              filled: true,
              fillColor: NetraColors.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NetraColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NetraColors.border),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Process Table Container
          Container(
            decoration: BoxDecoration(
              color: NetraColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NetraColors.border),
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No network processes active matching filter',
                        style: TextStyle(color: NetraColors.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(color: NetraColors.border, height: 1),
                    itemBuilder: (context, idx) {
                      final proc = filtered[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: NetraColors.violet.withOpacity(0.15),
                          child: const Icon(Icons.memory, color: NetraColors.violet, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(
                              proc.name,
                              style: const TextStyle(
                                color: NetraColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: NetraColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: NetraColors.border),
                              ),
                              child: Text(
                                'PID ${proc.pid}',
                                style: const TextStyle(fontSize: 11, color: NetraColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: NetraColors.cyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${proc.openSocketCount} sockets',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: NetraColors.cyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            proc.cmdline.isNotEmpty ? proc.cmdline : 'Process #${proc.pid}',
                            style: const TextStyle(color: NetraColors.textMuted, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '↓ ${_formatSpeed(proc.rxRateBps)}  ↑ ${_formatSpeed(proc.txRateBps)}',
                              style: const TextStyle(
                                color: NetraColors.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${_formatBytes(proc.totalRxBytes + proc.totalTxBytes)}',
                              style: const TextStyle(color: NetraColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
