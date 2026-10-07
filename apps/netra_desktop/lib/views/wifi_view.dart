import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_models.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';
import '../widgets/resizable_layout.dart';

class WifiView extends ConsumerStatefulWidget {
  const WifiView({super.key});

  @override
  ConsumerState<WifiView> createState() => _WifiViewState();
}

class _WifiViewState extends ConsumerState<WifiView> {
  String _searchQuery = '';

  void _showConnectDialog(BuildContext context, AccessPoint ap) {
    final colors = NetraColors.of(context);
    final passwordController = TextEditingController();
    bool obscurePassword = true;

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
                  Icon(Icons.wifi_lock, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connect to ${ap.ssid}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 18),
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
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (ap.security != 'Open')
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Passphrase',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.surface,
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: colors.textSecondary,
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
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
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
                          backgroundColor: success ? colors.surfaceCard : colors.red,
                          content: Text(
                            success ? 'Connecting to ${ap.ssid}...' : 'Failed to connect to ${ap.ssid}',
                            style: TextStyle(color: colors.textPrimary),
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
    final colors = NetraColors.of(context);
    final netState = ref.watch(networkStateProvider);
    final connectedAp = netState.accessPoints.where((a) => a.isConnected).firstOrNull;

    final filteredAps = netState.accessPoints.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.ssid.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
                    'Wi-Fi Networks',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan, authenticate, and manage wireless connections',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: netState.isLoading
                    ? null
                    : () => ref.read(networkStateProvider.notifier).refreshScan(),
                icon: netState.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                      )
                    : const Icon(Icons.wifi_find, size: 16),
                label: Text(netState.isLoading ? 'Scanning...' : 'Scan Networks'),
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

          // Active Connection Banner
          if (connectedAp != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: colors.isDark ? 0.15 : 0.08),
                    colors.surfaceCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wifi, color: colors.green, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              connectedAp.ssid,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BSSID: ${connectedAp.bssid} • Band: ${connectedAp.band} • Security: ${connectedAp.security}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(networkStateProvider.notifier).disconnect(),
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.red,
                      side: BorderSide(color: colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Search and Filter Header
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search visible networks...',
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
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '${filteredAps.length} Networks found',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Available APs List
          ResizableCard(
            title: 'Available Networks (${filteredAps.length})',
            icon: Icons.wifi,
            initialHeight: 480.0,
            minHeight: 220.0,
            maxHeight: 1100.0,
            padding: EdgeInsets.zero,
            child: filteredAps.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No wireless networks matching filter',
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAps.length,
                    separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
                    itemBuilder: (context, idx) {
                      final ap = filteredAps[idx];
                      final isConnected = ap.isConnected;

                      final signalColor = ap.signalStrength > 70
                          ? colors.green
                          : (ap.signalStrength > 40 ? colors.primary : colors.amber);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: signalColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            ap.signalStrength > 60
                                ? Icons.wifi
                                : (ap.signalStrength > 30 ? Icons.wifi_2_bar : Icons.wifi_1_bar),
                            color: signalColor,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              ap.ssid,
                              style: TextStyle(
                                color: isConnected ? colors.green : colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Badge(text: ap.band, color: colors.secondary),
                            const SizedBox(width: 6),
                            _Badge(text: ap.security, color: colors.primary),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Signal: ${ap.signalStrength}% • BSSID: ${ap.bssid}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ),
                        trailing: isConnected
                            ? Text(
                                'Active',
                                style: TextStyle(
                                  color: colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => _showConnectDialog(context, ap),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.surface,
                                  foregroundColor: colors.primary,
                                  side: BorderSide(color: colors.border),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
