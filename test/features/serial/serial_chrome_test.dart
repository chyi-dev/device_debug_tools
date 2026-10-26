import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/features/serial/serial_metrics.dart';
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

  testWidgets('单行输入框的行框高于字号，下划线不被裁在底边上', (tester) async {
    final controller = TextEditingController(text: 'ddt_desktop');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: SerialField(
                controller: controller,
                height: SerialMetrics.controlSm,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.clipBehavior, Clip.hardEdge);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final fontSize = editable.style.fontSize!;
    expect(editable.style.height, greaterThan(1));
    final box = tester.renderObject<RenderBox>(find.byType(EditableText));
    expect(box.size.height, greaterThan(fontSize));
    expect(box.size.height, lessThanOrEqualTo(SerialMetrics.controlSm));
  });

  testWidgets('长密码留在输入框内', (tester) async {
    final controller = TextEditingController(text: 'p' * 80);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 272,
              child: SerialFieldRow(
                label: '密码',
                child: SerialField(
                  controller: controller,
                  height: SerialMetrics.controlSm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final field = tester.getRect(find.byType(SerialField));
    final text = tester.getRect(find.byType(EditableText));
    expect(text.left, greaterThanOrEqualTo(field.left));
    expect(text.right, lessThanOrEqualTo(field.right));
    expect(text.top, greaterThanOrEqualTo(field.top));
    expect(text.bottom, lessThanOrEqualTo(field.bottom));
  });
}
