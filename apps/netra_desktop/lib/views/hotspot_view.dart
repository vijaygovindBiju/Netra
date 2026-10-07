import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

class HotspotView extends ConsumerStatefulWidget {
  const HotspotView({super.key});

  @override
  ConsumerState<HotspotView> createState() => _HotspotViewState();
}

class _HotspotViewState extends ConsumerState<HotspotView> {
  late TextEditingController _ssidController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final config = ref.read(hotspotStateProvider).config;
    _ssidController = TextEditingController(text: config.ssid);
    _passwordController = TextEditingController(text: config.passphrase);
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);
    final hsState = ref.watch(hotspotStateProvider);
    final notifier = ref.read(hotspotStateProvider.notifier);

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
                    'Smart Hotspot',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One-click AP tethering, connected device tracking, and QoS control',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: hsState.isLoading ? null : () => notifier.toggleHotspot(),
                icon: hsState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        hsState.isActive ? Icons.stop : Icons.play_arrow,
                        size: 18,
                        color: Colors.white,
                      ),
                label: Text(
                  hsState.isActive ? 'Stop Hotspot' : 'Start Hotspot',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hsState.isActive ? colors.red : colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hotspot Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hsState.isActive ? colors.primary.withValues(alpha: 0.5) : colors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (hsState.isActive ? colors.primary : colors.textMuted).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: hsState.isActive ? colors.primary : colors.textMuted,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hsState.isActive ? 'HOTSPOT IS BROADCASTING' : 'HOTSPOT IS OFFLINE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: hsState.isActive ? colors.primary : colors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (hsState.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${hsState.config.band} BAND',
                                style: TextStyle(
                                  color: colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hsState.isActive
                            ? 'Broadcasting "${hsState.config.ssid}" • ${hsState.clients.length} device(s) connected'
                            : 'Configure SSID and security below, then start your hotspot',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Configuration and Connected Clients Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hotspot Configuration Settings
              Expanded(
                flex: 4,
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
                          Icon(Icons.tune, color: colors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // SSID Field
                      Text('Network Name (SSID)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _ssidController,
                        enabled: !hsState.isActive,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        onChanged: (val) => notifier.updateConfig(ssid: val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      Text('WPA2/WPA3 Passphrase', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        enabled: !hsState.isActive,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        onChanged: (val) => notifier.updateConfig(passphrase: val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Frequency Band Selection
                      Text('Frequency Band', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _BandSelectorButton(
                              label: '2.4 GHz (Long Range)',
                              isSelected: hsState.config.band == '2.4GHz',
                              enabled: !hsState.isActive,
                              onTap: () => notifier.updateConfig(band: '2.4GHz'),
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BandSelectorButton(
                              label: '5 GHz (High Speed)',
                              isSelected: hsState.config.band == '5GHz',
                              enabled: !hsState.isActive,
                              onTap: () => notifier.updateConfig(band: '5GHz'),
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // 2. Connected Clients & QoS Management
              Expanded(
                flex: 6,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.devices, color: colors.secondary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Connected Devices & QoS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(
                              '${hsState.clients.length} Devices',
                              style: TextStyle(fontSize: 11, color: colors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (hsState.clients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.wifi_tethering_off, size: 36, color: colors.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 10),
                                Text(
                                  hsState.isActive
                                      ? 'Waiting for devices to connect...'
                                      : 'Start hotspot to monitor connected clients',
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
                            final client = hsState.clients[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                                    child: Icon(Icons.phone_android, color: colors.primary, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client.hostname ?? client.vendor ?? 'Device (${client.macAddress})',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${client.ipAddress} • ${client.macAddress} • ${_formatDuration(client.connectedDurationSecs)}',
                                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // QoS Priority Dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: DropdownButton<String>(
                                      value: client.priority,
                                      dropdownColor: colors.surfaceCard,
                                      underline: const SizedBox(),
                                      style: TextStyle(color: colors.textPrimary, fontSize: 11),
                                      items: const [
                                        DropdownMenuItem(value: 'High', child: Text('High Priority')),
                                        DropdownMenuItem(value: 'Medium', child: Text('Medium Priority')),
                                        DropdownMenuItem(value: 'Low', child: Text('Low Priority')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          notifier.setPriority(client.macAddress, val);
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BandSelectorButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;
  final NetraPalette colors;

  const _BandSelectorButton({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.primary : colors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
