import 'package:flutter/material.dart';

class ProcessTrafficItem {
  final int pid;
  final String name;
  final String cmdline;
  final int rxRateBps;
  final int txRateBps;
  final int totalRxBytes;
  final int totalTxBytes;
  final int openSocketCount;

  ProcessTrafficItem({
    required this.pid,
    required this.name,
    required this.cmdline,
    required this.rxRateBps,
    required this.txRateBps,
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.openSocketCount,
  });

  factory ProcessTrafficItem.fromJson(Map<String, dynamic> json) {
    return ProcessTrafficItem(
      pid: (json['pid'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? 'unknown',
      cmdline: json['cmdline'] ?? '',
      rxRateBps: (json['rx_rate_bps'] as num?)?.toInt() ?? 0,
      txRateBps: (json['tx_rate_bps'] as num?)?.toInt() ?? 0,
      totalRxBytes: (json['total_rx_bytes'] as num?)?.toInt() ?? 0,
      totalTxBytes: (json['total_tx_bytes'] as num?)?.toInt() ?? 0,
      openSocketCount: (json['open_socket_count'] as num?)?.toInt() ?? 0,
    );
  }
}

enum AppCategoryType {
  browsers,
  communication,
  media,
  gaming,
  development,
  system,
  other,
}

class AppCategoryInfo {
  final String title;
  final IconData icon;
  final Color accentColor;

  const AppCategoryInfo({
    required this.title,
    required this.icon,
    required this.accentColor,
  });
}

class AppGroup {
  final AppCategoryType type;
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<ProcessTrafficItem> processes;

  AppGroup({
    required this.type,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.processes,
  });

  int get totalRxRate => processes.fold(0, (sum, p) => sum + p.rxRateBps);
  int get totalTxRate => processes.fold(0, (sum, p) => sum + p.txRateBps);
  int get totalBytes => processes.fold(0, (sum, p) => sum + p.totalRxBytes + p.totalTxBytes);
  int get totalSockets => processes.fold(0, (sum, p) => sum + p.openSocketCount);
}

class AppCategorizer {
  static const Map<AppCategoryType, AppCategoryInfo> categoryMeta = {
    AppCategoryType.browsers: AppCategoryInfo(
      title: 'Web Browsers',
      icon: Icons.public,
      accentColor: Color(0xFF00E5FF),
    ),
    AppCategoryType.communication: AppCategoryInfo(
      title: 'Communication & Chat',
      icon: Icons.forum,
      accentColor: Color(0xFF7C4DFF),
    ),
    AppCategoryType.media: AppCategoryInfo(
      title: 'Media & Streaming',
      icon: Icons.music_note,
      accentColor: Color(0xFF00E676),
    ),
    AppCategoryType.gaming: AppCategoryInfo(
      title: 'Gaming & Launchers',
      icon: Icons.sports_esports,
      accentColor: Color(0xFFFFB300),
    ),
    AppCategoryType.development: AppCategoryInfo(
      title: 'Development & Tools',
      icon: Icons.code,
      accentColor: Color(0xFF0284C7),
    ),
    AppCategoryType.system: AppCategoryInfo(
      title: 'System & Daemons',
      icon: Icons.settings_suggest,
      accentColor: Color(0xFF94A3B8),
    ),
    AppCategoryType.other: AppCategoryInfo(
      title: 'General Applications',
      icon: Icons.widgets_outlined,
      accentColor: Color(0xFFA855F7),
    ),
  };

  static AppCategoryType categorize(ProcessTrafficItem item) {
    final lower = '${item.name.toLowerCase()} ${item.cmdline.toLowerCase()}';

    // 1. Browsers
    if (lower.contains('firefox') ||
        lower.contains('chrome') ||
        lower.contains('chromium') ||
        lower.contains('brave') ||
        lower.contains('edge') ||
        lower.contains('opera') ||
        lower.contains('vivaldi') ||
        lower.contains('tor') ||
        lower.contains('safari')) {
      return AppCategoryType.browsers;
    }

    // 2. Communication
    if (lower.contains('discord') ||
        lower.contains('slack') ||
        lower.contains('telegram') ||
        lower.contains('signal') ||
        lower.contains('teams') ||
        lower.contains('zoom') ||
        lower.contains('whatsapp') ||
        lower.contains('skype') ||
        lower.contains('thunderbird') ||
        lower.contains('element')) {
      return AppCategoryType.communication;
    }

    // 3. Media
    if (lower.contains('spotify') ||
        lower.contains('vlc') ||
        lower.contains('mpv') ||
        lower.contains('rhythmbox') ||
        lower.contains('audacity') ||
        lower.contains('obs') ||
        lower.contains('kodi') ||
        lower.contains('cider') ||
        lower.contains('netflix')) {
      return AppCategoryType.media;
    }

    // 4. Gaming
    if (lower.contains('steam') ||
        lower.contains('lutris') ||
        lower.contains('heroic') ||
        lower.contains('wine') ||
        lower.contains('proton') ||
        lower.contains('gamescope') ||
        lower.contains('minecraft')) {
      return AppCategoryType.gaming;
    }

    // 5. Development
    if (lower.contains('code') ||
        lower.contains('vscode') ||
        lower.contains('git') ||
        lower.contains('docker') ||
        lower.contains('cargo') ||
        lower.contains('rustc') ||
        lower.contains('flutter') ||
        lower.contains('dart') ||
        lower.contains('node') ||
        lower.contains('npm') ||
        lower.contains('python') ||
        lower.contains('bash') ||
        lower.contains('zsh') ||
        lower.contains('kitty') ||
        lower.contains('alacritty') ||
        lower.contains('sublime')) {
      return AppCategoryType.development;
    }

    // 6. System
    if (lower.contains('systemd') ||
        lower.contains('networkmanager') ||
        lower.contains('netrad') ||
        lower.contains('netra-daemon') ||
        lower.contains('pipewire') ||
        lower.contains('wireplumber') ||
        lower.contains('bluez') ||
        lower.contains('bluetoothd') ||
        lower.contains('dbus') ||
        lower.contains('avahi') ||
        lower.contains('cupsd') ||
        lower.contains('sshd') ||
        lower.contains('polkit') ||
        lower.contains('kernel') ||
        lower.contains('kworker') ||
        lower.contains('rtkit')) {
      return AppCategoryType.system;
    }

    return AppCategoryType.other;
  }

  static List<AppGroup> groupProcesses(List<ProcessTrafficItem> processes) {
    final Map<AppCategoryType, List<ProcessTrafficItem>> map = {};
    for (final type in AppCategoryType.values) {
      map[type] = [];
    }

    for (final p in processes) {
      final cat = categorize(p);
      map[cat]!.add(p);
    }

    final List<AppGroup> groups = [];
    for (final entry in map.entries) {
      if (entry.value.isNotEmpty) {
        final meta = categoryMeta[entry.key]!;
        // Sort processes within the group by total data descending
        entry.value.sort((a, b) =>
            (b.totalRxBytes + b.totalTxBytes).compareTo(a.totalRxBytes + a.totalTxBytes));

        groups.add(
          AppGroup(
            type: entry.key,
            title: meta.title,
            icon: meta.icon,
            accentColor: meta.accentColor,
            processes: entry.value,
          ),
        );
      }
    }

    // Sort groups by total combined data consumption
    groups.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return groups;
  }
}
