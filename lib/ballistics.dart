import 'dart:math' as math;

/// 一格地图 = 100 米（由截图反推验证：
/// 炮位(63.41,104.52) 敌人(67.56,100.67) → 5.6608 格 → 566 米）
const double kGridMeters = 100.0;

/// 八方位罗盘，用于把角度标成 SE / NW 这种后缀
const List<String> _sectors = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

String compassOf(double bearingDeg) {
  final normalized = (bearingDeg % 360 + 360) % 360;
  // 每个扇区 45°，以正方向为中心，所以整体偏移 22.5°
  final index = (((normalized + 22.5) % 360) / 45).floor();
  return _sectors[index % 8];
}

/// 一次射击诸元
class FireSolution {
  /// 距离（米）
  final double rangeMeters;

  /// 方位角（度，正北为 0，顺时针增加）
  final double bearingDeg;

  const FireSolution({required this.rangeMeters, required this.bearingDeg});

  /// 取整后的距离，报诸元时用
  int get rangeRounded => rangeMeters.round();

  /// 取整后的方位角
  int get bearingRounded {
    final r = bearingDeg.round() % 360;
    return r < 0 ? r + 360 : r;
  }

  String get compass => compassOf(bearingDeg);

  /// 形如 "133SE"
  String get bearingLabel => '$bearingRounded$compass';

  /// 可以直接粘给队友的一行诸元
  String get shareText => '距离 $rangeRounded 米 · 方向 $bearingLabel';
}

/// 由炮位和目标位算诸元。
///
/// 坐标沿用游戏地图格：X 向东为正，Y 向北为正。
/// 方位角 = atan2(东向分量, 北向分量)，正北 0°，顺时针。
FireSolution solve({
  required double gunX,
  required double gunY,
  required double targetX,
  required double targetY,
  double gridMeters = kGridMeters,
}) {
  final dx = targetX - gunX; // 东
  final dy = targetY - gunY; // 北
  final range = math.sqrt(dx * dx + dy * dy) * gridMeters;
  final bearing = (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
  return FireSolution(rangeMeters: range, bearingDeg: bearing);
}

/// 弹着点矫正的四个方向（按地图看：上=北）
enum Nudge { up, down, left, right }

/// 把矫正量（米）叠加到目标坐标上，返回新的偏移量（单位：格）。
/// 分开存偏移量而不是直接改敌人坐标，这样报点原值还在、随时能清零。
({double dx, double dy}) applyNudge({
  required double offsetX,
  required double offsetY,
  required Nudge direction,
  required double stepMeters,
  double gridMeters = kGridMeters,
}) {
  final step = stepMeters / gridMeters;
  switch (direction) {
    case Nudge.up:
      return (dx: offsetX, dy: offsetY + step);
    case Nudge.down:
      return (dx: offsetX, dy: offsetY - step);
    case Nudge.left:
      return (dx: offsetX - step, dy: offsetY);
    case Nudge.right:
      return (dx: offsetX + step, dy: offsetY);
  }
}
