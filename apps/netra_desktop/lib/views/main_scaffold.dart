import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/netra_theme.dart';
import 'audio_view.dart';
import 'bluetooth_view.dart';
import 'dashboard_view.dart';
import 'hotspot_view.dart';
import 'traffic_view.dart';
import 'wifi_view.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    DashboardView(),
    WifiView(),
    HotspotView(),
    BluetoothView(),
    TrafficView(),
    AudioView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NetraColors.background,
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: NetraColors.surface,
              border: Border(right: BorderSide(color: NetraColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Branding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [NetraColors.cyan, NetraColors.violet],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.remove_red_eye, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NETRA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: NetraColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Control Center',
                              style: TextStyle(
                                fontSize: 11,
                                color: NetraColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: NetraColors.border, height: 1),
                const SizedBox(height: 16),

                // Navigation Items (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: 'Dashboard',
                          isSelected: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        _SidebarItem(
                          icon: Icons.wifi_outlined,
                          activeIcon: Icons.wifi,
                          label: 'Wi-Fi Networks',
                          isSelected: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                        _SidebarItem(
                          icon: Icons.local_fire_department_outlined,
                          activeIcon: Icons.local_fire_department,
                          label: 'Smart Hotspot',
                          isSelected: _selectedIndex == 2,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        _SidebarItem(
                          icon: Icons.bluetooth_outlined,
                          activeIcon: Icons.bluetooth,
                          label: 'Bluetooth Center',
                          isSelected: _selectedIndex == 3,
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),
                        _SidebarItem(
                          icon: Icons.data_usage_outlined,
                          activeIcon: Icons.data_usage,
                          label: 'Traffic & Sockets',
                          isSelected: _selectedIndex == 4,
                          onTap: () => setState(() => _selectedIndex = 4),
                        ),
                        _SidebarItem(
                          icon: Icons.headphones_outlined,
                          activeIcon: Icons.headphones,
                          label: 'PipeWire Audio',
                          isSelected: _selectedIndex == 5,
                          onTap: () => setState(() => _selectedIndex = 5),
                        ),
                      ],
                    ),
                  ),
                ),

                // Daemon Status Footer
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: NetraColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NetraColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: NetraColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daemon: Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: NetraColors.textPrimary,
                              ),
                            ),
                            Text(
                              'org.netra.Control',
                              style: TextStyle(fontSize: 10, color: NetraColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'v1.0.0',
                        style: TextStyle(fontSize: 10, color: NetraColors.cyan.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: _views[_selectedIndex],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? NetraColors.cyan.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? NetraColors.cyan.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? NetraColors.cyan : NetraColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? NetraColors.textPrimary : NetraColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
