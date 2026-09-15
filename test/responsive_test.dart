import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardogs_assistant/screens/compare_screen.dart';
import 'package:wardogs_assistant/screens/history_screen.dart';
import 'package:wardogs_assistant/screens/loadout_screen.dart';
import 'package:wardogs_assistant/screens/logistics_screen.dart';
import 'package:wardogs_assistant/screens/more_screen.dart';
import 'package:wardogs_assistant/screens/mortar_screen.dart';
import 'package:wardogs_assistant/theme.dart';

/// 屏幕尺寸从最小的 iPhone SE 一代到 iPad，字号从正常到无障碍最大。
/// 任何一格出现 RenderFlex 溢出、文字被挤爆，这里都会红。
const _sizes = <String, Size>{
  'iPhone SE 一代 320×568': Size(320, 568),
  'iPhone SE 375×667': Size(375, 667),
  'iPhone 17 Pro 402×874': Size(402, 874),
  'iPhone Pro Max 440×956': Size(440, 956),
  'iPad 768×1024': Size(768, 1024),
};

const _scales = <double>[1.0, 1.3, 1.8];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> check(
    WidgetTester t,
    String screenName,
    Widget screen,
    Size size,
    double scale,
  ) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
        ),
        child: screen,
      ),
    ));
    await t.pumpAndSettle();

    final err = t.takeException();
    expect(
      err,
      isNull,
      reason: '$screenName 在 $size / 字号 ${scale}x 下渲染出错：$err',
    );
  }

  for (final entry in _sizes.entries) {
    for (final scale in _scales) {
      final label = '${entry.key} · 字号 ${scale}x';

      testWidgets('迫击炮 — $label', (t) async {
        await check(t, '迫击炮', const MortarScreen(), entry.value, scale);
      });

      testWidgets('后勤 — $label', (t) async {
        await check(t, '后勤', const LogisticsScreen(), entry.value, scale);
      });

      testWidgets('配装 — $label', (t) async {
        await check(t, '配装', const LoadoutScreen(), entry.value, scale);
      });

      testWidgets('伤害对比 — $label', (t) async {
        await check(t, '伤害对比', const CompareScreen(), entry.value, scale);
      });

      testWidgets('更多 — $label', (t) async {
        await check(t, '更多', const MoreScreen(), entry.value, scale);
      });

      testWidgets('射击记录 — $label', (t) async {
        await check(
            t, '射击记录', const HistoryScreen(shots: []), entry.value, scale);
      });
    }
  }
}
