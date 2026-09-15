import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/screens/compare_screen.dart';
import 'package:wardogs_assistant/screens/logistics_screen.dart';
import 'package:wardogs_assistant/theme.dart';

/// 分段控件曾经只有文字那一小块能点，周围空白点不动（真机上复现过）。
/// 这里专门点文字**上方的空白**，确保整段都是热区。
void main() {
  Future<void> tapBesideText(WidgetTester t, String label) async {
    final center = t.getCenter(find.text(label));
    // 段高 36，文字约 18 高 —— 往上偏 13 就落在文字外、段内
    await t.tapAt(center.translate(0, -13));
    await t.pumpAndSettle();
  }

  testWidgets('后勤的分段控件：点文字旁边的空白也能切换', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const LogisticsScreen(),
    ));
    await t.pumpAndSettle();

    // 默认在「载具」
    expect(find.text('BOBCAT'), findsOneWidget);

    await tapBesideText(t, '机制');
    expect(find.text('BOBCAT'), findsNothing);
    expect(find.text('基本规则'), findsOneWidget);

    await tapBesideText(t, '进度线');
    expect(find.text('突击兵'), findsOneWidget);
  });

  testWidgets('伤害对比的分段控件：点文字旁边的空白也能切换', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const CompareScreen(),
    ));
    await t.pumpAndSettle();

    // FMJ / 无甲 下 FAL 是 141
    expect(find.text('141'), findsOneWidget);

    await tapBesideText(t, 'AP');
    // 换成 AP 弹，数值整体变了
    expect(find.text('141'), findsNothing);
    expect(find.text('112.83'), findsOneWidget);
  });
}
