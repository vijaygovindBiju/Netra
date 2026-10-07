import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';

class WifiView extends ConsumerStatefulWidget {
  const WifiView({super.key});

  @override
  ConsumerState<WifiView> createState() => _WifiViewState();
}

class _WifiViewState extends ConsumerState<WifiView> {
  String _searchQuery = '';

  void _showConnectDialog(BuildContext context, AccessPoint ap) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

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
              title: Row(
                children: [
                  const Icon(Icons.wifi_lock, color: NetraColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connect to ${ap.ssid}',
                      style: const TextStyle(color: NetraColors.textPrimary, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security: ${ap.security} • Band: ${ap.band}',
                    style: const TextStyle(color: NetraColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (ap.security != 'Open')
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: NetraColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Passphrase',
                        labelStyle: const TextStyle(color: NetraColors.textSecondary),
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: NetraColors.cyan),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: NetraColors.textSecondary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                ],
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
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final success = await ref
                        .read(networkStateProvider.notifier)
                        .connect(ap.ssid, passwordController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? NetraColors.surfaceCard : NetraColors.red,
                          content: Text(
                            success ? 'Connecting to ${ap.ssid}...' : 'Failed to connect to ${ap.ssid}',
                            style: const TextStyle(color: NetraColors.textPrimary),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final netState = ref.watch(networkStateProvider);
    final connectedAp = netState.accessPoints.where((a) => a.isConnected).firstOrNull;

    final filteredAps = netState.accessPoints.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.ssid.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
                    'Wi-Fi Networks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NetraColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Scan, authenticate, and manage wireless connections',
                    style: TextStyle(color: NetraColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: netState.isLoading
                    ? null
                    : () => ref.read(networkStateProvider.notifier).refreshScan(),
                icon: netState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: NetraColors.cyan),
                      )
                    : const Icon(Icons.wifi_find, size: 18),
                label: Text(netState.isLoading ? 'Scanning...' : 'Scan Networks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NetraColors.surfaceCard,
                  foregroundColor: NetraColors.cyan,
                  side: const BorderSide(color: NetraColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Active Connection Banner
          if (connectedAp != null) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NetraColors.cyan.withOpacity(0.12),
                    NetraColors.surfaceCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NetraColors.cyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NetraColors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi, color: NetraColors.green, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              connectedAp.ssid,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: NetraColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BSSID: ${connectedAp.bssid} • Band: ${connectedAp.band} • Security: ${connectedAp.security}',
                          style: const TextStyle(color: NetraColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(networkStateProvider.notifier).disconnect(),
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NetraColors.red,
                      side: const BorderSide(color: NetraColors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Search and Filter Header
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: NetraColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search visible networks...',
                    hintStyle: const TextStyle(color: NetraColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: NetraColors.textSecondary),
                    filled: true,
                    fillColor: NetraColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NetraColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NetraColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: NetraColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NetraColors.border),
                ),
                child: Text(
                  '${filteredAps.length} Networks found',
                  style: const TextStyle(color: NetraColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Available APs List
          Container(
            decoration: BoxDecoration(
              color: NetraColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NetraColors.border),
            ),
            child: filteredAps.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No wireless networks matching filter',
                        style: TextStyle(color: NetraColors.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAps.length,
                    separatorBuilder: (_, __) => const Divider(color: NetraColors.border, height: 1),
                    itemBuilder: (context, idx) {
                      final ap = filteredAps[idx];
                      final isConnected = ap.isConnected;

                      final signalColor = ap.signalStrength > 70
                          ? NetraColors.green
                          : (ap.signalStrength > 40 ? NetraColors.cyan : NetraColors.amber);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: signalColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            ap.signalStrength > 60
                                ? Icons.wifi
                                : (ap.signalStrength > 30 ? Icons.wifi_2_bar : Icons.wifi_1_bar),
                            color: signalColor,
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              ap.ssid,
                              style: TextStyle(
                                color: isConnected ? NetraColors.green : NetraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _Badge(text: ap.band, color: NetraColors.violet),
                            const SizedBox(width: 6),
                            _Badge(text: ap.security, color: NetraColors.cyan),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Signal: ${ap.signalStrength}% • BSSID: ${ap.bssid}',
                            style: const TextStyle(color: NetraColors.textSecondary, fontSize: 12),
                          ),
                        ),
                        trailing: isConnected
                            ? const Text(
                                'Active',
                                style: TextStyle(
                                  color: NetraColors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => _showConnectDialog(context, ap),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NetraColors.surface,
                                  foregroundColor: NetraColors.cyan,
                                  side: const BorderSide(color: NetraColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Connect'),
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
