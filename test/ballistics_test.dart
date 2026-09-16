import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/ballistics.dart';

void main() {
  group('诸元计算', () {
    // 这是实机验证过的一炮，不是从截图反推的。
    // 刻度从 100 米改到 10 米就是被这组数推翻的，别改它。
    test('实机基准：炮位(100.54,59.02) 目标(62.96,95.79) → 526 米 / 314NW', () {
      final s = solve(gunX: 100.54, gunY: 59.02, targetX: 62.96, targetY: 95.79);
      expect(s.rangeRounded, 526);
      expect(s.bearingRounded, 314);
      expect(s.compass, 'NW');
      expect(s.bearingLabel, '314NW');
      // 这一炮在 L81 射程内 —— 按旧刻度会算成 5258 米，根本打不到
      expect(s.inL81Range, isTrue);
    });

    test('正北 / 正东 / 正南 / 正西 四个方向', () {
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: 1).bearingRounded, 0);
      expect(solve(gunX: 0, gunY: 0, targetX: 1, targetY: 0).bearingRounded, 90);
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: -1).bearingRounded, 180);
      expect(solve(gunX: 0, gunY: 0, targetX: -1, targetY: 0).bearingRounded, 270);
    });

    test('一格等于 10 米', () {
      expect(kGridMeters, 10.0);
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: 1).rangeRounded, 10);
      expect(solve(gunX: 0, gunY: 0, targetX: 3, targetY: 4).rangeRounded, 50);
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: 50).rangeRounded, 500);
    });

    test('罗盘扇区边界不跳错', () {
      expect(compassOf(0), 'N');
      expect(compassOf(22.4), 'N');
      expect(compassOf(22.6), 'NE');
      expect(compassOf(112.4), 'E');
      expect(compassOf(112.6), 'SE');
      expect(compassOf(337.6), 'N');
      expect(compassOf(359.9), 'N');
    });

    test('炮位和目标重合时不炸', () {
      final s = solve(gunX: 50, gunY: 50, targetX: 50, targetY: 50);
      expect(s.rangeRounded, 0);
      expect(s.bearingRounded, 0);
    });
  });

  group('弹着点矫正', () {
    test('上加北、下减北、左减东、右加东', () {
      // 一格 10 米，所以 25 米 = 2.5 格
      var o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.up, stepMeters: 25);
      expect(o.dy, closeTo(2.5, 1e-9));
      o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.down, stepMeters: 25);
      expect(o.dy, closeTo(-2.5, 1e-9));
      o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.left, stepMeters: 50);
      expect(o.dx, closeTo(-5.0, 1e-9));
      o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.right, stepMeters: 50);
      expect(o.dx, closeTo(5.0, 1e-9));
    });

    test('矫正 100 米向北，距离和方位跟着变', () {
      const gx = 100.54, gy = 59.02, tx = 62.96, ty = 95.79;
      final before = solve(gunX: gx, gunY: gy, targetX: tx, targetY: ty);
      final o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.up, stepMeters: 100);
      final after = solve(gunX: gx, gunY: gy, targetX: tx + o.dx, targetY: ty + o.dy);
      expect(after.rangeRounded, isNot(before.rangeRounded));
      // 目标在炮位北边，再往北挪就是越挪越远
      expect(after.rangeMeters, greaterThan(before.rangeMeters));
    });
  });

  group('射程判断', () {
    FireSolution at(double grids) =>
        solve(gunX: 0, gunY: 0, targetX: 0, targetY: grids);

    test('射程内不提示', () {
      expect(at(13.2).rangeWarning, isNull);
      expect(at(40.0).rangeWarning, isNull);
      expect(at(68.4).rangeWarning, isNull);
    });

    test('太近要提示', () {
      expect(at(10.0).rangeWarning, contains('太近'));
      expect(at(5.0).inL81Range, isFalse);
    });

    test('太远要提示', () {
      expect(at(100.0).rangeWarning, contains('超出射程'));
      expect(at(100.0).rangeRounded, 1000);
    });
  });
}
