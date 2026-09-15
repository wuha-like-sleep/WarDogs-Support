import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/ballistics.dart';

void main() {
  group('诸元计算', () {
    test('复现截图里的那一炮：566 米 / 133SE', () {
      final s = solve(gunX: 63.41, gunY: 104.52, targetX: 67.56, targetY: 100.67);
      expect(s.rangeRounded, 566);
      expect(s.bearingRounded, 133);
      expect(s.compass, 'SE');
      expect(s.bearingLabel, '133SE');
    });

    test('正北 / 正东 / 正南 / 正西 四个方向', () {
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: 1).bearingRounded, 0);
      expect(solve(gunX: 0, gunY: 0, targetX: 1, targetY: 0).bearingRounded, 90);
      expect(solve(gunX: 0, gunY: 0, targetX: 0, targetY: -1).bearingRounded, 180);
      expect(solve(gunX: 0, gunY: 0, targetX: -1, targetY: 0).bearingRounded, 270);
    });

    test('一格等于 100 米', () {
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
      // 往北挪 = 朝炮位方向靠，距离应该变近
      expect(after.rangeMeters, lessThan(before.rangeMeters));
    });
  });
}
