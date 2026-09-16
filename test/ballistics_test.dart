import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/ballistics.dart';

void main() {
  group('诸元计算', () {
    // 基准：一发落在 L81 射程内的正常射击。
    // 判据不是「某人报的数」，而是坐标差必须换算出射程内的距离 ——
    // 刻度错十倍时这条会立刻红。
    test('基准：相距 5.66 格 → 566 米 / 133SE，且在射程内', () {
      final s = solve(gunX: 63.41, gunY: 104.52, targetX: 67.56, targetY: 100.67);
      expect(s.rangeRounded, 566);
      expect(s.bearingRounded, 133);
      expect(s.bearingLabel, '133SE');
      expect(s.inL81Range, isTrue);
    });

    test('刻度错十倍会让正常射击掉出射程 —— 这就是回归的护栏', () {
      // 真实交战的坐标差在 1.3–6.8 格之间，换算后必须落在 132–684 米
      for (final grids in [1.4, 3.0, 5.0, 6.8]) {
        final s = solve(gunX: 0, gunY: 0, targetX: 0, targetY: grids);
        expect(s.inL81Range, isTrue,
            reason: '相距 $grids 格应当是一次可打的射击，'
                '算出 ${s.rangeRounded} 米说明刻度错了');
      }
    });

    test('正北 / 正东 / 正南 / 正西 四个方向', () {
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: 1).bearingRounded, 0);
      expect(solve(gunX: 0, gunY: 0, targetX: 1, targetY: 0).bearingRounded, 90);
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: -1).bearingRounded, 180);
      expect(solve(gunX: 0, gunY: 0, targetX: -1, targetY: 0).bearingRounded, 270);
    });

    test('一格等于 100 米', () {
      expect(kGridMeters, 100.0);
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: 1).rangeRounded, 100);
      expect(solve(gunX: 0, gunY: 0, targetX: 3, targetY: 4).rangeRounded, 500);
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
      // 一格 100 米，所以 25 米 = 0.25 格
      var o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.up, stepMeters: 25);
      expect(o.dy, closeTo(0.25, 1e-9));
      o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.down, stepMeters: 25);
      expect(o.dy, closeTo(-0.25, 1e-9));
      o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.left, stepMeters: 50);
      expect(o.dx, closeTo(-0.5, 1e-9));
      o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.right, stepMeters: 50);
      expect(o.dx, closeTo(0.5, 1e-9));
    });

    test('矫正 100 米向北，距离和方位跟着变', () {
      const gx = 63.41, gy = 104.52, tx = 67.56, ty = 100.67;
      final before = solve(gunX: gx, gunY: gy, targetX: tx, targetY: ty);
      final o = applyNudge(offsetX: 0, offsetY: 0, direction: Nudge.up, stepMeters: 100);
      final after = solve(gunX: gx, gunY: gy, targetX: tx + o.dx, targetY: ty + o.dy);
      expect(after.rangeRounded, isNot(before.rangeRounded));
      // 目标在炮位南边，往北挪就是朝炮位靠，距离变近
      expect(after.rangeMeters, lessThan(before.rangeMeters));
    });
  });

  group('射程判断', () {
    FireSolution at(double grids) =>
        solve(gunX: 0, gunY: 0, targetX: 0, targetY: grids);

    test('射程内不提示', () {
      expect(at(1.32).rangeWarning, isNull);
      expect(at(4.0).rangeWarning, isNull);
      expect(at(6.84).rangeWarning, isNull);
    });

    test('太近要提示', () {
      expect(at(1.0).rangeWarning, contains('太近'));
      expect(at(0.5).inL81Range, isFalse);
    });

    test('太远要提示', () {
      expect(at(10.0).rangeWarning, contains('超出射程'));
      expect(at(10.0).rangeRounded, 1000);
    });
  });
}
