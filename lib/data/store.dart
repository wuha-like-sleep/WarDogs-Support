import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 记住的一个坐标点。纯本地，存在手机里，不上传任何地方。
class SavedCoord {
  final String label;
  final double x;
  final double y;
  final int savedAt;

  const SavedCoord({
    required this.label,
    required this.x,
    required this.y,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {'l': label, 'x': x, 'y': y, 't': savedAt};

  factory SavedCoord.fromJson(Map<String, dynamic> j) => SavedCoord(
        label: j['l'] as String? ?? '',
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        savedAt: j['t'] as int? ?? 0,
      );

  String get coordText => '${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}';
}

/// 一发的完整记录：打的时候是什么状态，全存下来，能一键还原。
/// 反复试炮位时靠它回看对比。
class ShotRecord {
  final double gunX, gunY, tgtX, tgtY;
  final double offX, offY;
  final int rangeM;
  final String bearing;
  final int savedAt;

  const ShotRecord({
    required this.gunX,
    required this.gunY,
    required this.tgtX,
    required this.tgtY,
    required this.offX,
    required this.offY,
    required this.rangeM,
    required this.bearing,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'gx': gunX,
        'gy': gunY,
        'tx': tgtX,
        'ty': tgtY,
        'ox': offX,
        'oy': offY,
        'r': rangeM,
        'b': bearing,
        't': savedAt,
      };

  factory ShotRecord.fromJson(Map<String, dynamic> j) => ShotRecord(
        gunX: (j['gx'] as num).toDouble(),
        gunY: (j['gy'] as num).toDouble(),
        tgtX: (j['tx'] as num).toDouble(),
        tgtY: (j['ty'] as num).toDouble(),
        offX: (j['ox'] as num?)?.toDouble() ?? 0,
        offY: (j['oy'] as num?)?.toDouble() ?? 0,
        rangeM: (j['r'] as num).toInt(),
        bearing: j['b'] as String? ?? '',
        savedAt: j['t'] as int? ?? 0,
      );

  String get gunText => '${gunX.toStringAsFixed(2)}, ${gunY.toStringAsFixed(2)}';
  String get tgtText => '${tgtX.toStringAsFixed(2)}, ${tgtY.toStringAsFixed(2)}';
  bool get hasOffset => offX != 0 || offY != 0;

  /// 同一发不重复记（坐标和矫正都一样就算同一发）
  bool sameAs(ShotRecord o) =>
      gunX == o.gunX &&
      gunY == o.gunY &&
      tgtX == o.tgtX &&
      tgtY == o.tgtY &&
      offX == o.offX &&
      offY == o.offY;
}

class Store {
  static const _kCoords = 'saved_coords_v1';
  static const _kShots = 'shot_records_v1';
  static const _kStep = 'nudge_step_v1';
  static const _kGunX = 'last_gun_x';
  static const _kGunY = 'last_gun_y';
  static const _kGunAt = 'last_gun_at';

  /// 炮位记忆的保鲜期。超过这个时间多半已经换局换图了，
  /// 再预填就是在让玩家拿着上一局的炮位算诸元，而焦点还会自动跳过它。
  static const gunMemoryTtl = Duration(hours: 12);

  static Future<List<SavedCoord>> loadCoords() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_kCoords) ?? const [];
    final out = <SavedCoord>[];
    for (final s in raw) {
      try {
        out.add(SavedCoord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // 存坏的那条直接跳过，不能因为一条脏数据让整个列表打不开
      }
    }
    out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return out;
  }

  static Future<void> saveCoords(List<SavedCoord> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
      _kCoords,
      list.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  static Future<List<ShotRecord>> loadShots() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_kShots) ?? const [];
    final out = <ShotRecord>[];
    for (final s in raw) {
      try {
        out.add(ShotRecord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // 坏掉的一条不能让整个记录打不开
      }
    }
    out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return out;
  }

  static Future<void> saveShots(List<ShotRecord> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
      _kShots,
      list.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<int> loadStep() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kStep) ?? 25;
  }

  static Future<void> saveStep(int m) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kStep, m);
  }

  /// 炮位通常一局之内不动，所以单独记住，下次打开直接用
  static Future<(String, String)> loadLastGun({DateTime? now}) async {
    final sp = await SharedPreferences.getInstance();
    final at = sp.getInt(_kGunAt);
    if (at == null) return ('', '');
    final age = (now ?? DateTime.now())
        .difference(DateTime.fromMillisecondsSinceEpoch(at));
    if (age > gunMemoryTtl || age.isNegative) return ('', '');
    return (sp.getString(_kGunX) ?? '', sp.getString(_kGunY) ?? '');
  }

  static Future<void> saveLastGun(String x, String y, {DateTime? now}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kGunX, x);
    await sp.setString(_kGunY, y);
    await sp.setInt(
        _kGunAt, (now ?? DateTime.now()).millisecondsSinceEpoch);
  }
}
