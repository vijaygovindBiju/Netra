import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';
import '../widgets/resizable_layout.dart';

class BluetoothView extends ConsumerWidget {
  const BluetoothView({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'AudioHeadset':
        return Icons.headphones;
      case 'AudioSpeaker':
        return Icons.speaker;
      case 'Phone':
        return Icons.smartphone;
      case 'InputKeyboard':
        return Icons.keyboard;
      case 'InputMouse':
        return Icons.mouse;
      default:
        return Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = NetraColors.of(context);
    final btState = ref.watch(bluetoothStateProvider);
    final notifier = ref.read(bluetoothStateProvider.notifier);
    final audioState = ref.watch(audioStateProvider);
    final audioNotifier = ref.read(audioStateProvider.notifier);
    final adapter = btState.adapter;
    final maxRecommendedStreams = adapter?.maxRecommendedAudioStreams ?? 3;
    final maxConnections = adapter?.maxActiveConnections ?? 7;

    // Detect Bluetooth audio output endpoints
    final btAudioSinks = audioState.sinks.where((s) => s.isBluetooth && !s.isVirtual).toList();
    final activeDualAudioSink = audioState.sinks.where((s) => s.isVirtual && s.name.contains('NetraGroup_')).firstOrNull;
    final isDualAudioActive = activeDualAudioSink != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Control Center',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pair, manage devices, monitor battery levels, and stream dual-headphone audio',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (btState.isScanning) {
                    notifier.stopScan();
                  } else {
                    notifier.startScan();
                  }
                },
                icon: btState.isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        btState.isScanning ? Icons.stop : Icons.bluetooth_searching,
                        size: 18,
                        color: Colors.white,
                      ),
                label: Text(
                  btState.isScanning ? 'Stop Discovery' : 'Discover Devices',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Hardware Bluetooth Controller & Multi-Stream Capacity Card
          if (adapter != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.memory, color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  adapter.chipsetName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Bluetooth ${adapter.bluetoothVersion}',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${adapter.manufacturer} • HCI Rev ${adapter.hciVersion} • MAC: ${adapter.address}',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // Real-time Hardware Stream Capacity Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.headphones,
                                  size: 14,
                                  color: btAudioSinks.length > maxRecommendedStreams ? colors.amber : colors.green,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Max Audio: $maxRecommendedStreams Streams',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: btAudioSinks.length > maxRecommendedStreams ? colors.amber : colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Piconet ACL Limit: $maxConnections Devices',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: colors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildHwFeatureBadge('2M PHY (High Bandwidth)', adapter.supports2mPhy, colors, '500+ kbps packet throughput'),
                      const SizedBox(width: 8),
                      _buildHwFeatureBadge('LE Audio / LC3 Ready', adapter.supportsLeAudio, colors, 'Isochronous audio broadcasting'),
                      const SizedBox(width: 8),
                      _buildHwFeatureBadge('Controller Powered', adapter.isPowered, colors, 'Hardware radio online'),
                      const Spacer(),
                      Text(
                        'Active Audio Sinks: ${btAudioSinks.length} / $maxRecommendedStreams capacity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: btAudioSinks.length > maxRecommendedStreams ? colors.amber : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Multi-Headphone Audio Streamer Panel
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDualAudioActive
                    ? [colors.green.withValues(alpha: 0.14), colors.primary.withValues(alpha: 0.08)]
                    : [colors.surfaceCard, colors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDualAudioActive
                    ? colors.green.withValues(alpha: 0.45)
                    : colors.border,
                width: isDualAudioActive ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDualAudioActive ? colors.green : colors.primary).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.headphones,
                        color: isDualAudioActive ? colors.green : colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Multi-Headphone Audio Streaming',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDualAudioActive ? colors.green : colors.secondary).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDualAudioActive
                                      ? 'BROADCASTING TO ${btAudioSinks.length} HEADPHONES'
                                      : 'PIPEWIRE MULTI-SYNC (UP TO $maxRecommendedStreams)',
                                  style: TextStyle(
                                    color: isDualAudioActive ? colors.green : colors.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDualAudioActive
                                ? 'Synchronously broadcasting system audio to multiple Bluetooth headphones via PipeWire combined sink'
                                : (btAudioSinks.length >= 2
                                    ? '${btAudioSinks.length} Bluetooth headphones ready (Hardware capacity: up to $maxRecommendedStreams simultaneously)'
                                    : (btAudioSinks.length == 1
                                        ? '1 Bluetooth headphone connected. Connect additional pairs to stream to up to $maxRecommendedStreams simultaneously.'
                                        : 'Connect 2 or more Bluetooth headphones to stream audio simultaneously with zero echo.')),
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isDualAudioActive) ...[
                      ElevatedButton.icon(
                        onPressed: () => audioNotifier.destroyDualAudio('Dual Bluetooth'),
                        icon: const Icon(Icons.stop, size: 16, color: Colors.white),
                        label: const Text('Stop Multi-Stream', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ] else if (btAudioSinks.length >= 2) ...[
                      ElevatedButton.icon(
                        onPressed: () => audioNotifier.createDualAudio('Dual Bluetooth', btAudioSinks.map((s) => s.name).toList()),
                        icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                        label: Text('Sync All ${btAudioSinks.length} Headphones', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => ref.read(activeTabProvider.notifier).state = 5,
                        icon: const Icon(Icons.tune, size: 15),
                        label: const Text('Audio Orchestrator', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ],
                ),

                // Bandwidth Warning if sinks exceed recommended capacity
                if (btAudioSinks.length > maxRecommendedStreams) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bandwidth Capacity Notice: Controller recommends up to $maxRecommendedStreams concurrent audio streams. '
                            'Streaming to ${btAudioSinks.length} headphones simultaneously may cause 2.4GHz RF packet drops or jitter.',
                            style: TextStyle(fontSize: 11, color: colors.amber, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Connected Audio Headphone Devices Chips
                if (btAudioSinks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: btAudioSinks.map((sink) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDualAudioActive ? colors.green.withValues(alpha: 0.3) : colors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.headphones, size: 14, color: isDualAudioActive ? colors.green : colors.primary),
                            const SizedBox(width: 6),
                            Text(
                              sink.description.isNotEmpty ? sink.description : sink.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${sink.volumePercent}%',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Active Dual Streaming Controls (Volume & Latency compensation)
                if (activeDualAudioSink != null) ...[
                  const SizedBox(height: 14),
                  Divider(color: colors.border, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Combined Master Volume
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Master Stream Volume', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
                                Text('${activeDualAudioSink.volumePercent}%', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Slider(
                              value: activeDualAudioSink.volumePercent.toDouble().clamp(0.0, 100.0),
                              min: 0,
                              max: 100,
                              activeColor: colors.primary,
                              inactiveColor: colors.surface,
                              onChanged: (val) => audioNotifier.setVolume(activeDualAudioSink.id, val.toInt()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Latency Sync Offset
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Acoustic Sync Delay / Offset', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
                                Text('${activeDualAudioSink.latencyOffsetMs} ms', style: TextStyle(fontSize: 12, color: colors.secondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Slider(
                              value: activeDualAudioSink.latencyOffsetMs.toDouble().clamp(-100.0, 150.0),
                              min: -100,
                              max: 150,
                              activeColor: colors.secondary,
                              inactiveColor: colors.surface,
                              onChanged: (val) => audioNotifier.setLatencyOffset(activeDualAudioSink.id, val.toInt()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Connected & Paired Devices Section
          ResizableCard(
            title: 'Bluetooth Devices (${btState.devices.length})',
            icon: Icons.bluetooth,
            initialHeight: 460.0,
            minHeight: 220.0,
            maxHeight: 1000.0,
            padding: EdgeInsets.zero,
            child: btState.devices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.bluetooth_disabled, size: 36, color: colors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No Bluetooth devices found. Click Discover to scan.',
                            style: TextStyle(color: colors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: btState.devices.length,
                    separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
                    itemBuilder: (context, idx) {
                      final device = btState.devices[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: device.isConnected
                                ? colors.primary.withValues(alpha: 0.15)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: device.isConnected
                                  ? colors.primary.withValues(alpha: 0.3)
                                  : colors.border,
                            ),
                          ),
                          child: Icon(
                            _getCategoryIcon(device.category),
                            color: device.isConnected ? colors.primary : colors.textSecondary,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              device.alias.isNotEmpty ? device.alias : device.name,
                              style: TextStyle(
                                color: device.isConnected ? colors.primary : colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (device.isConnected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CONNECTED',
                                  style: TextStyle(
                                    color: colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (device.batteryPercentage != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.battery_charging_full, size: 12, color: colors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${device.batteryPercentage}%',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${device.address} • ${device.isPaired ? "Paired" : "Discovered"}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (device.isConnected)
                              OutlinedButton(
                                onPressed: () => notifier.disconnect(device.address),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.red,
                                  side: BorderSide(color: colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Disconnect'),
                              )
                            else if (device.isPaired)
                              ElevatedButton(
                                onPressed: () => notifier.connect(device.address),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => notifier.pair(device.address),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.surface,
                                  foregroundColor: colors.primary,
                                  side: BorderSide(color: colors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Pair'),
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

  Widget _buildHwFeatureBadge(String title, bool active, NetraPalette colors, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? colors.green.withValues(alpha: 0.12) : colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? colors.green.withValues(alpha: 0.3) : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_circle : Icons.remove_circle_outline,
              size: 13,
              color: active ? colors.green : colors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? colors.green : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

