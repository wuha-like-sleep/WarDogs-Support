import 'dart:math' as math;

/// 一格地图 = 100 米。
///
/// 这个值被改错过一次，教训留在这里：
/// 曾有一组实测反馈说「52.58 格应该是 525 米」，据此把它改成了 10 米。
/// 那是错的 —— 那组坐标本身差了十倍，真实间距是 5.258 格。
/// 改完之后真实的 600 米变成了 60 米，当场暴露。
///
/// 支持 100 米的证据（四个独立来源 + 一条内在一致性）：
/// expcarry、AeroAL/wardogs-calc、wardogshub、wardogs.zone 都写 100；
/// L81 有效射程 132–684 米换算成 1.32–6.84 格，
/// 而实际交战的坐标差正是这个量级。
///
/// 要再改这个值，先拿到**游戏内坐标显示的原始截图**核对格式，
/// 别只凭一个换算后的数字。刻度也可以在 App 里直接切，不必改代码。
const double kGridMeters = 100.0;

/// L81 迫击炮的有效射程（米）。社区实测口径，官方没公布过。
/// 超出这个范围的诸元算得出来也打不到，必须让人一眼看见。
const int kL81MinRange = 132;
const int kL81MaxRange = 684;

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

  /// 这一发 L81 打不打得到
  bool get inL81Range =>
      rangeRounded >= kL81MinRange && rangeRounded <= kL81MaxRange;

  /// 超出射程时给一句人话，射程内返回 null
  String? get rangeWarning {
    if (inL81Range) return null;
    if (rangeRounded < kL81MinRange) return '太近，L81 最少 $kL81MinRange 米';
    return '超出射程，L81 最远 $kL81MaxRange 米';
  }

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
