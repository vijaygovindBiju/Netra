import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/netra_providers.dart';
import '../theme/netra_theme.dart';
import '../widgets/resizable_layout.dart';
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
      body: ResizableSidebarLayout(
        initialWidth: 250,
        minWidth: 180,
        maxWidth: 420,
        sidebarBuilder: (context, width, isCollapsed) {
          return Container(
            color: colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Branding with Theme Switcher
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 12 : 20,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                      if (!isCollapsed) ...[
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
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Control Center',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isCollapsed) ...[
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
                    ],
                  ),
                ),
                if (isCollapsed) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IconButton(
                        icon: Icon(
                          themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                          size: 18,
                          color: themeMode == ThemeMode.dark ? colors.amber : colors.secondary,
                        ),
                        tooltip: themeMode == ThemeMode.dark ? 'Switch to Light' : 'Switch to Dark',
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).state =
                              themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                        },
                      ),
                    ),
                  ),
                ],
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
                          isCollapsed: isCollapsed,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 0,
                        ),
                        _SidebarItem(
                          icon: Icons.wifi_outlined,
                          activeIcon: Icons.wifi,
                          label: 'Wi-Fi Networks',
                          isSelected: selectedIndex == 1,
                          isCollapsed: isCollapsed,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                        ),
                        _SidebarItem(
                          icon: Icons.local_fire_department_outlined,
                          activeIcon: Icons.local_fire_department,
                          label: 'Smart Hotspot',
                          isSelected: selectedIndex == 2,
                          isCollapsed: isCollapsed,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 2,
                        ),
                        _SidebarItem(
                          icon: Icons.bluetooth_outlined,
                          activeIcon: Icons.bluetooth,
                          label: 'Bluetooth Center',
                          isSelected: selectedIndex == 3,
                          isCollapsed: isCollapsed,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 3,
                        ),
                        _SidebarItem(
                          icon: Icons.data_usage_outlined,
                          activeIcon: Icons.data_usage,
                          label: 'Traffic & Sockets',
                          isSelected: selectedIndex == 4,
                          isCollapsed: isCollapsed,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 4,
                        ),
                        _SidebarItem(
                          icon: Icons.headphones_outlined,
                          activeIcon: Icons.headphones,
                          label: 'PipeWire Audio',
                          isSelected: selectedIndex == 5,
                          isCollapsed: isCollapsed,
                          onTap: () => ref.read(activeTabProvider.notifier).state = 5,
                        ),
                      ],
                    ),
                  ),
                ),

                // Daemon Status Footer
                Container(
                  margin: EdgeInsets.all(isCollapsed ? 8 : 14),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 8 : 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: isCollapsed
                      ? Tooltip(
                          message: 'Daemon Active • org.netra.Control v1.0.0',
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                      : Row(
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'org.netra.Control',
                                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                                    overflow: TextOverflow.ellipsis,
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
          );
        },
        content: _views[selectedIndex],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.isCollapsed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 14,
            vertical: 10,
          ),
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
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? colors.primary : colors.textSecondary,
                size: 19,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 2,
      ),
      child: isCollapsed
          ? Tooltip(
              message: label,
              waitDuration: const Duration(milliseconds: 200),
              child: content,
            )
          : content,
    );
  }
}

