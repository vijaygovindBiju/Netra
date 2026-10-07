import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_models.dart';
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
  bool _isGroupedView = true;
  final Set<AppCategoryType> _expandedCategories = {
    AppCategoryType.browsers,
    AppCategoryType.communication,
    AppCategoryType.media,
    AppCategoryType.gaming,
    AppCategoryType.development,
    AppCategoryType.system,
    AppCategoryType.other,
  };

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

  void _toggleCategory(AppCategoryType type) {
    setState(() {
      if (_expandedCategories.contains(type)) {
        _expandedCategories.remove(type);
      } else {
        _expandedCategories.add(type);
      }
    });
  }

  void _expandAll(List<AppGroup> groups) {
    setState(() {
      _expandedCategories.addAll(groups.map((g) => g.type));
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedCategories.clear();
    });
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
          p.pid.toString().contains(_search) ||
          p.cmdline.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    // Grouping
    final appGroups = AppCategorizer.groupProcesses(filtered);

    // Sort flat list
    final flatList = List<ProcessTrafficItem>.from(filtered);
    if (_sortBy == 'data') {
      flatList.sort((a, b) => (b.totalRxBytes + b.totalTxBytes).compareTo(a.totalRxBytes + a.totalTxBytes));
    } else if (_sortBy == 'speed') {
      flatList.sort((a, b) => (b.rxRateBps + b.txRateBps).compareTo(a.rxRateBps + a.txRateBps));
    } else if (_sortBy == 'name') {
      flatList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
              Expanded(
                child: Column(
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
                      'Live process socket telemetry, app category grouping, and bandwidth consumption',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  subtext: '${appGroups.length} App Categories',
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

          // Search & View Controls Bar
          Row(
            children: [
              // Search Input
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _search = val),
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filter processes by name, command, or PID...',
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
              const SizedBox(width: 12),

              // View Mode Selector (Grouped vs Flat)
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    _ViewModeButton(
                      label: 'Collapsible Groups',
                      icon: Icons.folder_outlined,
                      isSelected: _isGroupedView,
                      onTap: () => setState(() => _isGroupedView = true),
                      colors: colors,
                    ),
                    _ViewModeButton(
                      label: 'Flat List',
                      icon: Icons.list_alt,
                      isSelected: !_isGroupedView,
                      onTap: () => setState(() => _isGroupedView = false),
                      colors: colors,
                    ),
                  ],
                ),
              ),

              if (_isGroupedView) ...[
                const SizedBox(width: 12),
                // Expand / Collapse All
                OutlinedButton.icon(
                  onPressed: () {
                    if (_expandedCategories.isEmpty) {
                      _expandAll(appGroups);
                    } else {
                      _collapseAll();
                    }
                  },
                  icon: Icon(
                    _expandedCategories.isEmpty ? Icons.unfold_more : Icons.unfold_less,
                    size: 16,
                  ),
                  label: Text(_expandedCategories.isEmpty ? 'Expand All' : 'Collapse All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
                // Sort Dropdown
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
                        DropdownMenuItem(value: 'speed', child: Text('Sort by Speed')),
                        DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Main Content View
          if (_isGroupedView)
            _buildGroupedView(appGroups, colors)
          else
            _buildFlatView(flatList, colors),
        ],
      ),
    );
  }

  // 1. Collapsible Grouped Accordion View
  Widget _buildGroupedView(List<AppGroup> groups, NetraPalette colors) {
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Text(
            'No matching network processes in any category',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final group = groups[idx];
        final isExpanded = _expandedCategories.contains(group.type);
        final groupTotalBytes = group.totalBytes;

        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? group.accentColor.withValues(alpha: colors.isDark ? 0.35 : 0.25)
                  : colors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accordion Header Tile
              InkWell(
                onTap: () => _toggleCategory(group.type),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      // Category Icon with Accent Container
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: group.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(group.icon, color: group.accentColor, size: 20),
                      ),
                      const SizedBox(width: 14),

                      // Category Title & Count
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              group.title,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                '${group.processes.length} app${group.processes.length == 1 ? "" : "s"}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Aggregate Speed
                      Text(
                        '↓ ${_formatSpeed(group.totalRxRate)} • ↑ ${_formatSpeed(group.totalTxRate)}',
                        style: TextStyle(
                          color: colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Aggregate Total Data
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: group.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatBytes(groupTotalBytes),
                          style: TextStyle(
                            color: group.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Expand / Collapse Chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Accordion Body (Collapsible Process Subtable)
              if (isExpanded) ...[
                Divider(color: colors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.processes.length,
                    separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
                    itemBuilder: (context, pIdx) {
                      final proc = group.processes[pIdx];
                      final procTotalBytes = proc.totalRxBytes + proc.totalTxBytes;
                      final ratio = (groupTotalBytes > 0)
                          ? (procTotalBytes / groupTotalBytes).clamp(0.05, 1.0)
                          : 0.05;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Process Name & PID
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: group.accentColor.withValues(alpha: 0.15),
                                        child: Text(
                                          proc.name.isNotEmpty ? proc.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: group.accentColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                                                      fontSize: 13,
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
                                  child: Text(
                                    '${proc.openSocketCount} sockets',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                  ),
                                ),

                                // Speed
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '↓ ${_formatSpeed(proc.rxRateBps)}  ↑ ${_formatSpeed(proc.txRateBps)}',
                                    style: TextStyle(
                                      color: colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),

                                // Data Usage Total
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatBytes(procTotalBytes),
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Proportion bar relative to category
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 3,
                                backgroundColor: colors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(group.accentColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 2. Flat Process List View
  Widget _buildFlatView(List<ProcessTrafficItem> list, NetraPalette colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
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
          list.isEmpty
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
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
                  itemBuilder: (context, idx) {
                    final proc = list[idx];
                    final totalProcBytes = proc.totalRxBytes + proc.totalTxBytes;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
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
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final NetraPalette colors;

  const _ViewModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: colors.isDark ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
