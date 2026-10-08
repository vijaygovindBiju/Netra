import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';
import '../widgets/resizable_layout.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final Set<String> _expandedAppNames = {};

  // Card visibility state (allow removing / hiding cards)
  bool _showAppUsage = true;
  bool _showLinkDetails = true;
  bool _showHotspotClients = true;
  bool _showNearbyWifi = true;

  // Card collapsed state (allow colliding / folding cards)
  // By default, secondary bottom cards start collapsed to eliminate clutter!
  bool _collapseAppUsage = false;
  bool _collapseLinkDetails = false;
  bool _collapseHotspotClients = true;
  bool _collapseNearbyWifi = true;

  bool get _areAllCollapsed =>
      _collapseAppUsage &&
      _collapseLinkDetails &&
      _collapseHotspotClients &&
      _collapseNearbyWifi;

  void _toggleAllCollapsed() {
    final target = !_areAllCollapsed;
    setState(() {
      _collapseAppUsage = target;
      _collapseLinkDetails = target;
      _collapseHotspotClients = target;
      _collapseNearbyWifi = target;
    });
  }

  bool _showAllApps = false;

  void _toggleAllAppAccordions(List<NamedAppGroup> apps) {
    setState(() {
      final allExpanded = apps.isNotEmpty &&
          apps.every((a) => _expandedAppNames.contains(a.appName.toLowerCase()));
      if (allExpanded) {
        _expandedAppNames.clear();
      } else {
        _expandedAppNames.addAll(apps.map((a) => a.appName.toLowerCase()));
      }
    });
  }

  Widget _buildRestoreChip(String label, VoidCallback onRestore, NetraPalette colors) {
    return InkWell(
      onTap: onRestore,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 12, color: colors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

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

  void _toggleApp(String appName) {
    setState(() {
      if (_expandedAppNames.contains(appName)) {
        _expandedAppNames.remove(appName);
      } else {
        _expandedAppNames.add(appName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);
    final netState = ref.watch(networkStateProvider);
    final hsState = ref.watch(hotspotStateProvider);
    final trafficState = ref.watch(trafficStateProvider);
    final audioState = ref.watch(audioStateProvider);

    final activeDualAudioSink = audioState.sinks.where((s) => s.isVirtual && s.name.contains('NetraGroup_')).firstOrNull;
    final isDualAudioActive = activeDualAudioSink != null;
    final btAudioSinks = audioState.sinks.where((s) => s.isBluetooth && !s.isVirtual).toList();

    final metrics = netState.currentMetrics;
    final rxSpeed = _formatSpeed(metrics?.rxRateBps ?? 0);
    final txSpeed = _formatSpeed(metrics?.txRateBps ?? 0);

    // Connected Wi-Fi network information
    final connectedAp = netState.accessPoints.where((a) => a.isConnected).firstOrNull;
    final connectedSsid = connectedAp?.ssid ?? (netState.accessPoints.any((a) => a.isConnected) ? netState.accessPoints.firstWhere((a) => a.isConnected).ssid : null);

    // Total traffic on the active interface / Wi-Fi
    final totalInterfaceBytes = (metrics?.rxBytes ?? 0) + (metrics?.txBytes ?? 0);
    final totalAppTrafficBytes = trafficState.processes.fold<int>(0, (sum, p) => sum + p.totalRxBytes + p.totalTxBytes);
    final referenceNetworkBytes = totalInterfaceBytes > 0 ? totalInterfaceBytes : (totalAppTrafficBytes > 0 ? totalAppTrafficBytes : 1);

    // Group processes by same application name
    final namedAppGroups = AppCategorizer.groupByAppName(trafficState.processes);
    final displayedApps = _showAllApps ? namedAppGroups : namedAppGroups.take(5).toList();

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
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _toggleAllCollapsed,
                    icon: Icon(
                      _areAllCollapsed ? Icons.unfold_more : Icons.unfold_less,
                      size: 16,
                    ),
                    label: Text(_areAllCollapsed ? 'Expand All' : 'Collapse Cards'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
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
            ],
          ),
          if (!_showAppUsage || !_showLinkDetails || !_showHotspotClients || !_showNearbyWifi) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_off_outlined, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Hidden Cards:',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (!_showAppUsage)
                          _buildRestoreChip('App Usage', () => setState(() => _showAppUsage = true), colors),
                        if (!_showLinkDetails)
                          _buildRestoreChip('Link Details', () => setState(() => _showLinkDetails = true), colors),
                        if (!_showHotspotClients)
                          _buildRestoreChip('Hotspot Clients', () => setState(() => _showHotspotClients = true), colors),
                        if (!_showNearbyWifi)
                          _buildRestoreChip('Nearby Wi-Fi', () => setState(() => _showNearbyWifi = true), colors),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAppUsage = true;
                        _showLinkDetails = true;
                        _showHotspotClients = true;
                        _showNearbyWifi = true;
                      });
                    },
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Show All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          if (isDualAudioActive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.headphones, color: colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dual Bluetooth Audio Active • Synchronously streaming audio to multiple headphones',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(activeTabProvider.notifier).state = 3,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.green,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Manage in Bluetooth Tab', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else if (btAudioSinks.length >= 2) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.headphones, color: colors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${btAudioSinks.length} Bluetooth Headphones Connected • Ready for simultaneous Dual Audio streaming',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(activeTabProvider.notifier).state = 3,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Start Dual Stream', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

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

          // 2. Middle Section: Application Data Usage (Grouped by Same Name) & Interface Details
          ResizableSplitRow(
            initialRatio: 0.58,
            minRatio: 0.30,
            maxRatio: 0.75,
            spacing: 20.0,
            leftChild: _showAppUsage
                ? ResizableCard(
                    title: 'Application Data Usage',
                    icon: Icons.data_usage,
                    initialHeight: 410.0,
                    minHeight: 200.0,
                    maxHeight: 900.0,
                    padding: const EdgeInsets.all(16),
                    isCollapsed: _collapseAppUsage,
                    onCollapseChanged: (v) => setState(() => _collapseAppUsage = v),
                    onRemove: () => setState(() => _showAppUsage = false),
                    collapsedSummary: _buildSummaryPill(
                      '${displayedApps.length} Apps Active',
                      colors.primary,
                    ),
                    headerActions: [
                      if (namedAppGroups.length > 5)
                        InkWell(
                          onTap: () => setState(() => _showAllApps = !_showAllApps),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Text(
                              _showAllApps ? 'Top 5' : 'All (${namedAppGroups.length})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      Tooltip(
                        message: displayedApps.isNotEmpty &&
                                displayedApps.every((a) => _expandedAppNames.contains(a.appName.toLowerCase()))
                            ? 'Collapse all app groups'
                            : 'Expand all app groups',
                        child: InkWell(
                          onTap: () => _toggleAllAppAccordions(displayedApps),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              displayedApps.isNotEmpty &&
                                      displayedApps.every((a) => _expandedAppNames.contains(a.appName.toLowerCase()))
                                  ? Icons.unfold_less
                                  : Icons.unfold_more,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Open Traffic tab',
                        child: InkWell(
                          onTap: () => ref.read(activeTabProvider.notifier).state = 4,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    child: displayedApps.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Scanning network sockets across processes...',
                                style: TextStyle(color: colors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Active Network Baseline Anchor
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (connectedSsid != null ? colors.green : colors.primary)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (connectedSsid != null ? colors.green : colors.primary)
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      connectedSsid != null ? Icons.wifi : Icons.network_check,
                                      size: 15,
                                      color: connectedSsid != null ? colors.green : colors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        connectedSsid != null
                                            ? 'Connected Wi-Fi: $connectedSsid • Total: ${_formatBytes(referenceNetworkBytes)}'
                                            : 'Active Link: ${netState.primaryIface} • Total: ${_formatBytes(referenceNetworkBytes)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'Wi-Fi Share',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: connectedSsid != null ? colors.green : colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedApps.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, idx) {
                                  final app = displayedApps[idx];
                                  final isExpanded = _expandedAppNames.contains(app.appName.toLowerCase());
                                  final appTotalBytes = app.totalBytes;
                                  final wifiSharePct = referenceNetworkBytes > 0
                                      ? ((appTotalBytes / referenceNetworkBytes) * 100.0).clamp(0.0, 100.0)
                                      : 0.0;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isExpanded
                                            ? app.accentColor.withValues(alpha: colors.isDark ? 0.4 : 0.3)
                                            : colors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Collapsible App Header Tile ("Collision")
                                        InkWell(
                                          onTap: () => _toggleApp(app.appName.toLowerCase()),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(7),
                                                      decoration: BoxDecoration(
                                                        color: app.accentColor.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(app.icon, color: app.accentColor, size: 16),
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
                                                                  app.displayName,
                                                                  style: TextStyle(
                                                                    color: colors.textPrimary,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 13,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                                decoration: BoxDecoration(
                                                                  color: colors.surfaceCard,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(color: colors.border),
                                                                ),
                                                                child: Text(
                                                                  app.processCount == 1
                                                                      ? 'PID ${app.processes.first.pid}'
                                                                      : '${app.processCount} procs',
                                                                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 3),
                                                          Row(
                                                            children: [
                                                              Icon(Icons.wifi, size: 11, color: colors.green),
                                                              const SizedBox(width: 3),
                                                              Text(
                                                                connectedSsid != null
                                                                    ? '${wifiSharePct.toStringAsFixed(1)}% of "$connectedSsid"'
                                                                    : '${wifiSharePct.toStringAsFixed(1)}% of Wi-Fi traffic',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: colors.green,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                              Text(
                                                                ' • ↓ ${_formatSpeed(app.totalRxRate)}',
                                                                style: TextStyle(fontSize: 11, color: colors.textMuted),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    // Total Data with Wi-Fi Share
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: app.accentColor.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: app.accentColor.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(
                                                            _formatBytes(appTotalBytes),
                                                            style: TextStyle(
                                                              color: app.accentColor,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${wifiSharePct.toStringAsFixed(1)}% share',
                                                            style: TextStyle(
                                                              color: colors.textSecondary,
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    AnimatedRotation(
                                                      turns: isExpanded ? 0.5 : 0.0,
                                                      duration: const Duration(milliseconds: 200),
                                                      child: Icon(
                                                        Icons.keyboard_arrow_down,
                                                        color: colors.textSecondary,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Proportional Wi-Fi data usage bar
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: LinearProgressIndicator(
                                                    value: (wifiSharePct / 100.0).clamp(0.01, 1.0),
                                                    minHeight: 3.5,
                                                    backgroundColor: colors.border.withValues(alpha: 0.5),
                                                    valueColor: AlwaysStoppedAnimation<Color>(app.accentColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Expanded Workers Subtable (When Collapsible Tile is Opened)
                                        if (isExpanded) ...[
                                          Divider(color: colors.border, height: 1),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: Text(
                                                    'Worker Processes (${app.processCount}) • Breakdown on ${connectedSsid ?? 'Wi-Fi Network'}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: colors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                ...app.processes.map((proc) {
                                                  final pTotal = proc.totalRxBytes + proc.totalTxBytes;
                                                  final pShare = referenceNetworkBytes > 0
                                                      ? ((pTotal / referenceNetworkBytes) * 100.0).clamp(0.0, 100.0)
                                                      : 0.0;
                                                  final ratio = appTotalBytes > 0
                                                      ? (pTotal / appTotalBytes).clamp(0.05, 1.0)
                                                      : 0.05;

                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'PID ${proc.pid} (${proc.openSocketCount} sockets)',
                                                                style: TextStyle(
                                                                  color: colors.textPrimary,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${pShare.toStringAsFixed(1)}% of Wi-Fi • ↓ ${_formatSpeed(proc.rxRateBps)}',
                                                              style: TextStyle(color: colors.textMuted, fontSize: 10),
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Text(
                                                              _formatBytes(pTotal),
                                                              style: TextStyle(
                                                                color: colors.textPrimary,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 3),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(2),
                                                          child: LinearProgressIndicator(
                                                            value: ratio,
                                                            minHeight: 2.5,
                                                            backgroundColor: colors.border,
                                                            valueColor: AlwaysStoppedAnimation<Color>(app.accentColor),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                    )
                : null,
            rightChild: _showLinkDetails
                ? ResizableCard(
                    title: 'Active Link Details',
                    icon: Icons.router,
                    initialHeight: 410.0,
                    minHeight: 200.0,
                    maxHeight: 900.0,
                    padding: const EdgeInsets.all(16),
                    isCollapsed: _collapseLinkDetails,
                    onCollapseChanged: (v) => setState(() => _collapseLinkDetails = v),
                    onRemove: () => setState(() => _showLinkDetails = false),
                    collapsedSummary: _buildSummaryPill(
                      netState.accessPoints.any((a) => a.isConnected) ? 'Connected' : 'Standby',
                      netState.accessPoints.any((a) => a.isConnected) ? colors.green : colors.amber,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 16),
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
                  )
                : null,
          ),

          const SizedBox(height: 20),

          // 3. Bottom Row: Connected Devices & Visible Wi-Fi Networks
          ResizableSplitRow(
            initialRatio: 0.50,
            minRatio: 0.25,
            maxRatio: 0.75,
            spacing: 20.0,
            leftChild: _showHotspotClients
                ? ResizableCard(
                    title: 'Hotspot Clients',
                    icon: Icons.devices,
                    initialHeight: 330.0,
                    minHeight: 180.0,
                    maxHeight: 800.0,
                    padding: const EdgeInsets.all(16),
                    isCollapsed: _collapseHotspotClients,
                    onCollapseChanged: (v) => setState(() => _collapseHotspotClients = v),
                    onRemove: () => setState(() => _showHotspotClients = false),
                    collapsedSummary: _buildSummaryPill(
                      hsState.isActive ? '${hsState.clients.length} Active' : 'Offline',
                      hsState.isActive ? colors.green : colors.textMuted,
                    ),
                    headerActions: [
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
                    child: hsState.clients.isEmpty
                        ? Padding(
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
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: hsState.clients.length,
                            separatorBuilder: (_, _) => Divider(color: colors.border, height: 12),
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
                  )
                : null,
            rightChild: _showNearbyWifi
                ? ResizableCard(
                    title: 'Nearby Wi-Fi Networks',
                    icon: Icons.wifi_find,
                    initialHeight: 330.0,
                    minHeight: 180.0,
                    maxHeight: 800.0,
                    padding: const EdgeInsets.all(16),
                    isCollapsed: _collapseNearbyWifi,
                    onCollapseChanged: (v) => setState(() => _collapseNearbyWifi = v),
                    onRemove: () => setState(() => _showNearbyWifi = false),
                    collapsedSummary: _buildSummaryPill(
                      '${netState.accessPoints.length} Found',
                      colors.secondary,
                    ),
                    headerActions: [
                      Text(
                        '${netState.accessPoints.length} Found',
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                    child: netState.accessPoints.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'Scanning for wireless access points...',
                                style: TextStyle(color: colors.textMuted, fontSize: 12),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: netState.accessPoints.take(4).length,
                            separatorBuilder: (_, _) => Divider(color: colors.border, height: 12),
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
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatefulWidget {
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
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  static const double _initialHeight = 125.0;
  double? _height;
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);
    final curH = _height ?? _initialHeight;

    return Container(
      height: curH,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDragging ? colors.primary.withValues(alpha: 0.6) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
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
                          color: widget.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.icon, color: widget.iconColor, size: 16),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtext,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          // Interactive bottom drag handle
          MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () => setState(() => _height = _initialHeight),
              onVerticalDragStart: (_) => setState(() => _isDragging = true),
              onVerticalDragEnd: (_) => setState(() => _isDragging = false),
              onVerticalDragUpdate: (details) {
                setState(() {
                  final next = (curH + details.delta.dy).clamp(95.0, 260.0);
                  _height = next;
                });
              },
              child: Tooltip(
                message: 'Drag to resize card (${curH.toInt()}px) • Double-click to reset',
                waitDuration: const Duration(milliseconds: 300),
                child: Container(
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isDragging || _isHovering
                        ? colors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isDragging || _isHovering ? 32 : 18,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? colors.primary
                          : (_isHovering ? colors.primary.withValues(alpha: 0.7) : colors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
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
