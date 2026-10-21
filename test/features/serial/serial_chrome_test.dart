import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/features/serial/widget/serial_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('勾选框可放在未包 Expanded 的 Row 里', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: Row(
                children: [
                  const Expanded(child: SizedBox(height: 26)),
                  SerialCheck(
                    label: 'Retain',
                    value: false,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Retain'), findsOneWidget);
  });
}
