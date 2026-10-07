import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

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
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: NetraColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: NetraColors.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.headset, color: NetraColors.cyan),
                  SizedBox(width: 10),
                  Text(
                    'Create Multi-Device Audio Group',
                    style: TextStyle(color: NetraColors.textPrimary, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Broadcast media playback across multiple Bluetooth headphones or speakers simultaneously with clock sync.',
                      style: TextStyle(color: NetraColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _groupNameController,
                      style: const TextStyle(color: NetraColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: const TextStyle(color: NetraColors.textSecondary),
                        filled: true,
                        fillColor: NetraColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: NetraColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Target Sinks to Sync:', style: TextStyle(color: NetraColors.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: NetraColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: NetraColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sinks.where((s) => !s.isVirtual).length,
                        separatorBuilder: (_, __) => const Divider(color: NetraColors.border, height: 1),
                        itemBuilder: (context, idx) {
                          final sink = sinks.where((s) => !s.isVirtual).toList()[idx];
                          final isSelected = _selectedMultiSinkSlaves.contains(sink.name);

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: NetraColors.cyan,
                            checkColor: Colors.black,
                            title: Text(
                              sink.description.isNotEmpty ? sink.description : sink.name,
                              style: const TextStyle(color: NetraColors.textPrimary, fontSize: 13),
                            ),
                            subtitle: Text(sink.name, style: const TextStyle(color: NetraColors.textMuted, fontSize: 11)),
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
                  child: const Text('Cancel', style: TextStyle(color: NetraColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NetraColors.cyan,
                    foregroundColor: Colors.black,
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
    final audioState = ref.watch(audioStateProvider);
    final notifier = ref.read(audioStateProvider.notifier);

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
                    'PipeWire Audio Orchestrator',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NetraColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Multi-Bluetooth simultaneous audio, latency compensation, and per-app stream routing',
                    style: TextStyle(color: NetraColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDualAudioDialog(context, audioState.sinks),
                icon: const Icon(Icons.group_work, size: 18, color: Colors.black),
                label: const Text(
                  'Create Multi-Device Sync',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NetraColors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 1. Application Audio Stream Routing Matrix
          Container(
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
                    Icon(Icons.alt_route, color: NetraColors.cyan, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Per-Application Audio Routing Matrix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: NetraColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (audioState.streams.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No applications are currently playing audio',
                        style: TextStyle(color: NetraColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: audioState.streams.length,
                    separatorBuilder: (_, __) => const Divider(color: NetraColors.border),
                    itemBuilder: (context, idx) {
                      final stream = audioState.streams[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: NetraColors.violet.withOpacity(0.15),
                              child: const Icon(Icons.music_note, color: NetraColors.violet, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stream.appName,
                                    style: const TextStyle(
                                      color: NetraColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    stream.binaryName.isNotEmpty ? stream.binaryName : 'Stream #${stream.id}',
                                    style: const TextStyle(color: NetraColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Route Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: NetraColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: NetraColors.border),
                              ),
                              child: DropdownButton<int>(
                                value: audioState.sinks.any((s) => s.id == stream.currentSinkId)
                                    ? stream.currentSinkId
                                    : (audioState.sinks.isNotEmpty ? audioState.sinks.first.id : null),
                                dropdownColor: NetraColors.surfaceCard,
                                underline: const SizedBox(),
                                style: const TextStyle(color: NetraColors.cyan, fontSize: 13, fontWeight: FontWeight.bold),
                                items: audioState.sinks.map((sink) {
                                  return DropdownMenuItem<int>(
                                    value: sink.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          sink.isBluetooth
                                              ? Icons.bluetooth_audio
                                              : (sink.isVirtual ? Icons.group_work : Icons.speaker),
                                          size: 16,
                                          color: sink.isVirtual ? NetraColors.cyan : NetraColors.textSecondary,
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
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 2. Physical & Virtual Audio Sinks Panel
          Container(
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
                    Icon(Icons.speaker_group, color: NetraColors.violet, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Audio Output Endpoints & Latency Sync',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: NetraColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: audioState.sinks.length,
                  separatorBuilder: (_, __) => const Divider(color: NetraColors.border),
                  itemBuilder: (context, idx) {
                    final sink = audioState.sinks[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                sink.isBluetooth
                                    ? Icons.bluetooth_audio
                                    : (sink.isVirtual ? Icons.group_work : Icons.speaker),
                                color: sink.isVirtual ? NetraColors.cyan : NetraColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  sink.description,
                                  style: const TextStyle(
                                    color: NetraColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (sink.isVirtual) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: NetraColors.cyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('MULTI-AUDIO MASTER',
                                      style: TextStyle(fontSize: 10, color: NetraColors.cyan, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Text('${sink.volumePercent}%',
                                  style: const TextStyle(color: NetraColors.cyan, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(
                                  sink.isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: sink.isMuted ? NetraColors.red : NetraColors.textSecondary,
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
                            activeColor: NetraColors.cyan,
                            inactiveColor: NetraColors.surface,
                            onChanged: (val) => notifier.setVolume(sink.id, val.toInt()),
                          ),
                          // Latency Offset Slider (Sync Dual Headphones)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Text('Latency Compensation: ', style: TextStyle(color: NetraColors.textMuted, fontSize: 11)),
                                Text('${sink.latencyOffsetMs}ms',
                                    style: const TextStyle(color: NetraColors.violet, fontSize: 11, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Slider(
                                    value: sink.latencyOffsetMs.toDouble().clamp(-100.0, 150.0),
                                    min: -100,
                                    max: 150,
                                    activeColor: NetraColors.violet,
                                    inactiveColor: NetraColors.surface,
                                    onChanged: (val) => notifier.setLatencyOffset(sink.id, val.toInt()),
                                  ),
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
