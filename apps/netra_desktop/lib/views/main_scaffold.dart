import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';
import 'audio_view.dart';
import 'bluetooth_view.dart';
import 'dashboard_view.dart';
import 'hotspot_view.dart';
import 'traffic_view.dart';
import 'wifi_view.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  final List<Widget> _views = const [
    DashboardView(),
    WifiView(),
    HotspotView(),
    BluetoothView(),
    TrafficView(),
    AudioView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(activeTabProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colors = NetraColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(right: BorderSide(color: colors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Branding with Theme Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NETRA',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Control Center',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Light / Dark Theme Mode Toggle
                      Tooltip(
                        message: themeMode == ThemeMode.dark
                            ? 'Switch to Light Theme'
                            : 'Switch to Dark Theme',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  themeMode == ThemeMode.dark
                                      ? ThemeMode.light
                                      : ThemeMode.dark;
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colors.surfaceCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.border),
                              ),
                              child: Icon(
                                themeMode == ThemeMode.dark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                size: 16,
                                color: themeMode == ThemeMode.dark
                                    ? colors.amber
                                    : colors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.border, height: 1),
                const SizedBox(height: 12),

                // Navigation Items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: 'Dashboard',
                          isSelected: selectedIndex == 0,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 0,
                        ),
                        _SidebarItem(
                          icon: Icons.wifi_outlined,
                          activeIcon: Icons.wifi,
                          label: 'Wi-Fi Networks',
                          isSelected: selectedIndex == 1,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                        ),
                        _SidebarItem(
                          icon: Icons.local_fire_department_outlined,
                          activeIcon: Icons.local_fire_department,
                          label: 'Smart Hotspot',
                          isSelected: selectedIndex == 2,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 2,
                        ),
                        _SidebarItem(
                          icon: Icons.bluetooth_outlined,
                          activeIcon: Icons.bluetooth,
                          label: 'Bluetooth Center',
                          isSelected: selectedIndex == 3,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 3,
                        ),
                        _SidebarItem(
                          icon: Icons.data_usage_outlined,
                          activeIcon: Icons.data_usage,
                          label: 'Traffic & Sockets',
                          isSelected: selectedIndex == 4,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 4,
                        ),
                        _SidebarItem(
                          icon: Icons.headphones_outlined,
                          activeIcon: Icons.headphones,
                          label: 'PipeWire Audio',
                          isSelected: selectedIndex == 5,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 5,
                        ),
                      ],
                    ),
                  ),
                ),

                // Daemon Status Footer
                Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daemon: Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'org.netra.Control',
                              style: TextStyle(fontSize: 10, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'v1.0.0',
                        style: TextStyle(fontSize: 10, color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: _views[selectedIndex],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: colors.isDark ? 0.15 : 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? colors.primary.withValues(alpha: colors.isDark ? 0.35 : 0.25)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
