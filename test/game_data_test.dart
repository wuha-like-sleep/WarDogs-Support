import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/data/game_data.dart';
import 'package:wardogs_assistant/screens/compare_screen.dart';
import 'package:wardogs_assistant/screens/loadout_screen.dart';
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

    test('FAL 的 4 级甲两格被标为存疑', () {
      final fal = kWeapons.firstWhere((w) => w.name == 'FAL');
      final fmj = fal.damage.firstWhere((r) => r.ammo == 'FMJ');
      final ap = fal.damage.firstWhere((r) => r.ammo == 'AP');
      // 37.03 / 141.00 = 0.263，57.12 / 112.83 = 0.506，
      // 都不在 FAL 自己那条曲线上（应为 0.35 与 0.675），正好低四分之一。
      expect(fmj.t4, 37.03, reason: '原值照录');
      expect(ap.t4, 57.12, reason: '原值照录');
      expect(fmj.isDoubtful(4), isTrue);
      expect(ap.isDoubtful(4), isTrue);
    });

    test('每把标了存疑的枪都要说清楚疑点在哪', () {
      for (final w in kWeapons) {
        final hasDoubt = w.damage.any((r) => r.doubtful.isNotEmpty);
        if (!hasDoubt) continue;
        expect(w.dataNote, isNotNull,
            reason: '${w.name} 的伤害表上有 ? 却没写原因 —— '
                '玩家看到问号不知道该不该信，等于没标');
      }
    });

    test('基础字段的存疑标记只能打在有值的字段上', () {
      String? valueOf(Weapon w, String f) => switch (f) {
            'priceUsd' => w.priceUsd?.toString(),
            'weightKg' => w.weightKg?.toString(),
            'caliber' => w.caliber,
            'fireModes' => w.fireModes,
            'track' => w.track,
            'unlock' => w.unlock,
            _ => throw ArgumentError('未知字段 $f'),
          };
      for (final w in kWeapons) {
        for (final f in w.doubtfulFields) {
          expect(valueOf(w, f), isNotNull,
              reason: '${w.name} 把 $f 标了存疑，但这个字段本来就是横杠。'
                  '横杠已经说明「没有」，再挂个问号只会更糊涂');
        }
      }
    });

    test('其他枪的护甲衰减是递减的', () {
      for (final w in kWeapons.where((w) => w.damage.isNotEmpty)) {
        for (final r in w.damage) {
          // 横杠不参与比较；存疑的那格跳过，且不拿它当下一格的基准
          double? prev = r.at(0);
          for (var tier = 1; tier < 5; tier++) {
            final v = r.at(tier);
            if (v == null || r.isDoubtful(tier)) continue;
            if (prev != null) {
              expect(v, lessThanOrEqualTo(prev),
                  reason: '${w.name} 的 ${r.ammo} 在 $tier 级甲上反而更高 —— '
                      '要么数据错了，要么该标存疑');
            }
            prev = v;
          }
        }
      }
    });
  });

  group('拿不到就是拿不到', () {
    test('没查到的格子写 null，绝不写 0', () {
      for (final w in kWeapons) {
        for (final r in w.damage) {
          for (var tier = 0; tier < 5; tier++) {
            expect(r.at(tier), isNot(0),
                reason: '${w.name} 的 ${r.ammo} 第 $tier 格是 0。'
                    '「没查到」要写 null —— 0 的意思是打上去不掉血，'
                    '玩家会照着这个数换枪');
          }
        }
      }
    });

    test('伤害表永远是 FMJ / HP / AP 三行，缺的那行是整行横杠', () {
      final t21 = kWeapons.firstWhere((w) => w.name == 'T-21');
      expect(t21.damage.length, 1, reason: 'T-21 只收录了 FMJ 一行');
      expect(t21.damageRows.map((r) => r.ammo).toList(), ['FMJ', 'HP', 'AP'],
          reason: '整行消失会让玩家以为这枪不吃这种弹，那是另一回事');
      expect(t21.damageRows[1].isEmpty, isTrue);
      expect(t21.damageRows[2].isEmpty, isTrue);

      // 一把一个数都没有的枪，表也要画满三行
      final at4 = kWeapons.firstWhere((w) => w.name == 'AT4');
      expect(at4.damage, isEmpty);
      expect(at4.damageRows.length, 3);
      expect(at4.damageRows.every((r) => r.isEmpty), isTrue);
    });

    test('PKM 的 4 级甲一整列和 HP 的护甲格是横杠', () {
      final pkm = kWeapons.firstWhere((w) => w.name == 'PKM');
      for (final r in pkm.damage) {
        expect(r.t4, isNull, reason: '两批资料在 4 级甲上差 0.75 倍，判不出哪套对');
      }
      final hp = pkm.damage.firstWhere((r) => r.ammo == 'HP');
      expect(hp.noArmor, 253.01);
      for (var tier = 1; tier < 5; tier++) {
        expect(hp.at(tier), isNull, reason: 'HP 的护甲格两批资料差 0.60 倍');
      }
    });
  });

  group('枪械详情', () {
    /// 搜出某把枪并点开它的详情卡
    Future<void> openSheet(WidgetTester t, String weapon) async {
      const size = Size(402, 874);
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: const MediaQuery(
          data: MediaQueryData(size: size),
          child: LoadoutScreen(),
        ),
      ));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), weapon);
      await t.pumpAndSettle();
      await t.tap(find.text(weapon).last);
      await t.pumpAndSettle();
      // 详情卡从上往下是基础字段、伤害表、配件，伤害表通常要往下拉一点
      await t.drag(find.byType(DraggableScrollableSheet), const Offset(0, -260));
      await t.pumpAndSettle();
    }

    testWidgets('一个数都没有的枪，伤害表照样画出来', (t) async {
      await openSheet(t, 'AT4');
      expect(find.text('爆头伤害 / 护甲等级'), findsOneWidget,
          reason: '整块 section 消失会让人以为 App 不支持这枪，而不是「还没数据」');
      for (final ammo in ['FMJ', 'HP', 'AP']) {
        expect(find.text(ammo), findsOneWidget, reason: '三行固定画满');
      }
      expect(find.text('0'), findsNothing,
          reason: '空格子渲染成 0 等于告诉玩家这枪打上去不掉血');
    });

    testWidgets('PKM 缺的那几格是横杠，不是 0', (t) async {
      await openSheet(t, 'PKM');
      expect(find.text('126.52'), findsOneWidget);
      expect(find.text('253.01'), findsOneWidget);
      expect(find.text('—'), findsWidgets, reason: '横杠');
      expect(find.text('0'), findsNothing);
    });

    testWidgets('存疑的基础字段带问号', (t) async {
      await openSheet(t, 'M500');
      expect(find.text('\$1200 ?'), findsOneWidget,
          reason: '外面能撞见 \$50000 那个数，得让玩家知道这一格有争议');
      expect(find.textContaining('带 ? 的字段'), findsOneWidget,
          reason: '光有问号没有解释，等于没标');
    });
  });

  group('对比页', () {
    Future<void> open(WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: const CompareScreen(),
      ));
      await t.pumpAndSettle();
    }

    testWidgets('在 FMJ / 1级甲 下会标出问号和说明', (t) async {
      await open(t);

      // 默认 FMJ / 无甲：这一组没有存疑值
      expect(find.textContaining('?'), findsNothing);
      expect(find.textContaining('存疑'), findsNothing);

      // 切到 1 级甲
      await t.tap(find.text('1级'));
      await t.pumpAndSettle();

      // AK74 那一格：数字和问号在一起，问号不会被挤到别处去
      expect(find.text('72.79 ?'), findsOneWidget);
      // 说明跟图例在一起，排在柱子上面 —— 收录的枪再多也不会被挤出屏幕
      expect(find.textContaining('存疑'), findsOneWidget);
    });

    testWidgets('没收录的格子不会被排成 0 分柱子', (t) async {
      await open(t);

      // FMJ / 无甲：7 把枪都有值
      expect(find.textContaining('有 7 把'), findsOneWidget);

      // HP / 无甲：T-21 压根没有 HP 这一行，应当直接不出现，而不是排个 0
      await t.tap(find.text('HP'));
      await t.pumpAndSettle();
      expect(find.textContaining('有 6 把'), findsOneWidget);
      expect(find.text('T-21'), findsNothing,
          reason: '没有 HP 数据的枪出现在 HP 榜上，只能是被回退成了 0');

      // HP / 1级甲：PKM 的这一格是横杠，也该退出这一组
      await t.tap(find.text('1级'));
      await t.pumpAndSettle();
      expect(find.textContaining('有 5 把'), findsOneWidget);
      expect(find.text('PKM'), findsNothing);

      // 切回 FMJ / 无甲，两把都该回来
      await t.tap(find.text('FMJ'));
      await t.tap(find.text('无甲'));
      await t.pumpAndSettle();
      expect(find.textContaining('有 7 把'), findsOneWidget);
    });
  });
}
