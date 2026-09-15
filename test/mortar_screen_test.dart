import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardogs_assistant/screens/mortar_screen.dart';
import 'package:wardogs_assistant/theme.dart';

/// 按下小键盘上写着 [label] 的那个键
Future<void> press(WidgetTester t, String label) async {
  await t.tap(find.widgetWithText(InkWell, label).last);
  await t.pump();
}

/// 矫正按钮在折叠线以下，得先滚到可见再点
Future<void> scrollAndPress(WidgetTester t, String label) async {
  final f = find.widgetWithText(InkWell, label).last;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> typeNumber(WidgetTester t, String number) async {
  for (final ch in number.split('')) {
    await press(t, ch == '-' ? '−' : ch);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const MortarScreen(),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('从键盘敲进四个坐标，诸元就出来了', (t) async {
    await pumpScreen(t);

    // 一开始四个格子都空，诸元位置显示横杠而不是乱数
    expect(find.text('—'), findsNWidgets(2));

    await typeNumber(t, '63.41');
    await press(t, '下一项');
    await typeNumber(t, '104.52');
    await press(t, '下一项');
    await typeNumber(t, '67.56');
    await press(t, '下一项');
    await typeNumber(t, '100.67');
    await t.pump();

    // 这组数就是实机截图里的那一发
    expect(find.text('566'), findsOneWidget);
    expect(find.text('133SE'), findsOneWidget);
  });

  testWidgets('少填一个格子就不出诸元', (t) async {
    await pumpScreen(t);
    await typeNumber(t, '10');
    await press(t, '下一项');
    await typeNumber(t, '10');
    await press(t, '下一项');
    await typeNumber(t, '20');
    // 第四个格子空着
    await t.pump();
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('退格和清空都好使', (t) async {
    await pumpScreen(t);
    await typeNumber(t, '123');
    await press(t, '⌫');
    await t.pump();
    expect(find.text('12'), findsOneWidget);
    await press(t, 'C');
    await t.pump();
    expect(find.text('12'), findsNothing);
  });

  testWidgets('负号能来回切', (t) async {
    await pumpScreen(t);
    await typeNumber(t, '55');
    await press(t, '−');
    await t.pump();
    expect(find.text('-55'), findsOneWidget);
    await press(t, '−');
    await t.pump();
    expect(find.text('55'), findsOneWidget);
  });

  testWidgets('矫正按钮会把诸元改掉', (t) async {
    await pumpScreen(t);
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '5');
    await t.pump();
    expect(find.text('500'), findsOneWidget);

    await press(t, '收起键盘');
    await t.pumpAndSettle();

    // 默认步长 25 米，往南挪一次 = 离炮位近 25 米
    await scrollAndPress(t, '下');
    expect(find.text('475'), findsOneWidget);
    expect(find.textContaining('已矫正'), findsOneWidget);
  });
}
