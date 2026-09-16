import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/data/game_data.dart';
import 'package:wardogs_assistant/screens/compare_screen.dart';
import 'package:wardogs_assistant/theme.dart';

void main() {
  group('存疑数值', () {
    test('AK74 的 FMJ 对 1 级甲被标为存疑', () {
      final ak = kWeapons.firstWhere((w) => w.name == 'AK74');
      final fmj = ak.damage.firstWhere((r) => r.ammo == 'FMJ');
      expect(fmj.isDoubtful(1), isTrue,
          reason: '这一格穿甲后伤害反而更高，与其他枪规律相反，必须保留存疑标记');
      // 存疑的只有这一格，别误标
      expect(fmj.isDoubtful(0), isFalse);
      expect(fmj.isDoubtful(2), isFalse);
    });

    test('照原值保留，没有被擅自改掉', () {
      final ak = kWeapons.firstWhere((w) => w.name == 'AK74');
      final fmj = ak.damage.firstWhere((r) => r.ammo == 'FMJ');
      expect(fmj.t1, 72.79, reason: '资料源原值，不替数据源做决定');
    });

    test('其他枪的护甲衰减是递减的', () {
      for (final w in kWeapons.where((w) => w.damage.isNotEmpty)) {
        for (final r in w.damage) {
          for (var tier = 1; tier < 5; tier++) {
            if (r.isDoubtful(tier)) continue; // 存疑的那格例外
            expect(r.at(tier), lessThanOrEqualTo(r.at(tier - 1)),
                reason: '${w.name} 的 ${r.ammo} 在 $tier 级甲上反而更高 —— '
                    '要么数据错了，要么该标存疑');
          }
        }
      }
    });
  });

  testWidgets('对比页在 FMJ / 1级甲 下会标出问号和说明', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const CompareScreen(),
    ));
    await t.pumpAndSettle();

    // 默认 FMJ / 无甲：这一组没有存疑值
    expect(find.text('?'), findsNothing);
    expect(find.textContaining('存疑'), findsNothing);

    // 切到 1 级甲
    await t.tap(find.text('1级'));
    await t.pumpAndSettle();

    expect(find.text('?'), findsOneWidget);
    expect(find.textContaining('存疑'), findsOneWidget);
  });
}
