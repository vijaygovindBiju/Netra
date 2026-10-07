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
  String _sortBy = 'data'; // 'data', 'speed', 'name'

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
    final colors = NetraColors.of(context);
    final trafficState = ref.watch(trafficStateProvider);
    final notifier = ref.read(trafficStateProvider.notifier);

    // Compute totals
    int totalRxRate = 0;
    int totalTxRate = 0;
    int totalBytes = 0;
    for (final p in trafficState.processes) {
      totalRxRate += p.rxRateBps;
      totalTxRate += p.txRateBps;
      totalBytes += (p.totalRxBytes + p.totalTxBytes);
    }

    final filtered = trafficState.processes.where((p) {
      if (_search.isEmpty) return true;
      return p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.pid.toString().contains(_search);
    }).toList();

    // Sort
    if (_sortBy == 'data') {
      filtered.sort((a, b) => (b.totalRxBytes + b.totalTxBytes).compareTo(a.totalRxBytes + a.totalTxBytes));
    } else if (_sortBy == 'speed') {
      filtered.sort((a, b) => (b.rxRateBps + b.txRateBps).compareTo(a.rxRateBps + a.txRateBps));
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Per-App Network Monitor',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live process socket telemetry and application data consumption',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.refreshTraffic(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Sockets'),
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

          // Summary Metric Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Network Processes',
                  value: '${trafficState.processes.length}',
                  subtext: 'Active Socket Listeners',
                  icon: Icons.memory,
                  iconColor: colors.primary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total Process Down',
                  value: _formatSpeed(totalRxRate),
                  subtext: 'Inbound Socket Rate',
                  icon: Icons.arrow_downward,
                  iconColor: colors.green,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total Process Up',
                  value: _formatSpeed(totalTxRate),
                  subtext: 'Outbound Socket Rate',
                  icon: Icons.arrow_upward,
                  iconColor: colors.secondary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Cumulative Data',
                  value: _formatBytes(totalBytes),
                  subtext: 'Recorded Socket Traffic',
                  icon: Icons.pie_chart_outline,
                  iconColor: colors.amber,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _search = val),
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filter processes by name or PID...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 18),
                    filled: true,
                    fillColor: colors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: colors.surfaceCard,
                    icon: Icon(Icons.sort, color: colors.primary, size: 18),
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'data', child: Text('Sort by Total Data')),
                      DropdownMenuItem(value: 'speed', child: Text('Sort by Current Speed')),
                      DropdownMenuItem(value: 'name', child: Text('Sort by Process Name')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Process Table Container
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                // Table Column Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'PROCESS / APPLICATION',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'OPEN SOCKETS',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'REAL-TIME SPEED',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'DATA USAGE',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.border, height: 1),

                // Table List
                filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No network processes active matching filter',
                            style: TextStyle(color: colors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, idx) {
                          final proc = filtered[idx];
                          final totalProcBytes = proc.totalRxBytes + proc.totalTxBytes;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                // Process & PID
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor: colors.secondary.withValues(alpha: 0.15),
                                        child: Icon(Icons.memory, color: colors.secondary, size: 16),
                                      ),
                                      const SizedBox(width: 12),
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
                                              proc.cmdline.isNotEmpty ? proc.cmdline : 'Process #${proc.pid}',
                                              style: TextStyle(color: colors.textMuted, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Sockets
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${proc.openSocketCount} sockets',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Speed
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '↓ ${_formatSpeed(proc.rxRateBps)}',
                                        style: TextStyle(
                                          color: colors.green,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '↑ ${_formatSpeed(proc.txRateBps)}',
                                        style: TextStyle(
                                          color: colors.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Data Usage Total
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatBytes(totalProcBytes),
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '↓ ${_formatBytes(proc.totalRxBytes)}',
                                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color iconColor;
  final NetraPalette colors;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.iconColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                title,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
