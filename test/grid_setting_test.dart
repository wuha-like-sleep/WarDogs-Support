import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardogs_assistant/ballistics.dart';
import 'package:wardogs_assistant/data/settings.dart';
import 'package:wardogs_assistant/data/store.dart';
import 'package:wardogs_assistant/screens/mortar_screen.dart';
import 'package:wardogs_assistant/theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    gridMeters.value = kGridMeters;
  });

  test('默认刻度是实机验证的 10 米', () async {
    expect(kGridMeters, 10.0);
    expect(await Store.loadGridMeters(), 10.0);
  });

  test('改过的刻度存得住', () async {
    await setGridMeters(100);
    expect(gridMeters.value, 100.0);
    expect(await Store.loadGridMeters(), 100.0);
  });

  test('非法值不写入', () async {
    await setGridMeters(0);
    expect(gridMeters.value, 10.0);
    await setGridMeters(-5);
    expect(gridMeters.value, 10.0);
  });

  testWidgets('改刻度后，诸元当场跟着变', (t) async {
    t.view.physicalSize = const Size(1200, 4200);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const MortarScreen(),
    ));
    await t.pumpAndSettle();

    Future<void> press(String label) async {
      await t.tap(find.widgetWithText(InkWell, label).last);
      await t.pump();
    }

    // 炮位(0,0) 目标(0,50)
    await press('0');
    await press('下一项');
    await press('0');
    await press('下一项');
    await press('0');
    await press('下一项');
    await press('5');
    await press('0');
    await t.pump();
    expect(find.text('500'), findsOneWidget);

    // 切到 100 米刻度，同一组坐标应该变成十倍
    await setGridMeters(100);
    await t.pumpAndSettle();
    expect(find.text('5000'), findsOneWidget,
        reason: '在「更多」里改了刻度，计算页必须立刻重算，'
            '不能因为 IndexedStack 保活就还拿着旧值');
    expect(find.text('500'), findsNothing);
  });
}
