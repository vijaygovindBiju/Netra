import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netra_desktop/main.dart';
import 'package:netra_desktop/providers/netra_providers.dart';

void main() {
  testWidgets('NetraApp smoke test and theme toggle', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: NetraApp(),
      ),
    );

    // Verify app title and branding
    expect(find.text('NETRA'), findsOneWidget);
    expect(find.text('Control Center'), findsOneWidget);

    // Verify Dashboard sections
    expect(find.text('Control Dashboard'), findsOneWidget);
    expect(find.text('Application Data Usage'), findsOneWidget);
    expect(find.text('Active Link Details'), findsOneWidget);
    expect(find.text('Hotspot Clients'), findsOneWidget);
    expect(find.text('Nearby Wi-Fi Networks'), findsOneWidget);

    // Verify Theme Switch button exists (Light mode icon when in Dark mode)
    final themeToggleFinder = find.byIcon(Icons.light_mode);
    expect(themeToggleFinder, findsOneWidget);

    // Tap theme toggle to switch to Light Theme
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    // Now dark_mode icon should appear indicating it is in Light mode
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    // Tap again to switch back to Dark Theme
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });
}
