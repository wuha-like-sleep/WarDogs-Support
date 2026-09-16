/// WARDOGS 本地资料库。
/// 全部硬编码进包里 —— App 不联网，所以这里就是唯一数据源。
/// 数据整理自 WARDOGS WIKI，游戏仍在更新，以游戏内实际数值为准。
library;

class Weapon {
  final String name;
  final String category;

  /// 下面这些拿得到就填，拿不到留 null，界面上显示横杠而不是把整行藏掉
  final int? priceUsd;
  final double? weightKg;
  final String? caliber;
  final String? fireModes;
  final String? track;
  final String? unlock;
  final List<AmmoRow> damage;
  final Map<String, String> attachments;

  const Weapon({
    required this.name,
    required this.category,
    this.priceUsd,
    this.weightKg,
    this.caliber,
    this.fireModes,
    this.track,
    this.unlock,
    this.damage = const [],
    this.attachments = const {},
  });

  bool get hasDetail => damage.isNotEmpty || caliber != null;

  /// 列表行上直接显示的数字：FMJ 打无甲的爆头伤害。
  /// 玩家扫一眼就知道这枪够不够狠，比「有没有数据」有用得多。
  double? get headshotFmj {
    for (final r in damage) {
      if (r.ammo == 'FMJ') return r.noArmor;
    }
    return null;
  }
}

/// 一种弹药对各护甲等级的**爆头**伤害（wiki 原文：以爆头伤害计算）
class AmmoRow {
  final String ammo;
  final double noArmor, t1, t2, t3, t4;

  /// 哪几格的数值存疑（0=无甲，1..4=各级护甲）。
  /// 照抄数据源、不擅自改，但要让玩家看得见疑点在哪。
  final Set<int> doubtful;

  const AmmoRow(
    this.ammo,
    this.noArmor,
    this.t1,
    this.t2,
    this.t3,
    this.t4, {
    this.doubtful = const {},
  });

  double at(int tier) => switch (tier) {
        0 => noArmor,
        1 => t1,
        2 => t2,
        3 => t3,
        _ => t4,
      };

  bool isDoubtful(int tier) => doubtful.contains(tier);
}

const kAmmoNotes = <String, String>{
  'FMJ': '通用弹，各情况都不吃亏，拿不准就用它',
  'HP': '空尖弹，打没甲和轻甲爆发高，遇到重甲基本打不动',
  'AP': '穿甲弹，专治高级护甲，低甲目标伤害反而不如另外两种',
};

const kWeaponCategories = <String>[
  '突击步枪',
  '冲锋枪',
  '霰弹枪',
  '轻机枪',
  '射手步枪',
  '狙击步枪',
  '发射器',
  '副武器',
  '其他',
];

const kWeapons = <Weapon>[
  Weapon(
    name: 'AK74',
    category: '突击步枪',
    priceUsd: 1600,
    weightKg: 3,
    caliber: '5.45×39mm',
    fireModes: '半自动 / 全自动',
    track: '突击兵',
    unlock: '突击兵 3 级，另需 \$10000',
    damage: [
      // 72.79 比无甲的 61.12 还高，是全表唯一「穿了甲反而更疼」的一格。
      // 另外三把有数据的枪，护甲衰减严格是 0.70/0.60/0.45/0.35，
      // AK74 的 2/3/4 级也精确吻合，只有这一格是 1.191。
      // 大概率是资料源录错，但没有实测依据，所以照原值保留并标存疑。
      AmmoRow('FMJ', 61.12, 72.79, 36.67, 27.51, 21.40, doubtful: {1}),
      AmmoRow('HP', 122.21, 12.12, 8.81, 3.87, 0.56),
      AmmoRow('AP', 48.90, 40.10, 37.17, 32.76, 29.83),
    ],
    attachments: {
      '弹匣': '30 发 / 60 发 / 75 发弹鼓',
      '瞄具': '短距与中距瞄准镜',
      '握把': '战术、人体工学、垂直、倾斜等 10 种',
      '枪口': '制退器与抑制器共 4 种',
    },
  ),
  Weapon(name: 'Bushmaster M17S', category: '突击步枪', track: '突击兵'),
  Weapon(name: 'A-91', category: '突击步枪', track: '突击兵'),
  Weapon(name: 'KH-2002', category: '突击步枪', track: '突击兵'),
  Weapon(name: 'T-21', category: '突击步枪', track: '突击兵'),
  Weapon(name: 'GALIL', category: '突击步枪', track: '突击兵'),
  Weapon(name: 'M4', category: '突击步枪', track: '突击兵'),
  Weapon(
    name: 'FAL',
    category: '突击步枪',
    track: '突击兵',
    damage: [
      AmmoRow('FMJ', 141.00, 98.72, 84.61, 63.46, 37.03),
      AmmoRow('HP', 282.00, 27.94, 20.34, 8.91, 0.96),
      AmmoRow('AP', 112.83, 95.90, 90.25, 81.80, 57.12),
    ],
  ),
  Weapon(name: 'AMP-9', category: '冲锋枪'),
  Weapon(name: 'PP-19 VITYAZ', category: '冲锋枪'),
  Weapon(
    name: 'MP5',
    category: '冲锋枪',
    damage: [
      AmmoRow('FMJ', 46.22, 32.36, 27.75, 20.81, 16.18),
      AmmoRow('HP', 92.44, 9.16, 6.67, 2.92, 0.43),
      AmmoRow('AP', 36.99, 29.21, 26.62, 22.74, 20.16),
    ],
  ),
  Weapon(name: 'SUPER-45', category: '冲锋枪'),
  Weapon(name: 'MP43', category: '霰弹枪'),
  Weapon(name: 'M500', category: '霰弹枪'),
  Weapon(name: 'M249 SAW', category: '轻机枪', track: '支援兵'),
  Weapon(name: 'PKM', category: '轻机枪', track: '支援兵'),
  Weapon(name: 'SKS', category: '射手步枪'),
  Weapon(name: 'SVD', category: '射手步枪'),
  Weapon(name: 'BMR-308', category: '射手步枪'),
  Weapon(name: 'TD 侦查步枪', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: '莫辛步枪', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: 'SV98', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: 'MK22', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: 'AMR 50', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: '9K333 VERBA', category: '发射器', unlock: '防空导弹'),
  Weapon(name: 'MAAWS', category: '发射器'),
  Weapon(name: 'MGL-40', category: '发射器'),
  Weapon(name: 'RPG-7', category: '发射器'),
  Weapon(name: 'AT4', category: '发射器'),
  Weapon(name: 'GGX 17', category: '副武器'),
  Weapon(name: 'GGX 18', category: '副武器'),
  Weapon(name: 'JUDGE', category: '副武器'),
  Weapon(
    name: 'M1911',
    category: '副武器',
    damage: [
      AmmoRow('FMJ', 81.82, 57.28, 49.12, 36.85, 28.65),
      AmmoRow('HP', 163.64, 16.22, 11.80, 5.17, 0.76),
      AmmoRow('AP', 65.48, 51.70, 47.12, 40.25, 35.68),
    ],
  ),
  Weapon(name: 'DEAGLE', category: '副武器'),
  Weapon(name: '复合弓', category: '其他', track: '侦察兵'),
  Weapon(name: 'M12G', category: '其他'),
  Weapon(name: 'BROWNING MG', category: '其他'),
  Weapon(name: 'G60', category: '其他'),
];

// ------------------------------------------------------------------ 载具

class Vehicle {
  final String name;
  final String category;
  final String? note;

  const Vehicle(this.name, this.category, {this.note});
}

const kVehicleCategories = <String>['轻型载具', '重型载具', '直升机', '固定武器'];

const kVehicles = <Vehicle>[
  Vehicle('BOBCAT', '轻型载具'),
  Vehicle('DUNE BUGGY', '轻型载具'),
  Vehicle('KODIAK', '轻型载具'),
  Vehicle('KODIAK PICKUP', '轻型载具'),
  Vehicle('KODIAK M249', '轻型载具', note: '带 M249 机枪位'),
  Vehicle('HUMVEE', '轻型载具'),
  Vehicle('HUMVEE M249', '轻型载具', note: '带 M249 机枪位'),
  Vehicle('HUMVEE MINIGUN', '轻型载具', note: '带转管机枪'),
  Vehicle('URAL', '轻型载具', note: '运输卡车'),
  Vehicle('URAL DEFENDER', '轻型载具'),
  Vehicle('URAL DEFENDER M249', '轻型载具', note: '带 M249 机枪位'),
  Vehicle('FLAKPANZER GEPARD', '重型载具', note: '自行高炮，打直升机'),
  Vehicle('L2A6', '重型载具', note: '主战坦克'),
  Vehicle('SPH-2', '重型载具', note: '自行火炮'),
  Vehicle('AH-6M MINIGUNS', '直升机', note: '转管机枪型'),
  Vehicle('AH-6R ROCKETS', '直升机', note: '火箭型'),
  Vehicle('MH-6', '直升机', note: '运输型'),
  Vehicle('HAVOC', '直升机', note: '重型武装'),
  Vehicle('Z20 LAKOTA', '直升机'),
  Vehicle('Z20 LAKOTA MINIGUNS', '直升机', note: '转管机枪型'),
  Vehicle('L81 迫击炮', '固定武器', note: '本 App 计算器算的就是它'),
  Vehicle('TALON 9KSAM', '固定武器', note: '防空导弹'),
  Vehicle('VANGUARD CIWS', '固定武器', note: '近防炮'),
  Vehicle('STINGRAY', '固定武器'),
  Vehicle('LOUDSPEAKER', '固定武器', note: '扩音器'),
];

// ------------------------------------------------------------ 进度线 / 系统

class Track {
  final String name;
  final String howToLevel;
  final String unlocks;

  const Track(this.name, this.howToLevel, this.unlocks);
}

/// WARDOGS 没有固定职业选择界面 —— 你买什么装备，你就是什么角色。
/// 六条进度线各自独立升级。
const kTracks = <Track>[
  Track('突击兵', '正面交战、击杀推进', '突击步枪、冲锋枪、进攻类装备'),
  Track('医护兵', '治疗与救起队友', '医疗装备、复活相关道具'),
  Track('侦察兵', '标记敌人、远距离作战', '狙击步枪、侦察器材、复合弓'),
  Track('支援兵', '补给弹药、建造工事', '轻机枪、弹药箱、建造相关'),
  Track('驾驶员', '驾驶地面载具', '地面载具与车载武器'),
  Track('飞行员', '驾驶直升机', '直升机机型'),
];

class SystemNote {
  final String title;
  final String body;

  const SystemNote(this.title, this.body);
}

const kSystems = <SystemNote>[
  SystemNote(
    '基本规则',
    '100 人分三个阵营，抢大地图里 2×2 公里的控制区，先到 100 分赢。丢点比丢人致命。',
  ),
  SystemNote(
    '钱跨局保留',
    '开局给 10000 美元，装备是买出来的，不是解锁就白给。这局省下的钱下局还在，'
        '所以死得越少、攒得越多，后期能玩的东西越多。',
  ),
  SystemNote(
    'FOB 前进基地',
    '前线的重生与补给点。摸掉对面的 FOB，往往比正面强推划算得多。',
  ),
  SystemNote(
    '钻井平台',
    '持续产出资源，资源决定你买得起什么装备。守住它，全队一直有钱。',
  ),
  SystemNote(
    '建造与破坏',
    '工事能自己搭，建筑也会被打烂。你身后那堵墙随时可能没了。',
  ),
  SystemNote(
    '弹药怎么选',
    'FMJ 通用，拿不准就用它。HP 打无甲和轻甲爆发高，碰上重甲基本无效。'
        'AP 专治高级护甲，打软目标反而不如前两种。',
  ),
  SystemNote(
    '迫击炮怎么打',
    '打的是看不见的目标，全靠队友报坐标。填进计算器按算出的距离和方向调炮，'
        '第一发偏了用「弹着点矫正」挪，不用重新读坐标。',
  ),
];
