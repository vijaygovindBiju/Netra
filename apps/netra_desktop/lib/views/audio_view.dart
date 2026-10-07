import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';
import '../widgets/resizable_layout.dart';

class AudioView extends ConsumerStatefulWidget {
  const AudioView({super.key});

  @override
  ConsumerState<AudioView> createState() => _AudioViewState();
}

class _AudioViewState extends ConsumerState<AudioView> {
  final Set<String> _selectedMultiSinkSlaves = {};
  final TextEditingController _groupNameController = TextEditingController(text: 'Dual Headphones');

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _showCreateDualAudioDialog(BuildContext context, List<AudioSinkItem> sinks) {
    final colors = NetraColors.of(context);

    // Pre-select Bluetooth sinks by default if none selected
    if (_selectedMultiSinkSlaves.isEmpty) {
      final btSinks = sinks.where((s) => !s.isVirtual && s.isBluetooth).toList();
      if (btSinks.isNotEmpty) {
        for (final s in btSinks) {
          _selectedMultiSinkSlaves.add(s.name);
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.border),
              ),
              title: Row(
                children: [
                  Icon(Icons.headset, color: colors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Create Multi-Device Audio Group',
                    style: TextStyle(color: colors.textPrimary, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast media playback across multiple Bluetooth headphones or speakers simultaneously with clock sync.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _groupNameController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Target Sinks to Sync:',
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${_selectedMultiSinkSlaves.length} Selected',
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sinks.where((s) => !s.isVirtual).length,
                        separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, idx) {
                          final sink = sinks.where((s) => !s.isVirtual).toList()[idx];
                          final isSelected = _selectedMultiSinkSlaves.contains(sink.name);

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: colors.primary,
                            checkColor: Colors.white,
                            secondary: Icon(
                              sink.isBluetooth ? Icons.bluetooth_audio : Icons.speaker,
                              color: sink.isBluetooth ? colors.primary : colors.textSecondary,
                              size: 18,
                            ),
                            title: Text(
                              sink.description.isNotEmpty ? sink.description : sink.name,
                              style: TextStyle(color: colors.textPrimary, fontSize: 13),
                            ),
                            subtitle: Text(sink.name, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  _selectedMultiSinkSlaves.add(sink.name);
                                } else {
                                  _selectedMultiSinkSlaves.remove(sink.name);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _selectedMultiSinkSlaves.length < 2
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          await ref.read(audioStateProvider.notifier).createDualAudio(
                                _groupNameController.text,
                                _selectedMultiSinkSlaves.toList(),
                              );
                        },
                  child: const Text('Create Synchronized Group', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);
    final audioState = ref.watch(audioStateProvider);
    final notifier = ref.read(audioStateProvider.notifier);

    // Bluetooth Audio Endpoints & Virtual Master
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
                    'PipeWire Audio Orchestrator',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Multi-Bluetooth simultaneous audio, latency compensation, and per-app stream routing',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDualAudioDialog(context, audioState.sinks),
                icon: const Icon(Icons.group_work, size: 16, color: Colors.white),
                label: const Text(
                  'Custom Multi-Sync',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          const SizedBox(height: 20),

          // 1-Click Dual Bluetooth Audio Quick Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDualAudioActive
                    ? [colors.green.withValues(alpha: 0.15), colors.primary.withValues(alpha: 0.08)]
                    : [colors.surfaceCard, colors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDualAudioActive ? colors.green.withValues(alpha: 0.45) : colors.border,
                width: isDualAudioActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
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
                            'Dual Bluetooth Headphones Sync',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDualAudioActive ? colors.green : colors.secondary).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isDualAudioActive ? 'BROADCASTING' : 'READY',
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
                            ? 'All application playback is currently streamed synchronously to dual audio endpoints'
                            : (btAudioSinks.length >= 2
                                ? 'Detected ${btAudioSinks.length} Bluetooth headphones: ${btAudioSinks.map((s) => s.description).join(" & ")}'
                                : (btAudioSinks.length == 1
                                    ? '1 Bluetooth headphone connected (${btAudioSinks.first.description}). Connect a 2nd pair in Bluetooth tab to sync.'
                                    : 'Connect 2 Bluetooth headphones/earbuds to stream audio simultaneously.')),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isDualAudioActive) ...[
                  ElevatedButton.icon(
                    onPressed: () => notifier.destroyDualAudio('Dual Bluetooth'),
                    icon: const Icon(Icons.stop, size: 16, color: Colors.white),
                    label: const Text('Stop Dual Stream', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else if (btAudioSinks.length >= 2) ...[
                  ElevatedButton.icon(
                    onPressed: () => notifier.createDualAudio('Dual Bluetooth', btAudioSinks.map((s) => s.name).toList()),
                    icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                    label: const Text('Sync Both Headphones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => ref.read(activeTabProvider.notifier).state = 3,
                    icon: const Icon(Icons.bluetooth, size: 15),
                    label: const Text('Bluetooth Center', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Application Audio Stream Routing Matrix
          ResizableCard(
            title: 'Per-Application Audio Routing Matrix (${audioState.streams.length})',
            icon: Icons.alt_route,
            initialHeight: 360.0,
            minHeight: 180.0,
            maxHeight: 900.0,
            padding: const EdgeInsets.all(16),
            child: audioState.streams.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No applications are currently playing audio',
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: audioState.streams.length,
                    separatorBuilder: (_, _) => Divider(color: colors.border, height: 12),
                    itemBuilder: (context, idx) {
                      final stream = audioState.streams[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colors.secondary.withValues(alpha: 0.15),
                              child: Icon(Icons.music_note, color: colors.secondary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stream.appName,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    stream.binaryName.isNotEmpty ? stream.binaryName : 'Stream #${stream.id}',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // Route Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.border),
                              ),
                              child: DropdownButton<int>(
                                value: audioState.sinks.any((s) => s.id == stream.currentSinkId)
                                    ? stream.currentSinkId
                                    : (audioState.sinks.isNotEmpty ? audioState.sinks.first.id : null),
                                dropdownColor: colors.surfaceCard,
                                underline: const SizedBox(),
                                style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                items: audioState.sinks.map((sink) {
                                  return DropdownMenuItem<int>(
                                    value: sink.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          sink.isBluetooth
                                              ? Icons.bluetooth_audio
                                              : (sink.isVirtual ? Icons.group_work : Icons.speaker),
                                          size: 15,
                                          color: sink.isVirtual ? colors.primary : colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(sink.description.length > 28
                                            ? '${sink.description.substring(0, 28)}...'
                                            : sink.description),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (targetId) {
                                  if (targetId != null) {
                                    notifier.routeStream(stream.id, targetId);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),

          // 2. Physical & Virtual Audio Sinks Panel
          ResizableCard(
            title: 'Audio Output Endpoints & Latency Sync (${audioState.sinks.length})',
            icon: Icons.speaker_group,
            initialHeight: 380.0,
            minHeight: 180.0,
            maxHeight: 900.0,
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: audioState.sinks.length,
                  separatorBuilder: (_, _) => Divider(color: colors.border, height: 16),
                  itemBuilder: (context, idx) {
                    final sink = audioState.sinks[idx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              sink.isBluetooth
                                  ? Icons.bluetooth_audio
                                  : (sink.isVirtual ? Icons.group_work : Icons.speaker),
                              color: sink.isVirtual ? colors.primary : colors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sink.description,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (sink.isDefault) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.green.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('DEFAULT OUTPUT',
                                    style: TextStyle(fontSize: 9, color: colors.green, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (sink.isVirtual) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('MULTI-AUDIO MASTER',
                                    style: TextStyle(fontSize: 9, color: colors.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Stop and remove multi-sync group',
                                icon: Icon(Icons.delete_outline, size: 18, color: colors.red),
                                onPressed: () {
                                  final groupName = sink.name.replaceFirst('NetraGroup_', '').replaceAll('_', ' ');
                                  notifier.destroyDualAudio(groupName);
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text('${sink.volumePercent}%',
                                style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            IconButton(
                              icon: Icon(
                                sink.isMuted ? Icons.volume_off : Icons.volume_up,
                                color: sink.isMuted ? colors.red : colors.textSecondary,
                                size: 18,
                              ),
                              onPressed: () => notifier.setMute(sink.id, !sink.isMuted),
                            ),
                          ],
                        ),
                        // Volume Slider
                        Slider(
                          value: sink.volumePercent.toDouble().clamp(0.0, 100.0),
                          min: 0,
                          max: 100,
                          activeColor: colors.primary,
                          inactiveColor: colors.surface,
                          onChanged: (val) => notifier.setVolume(sink.id, val.toInt()),
                        ),
                        // Latency Offset Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Text('Latency Compensation: ', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                              Text('${sink.latencyOffsetMs}ms',
                                  style: TextStyle(color: colors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: sink.latencyOffsetMs.toDouble().clamp(-100.0, 150.0),
                                  min: -100,
                                  max: 150,
                                  activeColor: colors.secondary,
                                  inactiveColor: colors.surface,
                                  onChanged: (val) => notifier.setLatencyOffset(sink.id, val.toInt()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
