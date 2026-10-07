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
    final btState = ref.watch(bluetoothStateProvider);
    final notifier = ref.read(bluetoothStateProvider.notifier);

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
                    'Bluetooth Control Center',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NetraColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pair, manage devices, monitor battery levels, and configure multi-device links',
                    style: TextStyle(color: NetraColors.textSecondary, fontSize: 14),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(
                        btState.isScanning ? Icons.stop : Icons.bluetooth_searching,
                        size: 18,
                        color: Colors.black,
                      ),
                label: Text(
                  btState.isScanning ? 'Stop Discovery' : 'Discover Devices',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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

          // Connected & Paired Devices Section
          Container(
            decoration: BoxDecoration(
              color: NetraColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NetraColors.border),
            ),
            child: btState.devices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.bluetooth_disabled, size: 40, color: NetraColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No Bluetooth devices found. Click Discover to scan.',
                            style: TextStyle(color: NetraColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: btState.devices.length,
                    separatorBuilder: (_, __) => const Divider(color: NetraColors.border, height: 1),
                    itemBuilder: (context, idx) {
                      final device = btState.devices[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: device.isConnected
                                ? NetraColors.cyan.withOpacity(0.15)
                                : NetraColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: device.isConnected
                                  ? NetraColors.cyan.withOpacity(0.3)
                                  : NetraColors.border,
                            ),
                          ),
                          child: Icon(
                            _getCategoryIcon(device.category),
                            color: device.isConnected ? NetraColors.cyan : NetraColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              device.alias.isNotEmpty ? device.alias : device.name,
                              style: TextStyle(
                                color: device.isConnected ? NetraColors.cyan : NetraColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (device.isConnected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: NetraColors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CONNECTED',
                                  style: TextStyle(
                                    color: NetraColors.green,
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
                                  color: NetraColors.cyan.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.battery_charging_full, size: 12, color: NetraColors.cyan),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${device.batteryPercentage}%',
                                      style: const TextStyle(
                                        color: NetraColors.cyan,
                                        fontSize: 11,
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
                            style: const TextStyle(color: NetraColors.textSecondary, fontSize: 12),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (device.isConnected)
                              OutlinedButton(
                                onPressed: () => notifier.disconnect(device.address),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: NetraColors.red,
                                  side: const BorderSide(color: NetraColors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Disconnect'),
                              )
                            else if (device.isPaired)
                              ElevatedButton(
                                onPressed: () => notifier.connect(device.address),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NetraColors.cyan,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => notifier.pair(device.address),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NetraColors.surface,
                                  foregroundColor: NetraColors.cyan,
                                  side: const BorderSide(color: NetraColors.border),
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
