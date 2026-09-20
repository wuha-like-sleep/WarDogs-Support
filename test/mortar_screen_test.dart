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

  testWidgets('换目标后，上一个目标的矫正量不能残留', (t) async {
    // 视口调高，让整页一次装下 —— 否则滚动会把输入框从树里回收掉
    t.view.physicalSize = const Size(1200, 4200);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await pumpScreen(t);

    // 炮位 (0,0)，目标 (0,5) → 500 米
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '5');
    await t.pump();
    expect(find.text('500'), findsOneWidget);

    // 试射后往南修正 25 米 → 475
    await scrollAndPress(t, '下');
    expect(find.text('475'), findsOneWidget);
    expect(find.textContaining('已矫正'), findsOneWidget);

    // 换目标：清空重输 60。焦点还在 tgtY 上。
    await press(t, 'C');
    await typeNumber(t, '6');
    await t.pump();

    // 新目标应该是干干净净的 600，而不是带着上一发 25 米修正的 575
    expect(find.text('600'), findsOneWidget,
        reason: '换目标后诸元必须重新从坐标算，不能带上一个目标的矫正量');
    expect(find.text('575'), findsNothing);
    expect(find.textContaining('已矫正'), findsNothing);
  });

  testWidgets('空格子上按负号不能产生孤零零的 "-"', (t) async {
    await pumpScreen(t);
    await press(t, '−');
    await t.pump();
    // "-" 解析不出来，却会画在格子里看着像填好了，还会被存进磁盘
    expect(find.text('-'), findsNothing);
  });

  testWidgets('切到格子后第一个数字是重打，不是接在旧值后面', (t) async {
    // 视口给足：这条验的是输入行为，不是滚动。
    // 默认 800×600 下敌人坐标框会滚出构建范围，find 不到。
    t.view.physicalSize = const Size(1200, 4200);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await pumpScreen(t);
    await typeNumber(t, '67.56');
    await press(t, '下一项');
    await press(t, '下一项');
    await press(t, '下一项');
    // 现在焦点在敌人 Y 上，是「刚切过来」的状态
    await typeNumber(t, '70.12');
    await t.pump();
    expect(find.text('70.12'), findsOneWidget);
    // 这个才是原来的 bug：合法、解析得出、但错得离谱
    expect(find.text('67.5670.12'), findsNothing);
    expect(find.text('67.567012'), findsNothing);
  });

  testWidgets('坐标长度有上限，撑不爆输入框', (t) async {
    await pumpScreen(t);
    await typeNumber(t, '1234567890123');
    await t.pump();
    expect(find.text('12345678'), findsOneWidget);
  });

  testWidgets('矫正后点清零，提示要消掉', (t) async {
    t.view.physicalSize = const Size(1200, 4200);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await pumpScreen(t);
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '0');
    await press(t, '下一项');
    await typeNumber(t, '5');
    await t.pump();

    await scrollAndPress(t, '10');
    for (var i = 0; i < 3; i++) {
      await scrollAndPress(t, '上');
    }
    expect(find.textContaining('已矫正'), findsOneWidget);

    await scrollAndPress(t, '清零');
    expect(find.textContaining('已矫正'), findsNothing);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('刚打开时诸元卡片不能被顶出屏幕', (t) async {
    // 这条盯的是「看得见」，不是「找得到」——
    // 滚出视口的组件在 widget 树里照样 find 得到，
    // 134 条测试全绿的时候，真机上卡片顶部是被截掉的。
    t.view.physicalSize = const Size(1125, 2001); // iPhone SE 375×667
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await pumpScreen(t);

    for (final label in ['RNG', '方向']) {
      final r = t.getRect(find.text(label));
      expect(r.top, greaterThanOrEqualTo(0.0),
          reason: '「$label」被顶到屏幕上方看不见了（top=${r.top}）');
      expect(r.bottom, lessThanOrEqualTo(667.0),
          reason: '「$label」跑到屏幕下方去了（bottom=${r.bottom}）');
    }
  });

  testWidgets('小屏上切到敌人坐标，那个框必须滚进视野', (t) async {
    // 320×568（iPhone SE 一代）：目前能装下的最小屏。
    // 键盘一弹，敌人坐标那两个框就在折叠线附近。
    // 这条盯的是「正在输入的框到底看不看得见」，
    // 不是「找不找得到」—— 看不见就等于闭着眼敲坐标。
    t.view.physicalSize = const Size(960, 1704);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await pumpScreen(t);

    // 切到敌人 X
    await press(t, '下一项');
    await press(t, '下一项');
    await t.pumpAndSettle();

    // 敌人位置那一组必须出现在屏幕内
    final label = find.text('敌人位置');
    expect(label, findsOneWidget,
        reason: '敌人位置整块都没构建 —— 滚动没生效');

    final r = t.getRect(label);
    expect(r.top, greaterThanOrEqualTo(0.0),
        reason: '「敌人位置」在屏幕上方外面（top=${r.top}）');

    // 光标签可见没用 —— 真正要输入的是它下面那两个框（高 52，外加 6 间距）。
    // 只查标签的话，标签卡在屏幕最下沿也算过，而框还在外面。
    const fieldBottom = 6 + 52.0;
    expect(r.bottom + fieldBottom, lessThanOrEqualTo(568.0),
        reason: '「敌人位置」下面那两个输入框超出屏幕了'
            '（标签底 ${r.bottom}，框底 ${r.bottom + fieldBottom}）—— '
            '玩家看不见自己在往哪个框里敲');
  });
}
