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
    final hsState = ref.watch(hotspotStateProvider);
    final notifier = ref.read(hotspotStateProvider.notifier);

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
                    'Smart Hotspot',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NetraColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'One-click AP tethering, connected device tracking, and QoS control',
                    style: TextStyle(color: NetraColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: hsState.isLoading ? null : () => notifier.toggleHotspot(),
                icon: hsState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(
                        hsState.isActive ? Icons.stop : Icons.play_arrow,
                        size: 20,
                        color: hsState.isActive ? Colors.white : Colors.black,
                      ),
                label: Text(
                  hsState.isActive ? 'Stop Hotspot' : 'Start Hotspot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hsState.isActive ? Colors.white : Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hsState.isActive ? NetraColors.red : NetraColors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Hotspot Status Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: NetraColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hsState.isActive ? NetraColors.cyan.withOpacity(0.5) : NetraColors.border,
              ),
              boxShadow: hsState.isActive
                  ? [
                      BoxInsets.cyanGlow,
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (hsState.isActive ? NetraColors.cyan : NetraColors.textMuted).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: hsState.isActive ? NetraColors.cyan : NetraColors.textMuted,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hsState.isActive ? 'HOTSPOT IS BROADCASTING' : 'HOTSPOT IS OFFLINE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: hsState.isActive ? NetraColors.cyan : NetraColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (hsState.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: NetraColors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${hsState.config.band} BAND',
                                style: const TextStyle(
                                  color: NetraColors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hsState.isActive
                            ? 'Broadcasting "${hsState.config.ssid}" • ${hsState.clients.length} device(s) connected'
                            : 'Configure SSID and security below, then start your hotspot',
                        style: const TextStyle(color: NetraColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Configuration and Connected Clients Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hotspot Configuration Settings
              Expanded(
                flex: 4,
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
                          Icon(Icons.tune, color: NetraColors.cyan, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: NetraColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // SSID Field
                      const Text('Network Name (SSID)', style: TextStyle(color: NetraColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ssidController,
                        enabled: !hsState.isActive,
                        style: const TextStyle(color: NetraColors.textPrimary),
                        onChanged: (val) => notifier.updateConfig(ssid: val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: NetraColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: NetraColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: NetraColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Password Field
                      const Text('WPA2/WPA3 Passphrase', style: TextStyle(color: NetraColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        enabled: !hsState.isActive,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: NetraColors.textPrimary),
                        onChanged: (val) => notifier.updateConfig(passphrase: val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: NetraColors.surface,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: NetraColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: NetraColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: NetraColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Frequency Band Selection
                      const Text('Frequency Band', style: TextStyle(color: NetraColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _BandSelectorButton(
                              label: '2.4 GHz (Long Range)',
                              isSelected: hsState.config.band == '2.4GHz',
                              enabled: !hsState.isActive,
                              onTap: () => notifier.updateConfig(band: '2.4GHz'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BandSelectorButton(
                              label: '5 GHz (High Speed)',
                              isSelected: hsState.config.band == '5GHz',
                              enabled: !hsState.isActive,
                              onTap: () => notifier.updateConfig(band: '5GHz'),
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
                          const Row(
                            children: [
                              Icon(Icons.devices, color: NetraColors.violet, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Connected Devices & QoS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: NetraColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: NetraColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: NetraColors.border),
                            ),
                            child: Text(
                              '${hsState.clients.length} Devices',
                              style: const TextStyle(fontSize: 12, color: NetraColors.cyan),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (hsState.clients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.wifi_tethering_off, size: 40, color: NetraColors.textMuted.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  hsState.isActive
                                      ? 'Waiting for devices to connect...'
                                      : 'Start hotspot to monitor connected clients',
                                  style: const TextStyle(color: NetraColors.textMuted),
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
                            final client = hsState.clients[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: NetraColors.cyan.withOpacity(0.12),
                                    child: const Icon(Icons.phone_android, color: NetraColors.cyan, size: 18),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client.hostname ?? client.vendor ?? 'Device (${client.macAddress})',
                                          style: const TextStyle(
                                            color: NetraColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${client.ipAddress} • ${client.macAddress} • ${_formatDuration(client.connectedDurationSecs)}',
                                          style: const TextStyle(color: NetraColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // QoS Priority Dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: NetraColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: NetraColors.border),
                                    ),
                                    child: DropdownButton<String>(
                                      value: client.priority,
                                      dropdownColor: NetraColors.surfaceCard,
                                      underline: const SizedBox(),
                                      style: const TextStyle(color: NetraColors.textPrimary, fontSize: 12),
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

  const _BandSelectorButton({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? NetraColors.cyan.withOpacity(0.15) : NetraColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? NetraColors.cyan : NetraColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? NetraColors.cyan : NetraColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class BoxInsets {
  static final cyanGlow = BoxShadow(
    color: NetraColors.cyan.withOpacity(0.15),
    blurRadius: 18,
    spreadRadius: 2,
  );
}
