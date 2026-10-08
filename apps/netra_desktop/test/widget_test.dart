import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netra_desktop/main.dart';
import 'package:netra_desktop/models/bluetooth_models.dart';

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

  testWidgets('Dashboard cards collapse and remove/restore tests', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: NetraApp(),
      ),
    );

    // Verify Collapse Cards button exists
    final collapseBtnFinder = find.text('Collapse Cards');
    expect(collapseBtnFinder, findsOneWidget);

    // Tap Collapse Cards to collapse all cards ("collide")
    await tester.tap(collapseBtnFinder);
    await tester.pumpAndSettle();

    // Now button should say 'Expand All'
    expect(find.text('Expand All'), findsOneWidget);

    // Tap Expand All to re-expand all cards
    await tester.tap(find.text('Expand All'));
    await tester.pumpAndSettle();

    expect(find.text('Collapse Cards'), findsOneWidget);

    // Verify close/hide icon buttons exist for cards
    final closeIcons = find.byIcon(Icons.close);
    expect(closeIcons, findsWidgets);

    // Tap the first close icon to hide/remove a card
    await tester.tap(closeIcons.first);
    await tester.pumpAndSettle();

    // Verify Hidden Cards bar appears with Show All button
    expect(find.text('Hidden Cards:'), findsOneWidget);
    expect(find.text('Show All'), findsOneWidget);

    // Tap Show All to restore all hidden cards
    await tester.tap(find.text('Show All'));
    await tester.pumpAndSettle();

    // Hidden Cards bar should disappear
    expect(find.text('Hidden Cards:'), findsNothing);
  });

  test('BluetoothAdapterItem parses hardware capabilities and limits accurately', () {
    final rawJson = {
      'address': '00:11:22:33:44:55',
      'name': 'My Laptop BT',
      'is_powered': true,
      'is_discovering': false,
      'is_pairable': true,
      'manufacturer': 'MediaTek',
      'chipset_name': 'MediaTek Bluetooth MT7921',
      'bluetooth_version': '5.3',
      'hci_version': 12,
      'max_active_connections': 7,
      'max_recommended_audio_streams': 3,
      'supports_le_audio': true,
      'supports_2m_phy': true,
    };

    final adapter = BluetoothAdapterItem.fromJson(rawJson);
    expect(adapter.address, '00:11:22:33:44:55');
    expect(adapter.chipsetName, 'MediaTek Bluetooth MT7921');
    expect(adapter.bluetoothVersion, '5.3');
    expect(adapter.hciVersion, 12);
    expect(adapter.maxActiveConnections, 7);
    expect(adapter.maxRecommendedAudioStreams, 3);
    expect(adapter.supportsLeAudio, isTrue);
    expect(adapter.supports2mPhy, isTrue);
  });
}
