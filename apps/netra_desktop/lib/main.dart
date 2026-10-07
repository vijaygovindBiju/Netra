import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class NetraApp extends StatelessWidget {
  const NetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netra — Control Center',
      debugShowCheckedModeBanner: false,
      theme: NetraTheme.darkTheme,
      home: const MainScaffold(),
    );
  }
}
