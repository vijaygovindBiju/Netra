import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/netra_providers.dart';
import 'theme/netra_theme.dart';
import 'views/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: NetraApp(),
    ),
  );
}

class NetraApp extends ConsumerWidget {
  const NetraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Netra — Control Center',
      debugShowCheckedModeBanner: false,
      theme: NetraTheme.lightTheme,
      darkTheme: NetraTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScaffold(),
    );
  }
}
