import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bluetooth_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

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
                    'Pair, manage devices, monitor battery levels, and configure multi-device links',
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
          const SizedBox(height: 20),

          // Connected & Paired Devices Section
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
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
                    separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
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
}
