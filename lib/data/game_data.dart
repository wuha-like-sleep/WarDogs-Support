/// WARDOGS 本地资料库。
/// 全部硬编码进包里 —— App 不联网，所以这里就是唯一数据源。
///
/// 数据来源不是一家，主要有四条互相独立的线：
///   A. bwiki（哔哩哔哩合作 wiki，人工誊抄游戏内图鉴）
///   B. wardogs.zone —— 从游戏数据文件提取 + 自建伤害模型。
///      注意 wardogshub.gg 是它的换皮镜像（canonical 与 ld+json 都指回 zone），
///      两个域名算一条线，不能拿来互相印证。
///   C. GitHub Goldpip3/wardogs-base-builder 的 armory.json（游戏内物品库转录）
///   D. wardogshandbook.com（游戏内实测）
/// 游戏处在抢先体验，官方从未公布过武器数值表，以上全是社区记录。
///
/// 规矩：拿不到就留 null，不填 0、不按比例反推。
/// 几条线对不上的格子也留 null 或标存疑，不替资料源做决定。
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

  /// 上面哪几个基础字段存疑，用字段名写：
  /// priceUsd / weightKg / caliber / fireModes / track / unlock。
  /// 只标有值的字段 —— 值是 null 的那格本来就显示横杠，再加问号没有意义。
  final Set<String> doubtfulFields;

  /// 这把枪的数据状况：哪几格是横杠、为什么，哪几格带问号、为什么。
  /// 直接显示给玩家看，别写成只有自己看得懂的备注。
  final String? dataNote;

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
    this.doubtfulFields = const {},
    this.dataNote,
  });

  bool get hasDetail => damage.isNotEmpty || caliber != null;

  bool isFieldDoubtful(String field) => doubtfulFields.contains(field);

  /// 伤害表固定按 FMJ / HP / AP 三行画出来。
  /// 没收录的那一种返回全空的一行 —— 空着不等于伤害是 0，
  /// 整行消失会让玩家以为这枪不吃这种弹，那是另一回事。
  List<AmmoRow> get damageRows => [
        for (final a in kAmmoTypes)
          damage.firstWhere(
            (r) => r.ammo == a,
            orElse: () => AmmoRow(a, null, null, null, null, null),
          ),
      ];

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
///
/// 每一格都可以是 null。别把 null 当 0 用 ——
/// 「没查到」和「打上去不掉血」是两回事，后者会让人拿着枪去送。
class AmmoRow {
  final String ammo;
  final double? noArmor, t1, t2, t3, t4;

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

  double? at(int tier) => switch (tier) {
        0 => noArmor,
        1 => t1,
        2 => t2,
        3 => t3,
        _ => t4,
      };

  bool isDoubtful(int tier) => doubtful.contains(tier);

  bool get isEmpty =>
      noArmor == null && t1 == null && t2 == null && t3 == null && t4 == null;
}

/// 伤害表的固定行序
const kAmmoTypes = <String>['FMJ', 'HP', 'AP'];

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
  // 来源：bwiki / wardogs.zone 家族 / Goldpip3 armory.json + wardogshandbook.com
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
      // AK74 自己的 2/3/4 级是 0.60/0.45/0.35，只有这一格是 1.191。
      // 大概率是资料源录错，但没有实测依据，所以照原值保留并标存疑。
      AmmoRow('FMJ', 61.12, 72.79, 36.67, 27.51, 21.40, doubtful: {1}),
      AmmoRow('HP', 122.21, 12.12, 8.81, 3.87, 0.56),
      AmmoRow('AP', 48.90, 40.10, 37.17, 32.76, 29.83),
    ],
    dataNote: '带 ? 的那格存疑：穿了甲反而比没甲疼，与常理相反。',
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
  // 来源：三条独立线吻合 —— bwiki（图鉴誊抄）/ wardogs.zone 家族（数据文件提取）
  //       / Goldpip3 armory.json + wardogshandbook.com（游戏内实测）。
  // 基础字段五处逐字一致；FMJ 三线给 65.81/65.80/65.82，取 65.82，
  // 且 ×0.70/0.60/0.45/0.35 与本表其余各枪逐格吻合。
  // HP、AP 不填：两批资料差一个固定的 0.60 倍（HP）和整条不同的曲线（AP），
  // 是两套建模口径之争，各自内部都自洽，淘汰不掉任何一方。
  // 进度线三比一取「突击兵」（zone 写 Infantry），有分歧所以标存疑。
  // 另一家把 priceUsd 写 0，那一列量的是解锁费不是军械库售价，不是冲突。
  Weapon(
    name: 'T-21',
    category: '突击步枪',
    priceUsd: 600,
    weightKg: 3.27,
    caliber: '5.56×45mm',
    fireModes: '半自动 / 全自动',
    track: '突击兵',
    unlock: '初始解锁，无需等级',
    damage: [
      AmmoRow('FMJ', 65.82, 46.07, 39.49, 29.62, 23.04),
    ],
    doubtfulFields: {'track'},
    dataNote: '只查到 FMJ 的数值，HP 和 AP 暂缺。',
  ),
  Weapon(name: 'GALIL', category: '突击步枪', track: '突击兵'),
  Weapon(name: 'M4', category: '突击步枪', track: '突击兵'),
  // 来源同 AK74。
  // 4 级甲两格标存疑：FMJ 37.03 对无甲是 0.263、AP 57.12 是 0.506，
  // 都不在 FAL 自己那条曲线上（其余各格是 0.70/0.60/0.45 与 0.85/0.80/0.725）。
  // 按自己的曲线应为 49.35 与 76.16，实际值正好是它们的 0.75 倍 ——
  // 另一批资料的 4 级甲整体就差这个 0.75 倍，这两格像是混进了那一套。
  // 没有实测依据，所以照原值保留并标存疑，不擅自改。
  Weapon(
    name: 'FAL',
    category: '突击步枪',
    track: '突击兵',
    damage: [
      AmmoRow('FMJ', 141.00, 98.72, 84.61, 63.46, 37.03, doubtful: {4}),
      AmmoRow('HP', 282.00, 27.94, 20.34, 8.91, 0.96),
      AmmoRow('AP', 112.83, 95.90, 90.25, 81.80, 57.12, doubtful: {4}),
    ],
    dataNote: '4 级甲那两格存疑：不在这把枪自己的衰减规律上。',
  ),
  Weapon(name: 'AMP-9', category: '冲锋枪'),
  Weapon(name: 'PP-19 VITYAZ', category: '冲锋枪'),
  // 来源同 AK74。
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
  // 来源：wardogs.zone 家族 / Goldpip3 armory.json + wardogshandbook.com。
  // bwiki 这一条整条是空的 —— 这把枪恰好缺了「人工誊抄图鉴」那条旁证，
  // 所以只有两条线，是全表旁证最薄的一把。
  // 价格：另一家写 50000，那是解锁费串进了价格列（它自己的解锁文案里也写着
  // 同一个 50000），取 1200，但外面确实能撞见 50000 这个数，标存疑。
  // 射击模式：三处都写半自动，但 M500 原型是泵动；三处同源，无法区分是
  // 游戏真这么建模还是同一个错被抄了三遍，标存疑。
  // 伤害不填，理由见 dataNote。
  Weapon(
    name: 'M500',
    category: '霰弹枪',
    priceUsd: 1200,
    weightKg: 3.52,
    caliber: '12 Gauge',
    fireModes: '半自动',
    track: '支援兵',
    unlock: '支援兵 10 级，另需 \$50000',
    doubtfulFields: {'priceUsd', 'fireModes'},
    dataNote: '霰弹按每颗弹丸计伤，和其它枪不是一套算法，暂不列出。',
  ),
  Weapon(name: 'M249 SAW', category: '轻机枪', track: '支援兵'),
  // 来源：wardogs.zone 家族 / Goldpip3 + wardogshandbook.com，两条线。
  // 解锁等级 30 另经 bwiki 独立复核，是本条证据最硬的一项。
  // 价格 4500 是商店售价；另一家写的 150000 是解锁费串进了价格列，不采用。
  // 口径取 7.62×54mmR（R 是该弹的正确命名，两条线只差这个字母）。
  // 无甲一列两条线一致，且满足本表铁律：HP无甲 = FMJ无甲×2、AP无甲 = FMJ无甲×0.80。
  // FMJ/AP 的 1–3 级两条线逐格吻合，且落在 0.70/0.60/0.45 与 0.85/0.80/0.725 上。
  // 留空的格子见 dataNote。
  Weapon(
    name: 'PKM',
    category: '轻机枪',
    priceUsd: 4500,
    weightKg: 7.5,
    caliber: '7.62×54mmR',
    fireModes: '半自动 / 全自动',
    track: '支援兵',
    unlock: '支援兵 30 级，另需 \$150000',
    damage: [
      AmmoRow('FMJ', 126.52, 88.56, 75.91, 56.93, null),
      AmmoRow('HP', 253.01, null, null, null, null),
      AmmoRow('AP', 101.21, 86.03, 80.99, 73.40, null),
    ],
    doubtfulFields: {'priceUsd', 'weightKg'},
    dataNote: '4 级甲和 HP 的部分数值暂缺。价格与重量未经证实。',
  ),
  Weapon(name: 'SKS', category: '射手步枪'),
  Weapon(name: 'SVD', category: '射手步枪'),
  Weapon(name: 'BMR-308', category: '射手步枪'),
  Weapon(name: 'TD 侦查步枪', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: '莫辛步枪', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: 'SV98', category: '狙击步枪', track: '侦察兵'),
  Weapon(name: 'MK22', category: '狙击步枪', track: '侦察兵'),
  // 来源：bwiki / wardogs.zone 家族 / Goldpip3 armory.json + wardogshandbook.com。
  // FMJ 是全条最硬的一项：三条独立线逐位吻合（342.41 / 342.42 / 342），
  // 衰减 0.70/0.60/0.45/0.35 与本表其余各枪一致。
  // HP、AP 只有 wardogs.zone 一家给，且 AP 的有甲四格对不上它自己公布的
  // 留存表（85/80/72.5/67.5%），整行标存疑。
  // 价格 8800 是商店售价；另一家写的 200000 是解锁费串进了价格列。
  // 射击模式那一串其实是「枪机形式 + 供弹方式」，不是开火模式，且只有一家给，标存疑。
  Weapon(
    name: 'AMR 50',
    category: '狙击步枪',
    priceUsd: 8800,
    weightKg: 12.5,
    caliber: '.50 Cal',
    fireModes: '栓动 / 弹匣供弹',
    track: '侦察兵',
    unlock: '侦察兵 35 级，另需 \$200000',
    damage: [
      AmmoRow('FMJ', 342.41, 239.69, 205.45, 154.08, 119.84),
      AmmoRow('HP', 685.00, 67.80, 49.30, 21.60, 3.10,
          doubtful: {0, 1, 2, 3, 4}),
      AmmoRow('AP', 274.00, 249.00, 241.00, 229.00, 221.00,
          doubtful: {0, 1, 2, 3, 4}),
    ],
    doubtfulFields: {'fireModes'},
    dataNote: 'HP、AP 两行存疑，未经核对。FMJ 一行可信。',
  ),
  // 发射器五把（VERBA / MAAWS / MGL-40 / RPG-7 / AT4）没有任何一家给出
  // 按弹药类型分的爆头伤害。不要拿 0.70/0.60/0.45/0.35 反推 ——
  // 没有无甲基数，乘什么都是编的。
  //
  // 来源：wardogs.zone 家族 / Goldpip3 armory.json + wardogshandbook.com。
  // 重量：有两家写 0，那是「没采到」漏成了数字，不是 17.25kg 的反对票。
  // 解锁等级 16 另经 bwiki 复核；解锁费 50000 只有两条线且其中一家说没采到，标存疑。
  // 价格 800 只在社区记录里出现过，官方从未公布，标存疑。
  // 顺带修一处旧错：这条以前把「防空导弹」写进了 unlock（解锁条件）字段。
  Weapon(
    name: '9K333 VERBA',
    category: '发射器',
    priceUsd: 800,
    weightKg: 17.25,
    caliber: '72mm 防空导弹',
    track: '支援兵',
    unlock: '支援兵 16 级，另需 \$50000',
    doubtfulFields: {'priceUsd', 'unlock'},
    dataNote: '防空导弹不分弹药类型，没有这张伤害表。',
  ),
  // 来源同上。价格 2600 是商店售价，另一家的 125000 是解锁费串进了价格列。
  // 重量：两家写 0（缺值漏成数字），7kg 由三处吻合，但仍标存疑。
  // 射击模式留空：唯一给了值的那家写的是装填方式（可重复装填发射管），不是开火模式。
  Weapon(
    name: 'MAAWS',
    category: '发射器',
    priceUsd: 2600,
    weightKg: 7,
    caliber: '84mm 反坦克弹',
    track: '支援兵',
    unlock: '支援兵 20 级，另需 \$125000',
    doubtfulFields: {'weightKg'},
    dataNote: '火箭与榴弹按爆炸计伤，不分弹药类型，没有这张表。',
  ),
  // 来源同上。价格 6000 是商店售价，另一家的 200000 是解锁费串进了价格列。
  // 解锁等级 35 另经 bwiki 复核，是本条最硬的一项。
  // 射击模式留空：唯一给了值的那家写的是「6 发发射管」，那是容量不是开火模式。
  Weapon(
    name: 'MGL-40',
    category: '发射器',
    priceUsd: 6000,
    weightKg: 5.3,
    caliber: '40mm 榴弹',
    track: '支援兵',
    unlock: '支援兵 35 级，另需 \$200000',
    doubtfulFields: {'priceUsd', 'weightKg'},
    dataNote: '火箭与榴弹按爆炸计伤，不分弹药类型，没有这张表。',
  ),
  // 来源：bwiki / Goldpip3 armory.json + wardogshandbook.com，两条独立线，
  // 在价格、重量、口径、进度线、解锁上完全一致。
  // 价格 2000 是商店售价，另一家的 30000 是解锁费串进了价格列。
  // 射击模式「单发」只有 bwiki 一家给（另一家给的是装填方式），标存疑。
  Weapon(
    name: 'RPG-7',
    category: '发射器',
    priceUsd: 2000,
    weightKg: 6.3,
    caliber: '93mm',
    fireModes: '单发',
    track: '支援兵',
    unlock: '支援兵 5 级，另需 \$30000',
    doubtfulFields: {'fireModes'},
    dataNote: '火箭与榴弹按爆炸计伤，不分弹药类型，没有这张表。',
  ),
  Weapon(name: 'AT4', category: '发射器'),
  Weapon(name: 'GGX 17', category: '副武器'),
  Weapon(name: 'GGX 18', category: '副武器'),
  Weapon(name: 'JUDGE', category: '副武器'),
  // 来源同 AK74。
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
