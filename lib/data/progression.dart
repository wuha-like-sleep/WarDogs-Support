/// 等级解锁表。
///
/// 数据取自 wardogshub.gg/progression 的 163 条全表，
/// 与 B 站 wiki 的六条兵种页 + WARDOGS 等级页交叉比对。
/// 对不上的地方在 [Unlock.note] 里标出来，没有取平均、没有猜。
///
/// **驾驶员那条线两源整体打架**（见 kDriverConflict），标了警告。
/// 飞行员线两源完全一致；突击、医护、侦察、支援四线的枪械部分完全一致。
library;

/// 一条解锁记录
class Unlock {
  /// 需要的等级
  final int level;

  /// 解锁什么
  final String name;

  /// 一次性解锁费（美元）。null 表示只要等级、不花钱。
  ///
  /// 注意这**不是**局内购买价。游戏里有两个价：到了等级先付一次性解锁费，
  /// 之后每条命再按单价买。Weapon.priceUsd 存的是局内单价，两者别混。
  final int? cost;

  /// 是不是枪
  final bool isWeapon;

  /// 来源之间对不上的地方，写清楚
  final String? note;

  const Unlock(
    this.level,
    this.name, {
    this.cost,
    this.isWeapon = false,
    this.note,
  });
}

class Ladder {
  final String track;
  final List<Unlock> unlocks;

  /// 整条线都不可靠时的警告
  final String? warning;

  const Ladder(this.track, this.unlocks, {this.warning});

  int get weaponCount => unlocks.where((u) => u.isWeapon).length;
}

const kDriverConflict =
    '这条线两个来源整体对不上（同一辆车的等级差 2–10 级，且一方有 L2A6、'
    '另一方没有）。下面按其中一个来源列出，以游戏内实际为准。';

const kLadders = <Ladder>[
  Ladder('突击兵', [
    Unlock(2, '六角制退器', cost: 5000),
    Unlock(3, 'AK74', cost: 10000, isWeapon: true),
    Unlock(5, 'TOPCOMP 制退器', cost: 7500),
    Unlock(10, 'GALIL 35 发弹匣'),
    Unlock(10, 'GALIL', cost: 35000, isWeapon: true),
    Unlock(11, '橡胶人体工学前握把', cost: 7500),
    Unlock(12, 'TRICON 1.5X 紧凑棱镜镜', cost: 10000),
    Unlock(15, 'GALIL 50 发弹匣', cost: 25000),
    Unlock(16, '鸟笼消焰器', cost: 15000),
    Unlock(17, 'CQ-2X 棱镜战斗镜', cost: 15000),
    Unlock(20, 'M4', cost: 100000, isWeapon: true),
    Unlock(24, '三叉消焰器', cost: 20000),
    Unlock(29, 'RC-556 消音器', cost: 30000),
    Unlock(33, 'OKP 7 反射镜', cost: 30000),
    Unlock(35, 'FAL & BMR-308 20 发弹匣'),
    Unlock(35, 'FAL', cost: 200000, isWeapon: true),
    Unlock(38, 'CQR 战术前导轨握把', cost: 25000),
    Unlock(43, '4X 战斗棱镜镜带反射', cost: 35000),
    Unlock(45, '三腔制退器', cost: 45000),
    Unlock(48, 'SHIFT 前握把', cost: 30000),
    Unlock(50, 'FAL 30 发弹匣', cost: 50000),
  ]),
  Ladder('医护兵', [
    Unlock(1, '双口制退器', cost: 7500),
    Unlock(2, '野战复苏仪', cost: 10000),
    Unlock(3, 'AMP-9 15 发弹匣', cost: 7500),
    Unlock(4, 'PP-19 30 发弹匣'),
    Unlock(4, 'PP-19 VITYAZ', cost: 25000, isWeapon: true),
    Unlock(5, 'M18 烟雾弹（白）', cost: 7500),
    Unlock(6, '四准星反射镜', cost: 10000),
    Unlock(7, 'PP-19 10 发弹匣', cost: 7500),
    Unlock(9, '个人急救包', cost: 25000),
    Unlock(11, '除颤器', cost: 50000),
    Unlock(12, 'AMP-9 战术消焰器', cost: 10000),
    Unlock(13, 'BALLISTA 制退器', cost: 15000),
    Unlock(14, '肾上腺素注射笔', cost: 25000),
    Unlock(15, 'MP5 20 发弹匣'),
    Unlock(15, 'MP5', cost: 75000, isWeapon: true),
    Unlock(16, 'RVG 垂直前握把', cost: 10000),
    Unlock(18, 'QD-5 消音器', cost: 17500),
    Unlock(20, 'AMP-9 50 发弹匣', cost: 15000),
    Unlock(21, 'M18 烟雾弹（黑）', cost: 15000),
    Unlock(22, 'PP-19 消焰器', cost: 20000),
    Unlock(24, '医疗包', cost: 75000),
    Unlock(25, 'MP5 30 发弹匣', cost: 25000),
    Unlock(26, 'ECLIPSE 消焰器', cost: 22500),
    Unlock(28, 'VEKTOR FRENIX-X 微型反射镜', cost: 15000),
    Unlock(29, 'PP-19 50 发弹匣', cost: 50000, note: '另一来源记 33 级'),
    Unlock(30, 'AMP-9 9X19 消音器', cost: 25000),
    Unlock(35, 'SUPER-45 13 发弹匣'),
    Unlock(35, 'SUPER-45', cost: 150000, isWeapon: true),
    Unlock(36, 'GHOST LITE 枪口制退器', cost: 30000),
    Unlock(40, 'SUPER-45 消焰器', cost: 40000),
    Unlock(43, 'PP-19-01 9X19 消音器', cost: 45000),
    Unlock(45, 'MP5 50 发弹匣', cost: 75000),
    Unlock(50, 'SUPER-45 40 发鼓弹匣', cost: 50000),
  ]),
  Ladder('侦察兵', [
    Unlock(2, '单筒望远镜', cost: 7500),
    Unlock(3, 'STRELIX 消音器', cost: 7500),
    Unlock(5, 'SKS', cost: 25000, isWeapon: true),
    Unlock(6, 'DTK-1 制退器', cost: 7500),
    Unlock(7, 'SKS 两脚架', cost: 10000),
    Unlock(8, '测距仪', cost: 15000),
    Unlock(10, '莫辛步枪', cost: 50000, isWeapon: true),
    Unlock(11, '3X-6X LPVO', cost: 15000),
    Unlock(12, 'SVD 5 发弹匣'),
    Unlock(12, 'SVD', cost: 50000, isWeapon: true),
    Unlock(13, 'SVD 7.62X54R 制退器', cost: 10000),
    Unlock(14, '两脚架', cost: 10000),
    Unlock(16, 'SVD 10 发弹匣', cost: 25000),
    Unlock(17, '箭矢'),
    Unlock(17, '复合弓', cost: 75000, isWeapon: true),
    Unlock(19, 'SV98 10 发弹匣'),
    Unlock(19, 'SV98', cost: 100000, isWeapon: true),
    Unlock(20, 'SRVV 制退器', cost: 17500),
    Unlock(21, 'SV98 两脚架', cost: 30000),
    Unlock(22, '阔剑地雷', cost: 50000),
    Unlock(23, 'CONSTRICTOR 制退器', cost: 20000),
    Unlock(24, '吉利服装甲', cost: 80000),
    Unlock(24, '吉利服头盔', cost: 60000),
    Unlock(25, 'MK22 5 发弹匣'),
    Unlock(25, 'MK22', cost: 150000, isWeapon: true),
    Unlock(28, 'SLICKTAP 制退器', cost: 22500),
    Unlock(30, 'BMR-308', cost: 125000, isWeapon: true),
    Unlock(31, 'BMR-308 消焰器', cost: 25000),
    Unlock(32, '红外测距仪', cost: 50000),
    Unlock(33, 'BMR-308 消音器', cost: 27500),
    Unlock(34, '6X 射手镜带反射', cost: 35000),
    Unlock(35, 'AMR 50', cost: 200000, isWeapon: true),
    Unlock(36, '三口制退器', cost: 25000),
    Unlock(37, '.50 重型消音器', cost: 27500),
    Unlock(40, '.308 流通式消音器', cost: 30000),
    Unlock(43, 'FRONTIER 2.5X-10X 精确镜', cost: 95000),
    Unlock(46, 'PRO 可倾两脚架', cost: 50000),
    Unlock(48, 'AX50 .50 枪口制退器', cost: 35000),
    Unlock(50, 'AMR 50 10 发弹匣', cost: 50000),
  ]),
  Ladder('支援兵', [
    Unlock(1, '轻型钻机', cost: 10000),
    Unlock(2, 'C4 炸药'),
    Unlock(2, '遥控起爆器', cost: 15000),
    Unlock(3, '中型锤', cost: 25000),
    Unlock(5, 'RPG-7', cost: 30000, isWeapon: true),
    Unlock(8, '大型锤', cost: 75000, note: '另一来源记 7 级'),
    Unlock(10, 'M500', cost: 50000, isWeapon: true),
    Unlock(11, 'M500 SABRE 制退器', cost: 17500),
    Unlock(12, 'PGO-7 瞄具', cost: 10000),
    Unlock(14, '改良阻塞圈', cost: 7500),
    Unlock(15, 'M249 100 发布袋弹匣'),
    Unlock(15, 'M249 SAW', cost: 100000, isWeapon: true),
    Unlock(16, '9K333 VERBA', isWeapon: true, note: '仅单一来源，解锁费未知'),
    Unlock(17, 'TREAD 制退器', cost: 10000),
    Unlock(18, 'M249 两脚架', cost: 15000),
    Unlock(19, '全阻塞圈', cost: 30000),
    Unlock(20, 'MAAWS', cost: 125000, isWeapon: true),
    Unlock(25, '反坦克地雷', cost: 75000),
    Unlock(26, '开槽消焰器', cost: 20000),
    Unlock(28, '重型钻机', cost: 25000),
    Unlock(30, 'PKM 100 发弹箱'),
    Unlock(30, 'PKM', cost: 150000, isWeapon: true),
    Unlock(33, 'PKM 两脚架', cost: 35000),
    Unlock(35, 'MGL-40', cost: 200000, isWeapon: true),
    Unlock(45, 'ORPHEUS MAX 制退器', cost: 40000),
  ]),
  Ladder('驾驶员', [
    Unlock(3, 'URAL', cost: 35000),
    Unlock(6, 'KODIAK（M249）', cost: 50000),
    Unlock(8, '沙滩车', cost: 25000),
    Unlock(10, 'KODIAK（皮卡）', cost: 35000),
    Unlock(15, '悍马', cost: 25000),
    Unlock(18, 'URAL DEFENDER', cost: 75000),
    Unlock(25, '悍马（M249）', cost: 125000),
    Unlock(25, 'URAL DEFENDER（M249）', cost: 125000),
    Unlock(30, '悍马（机枪塔）', cost: 150000),
    Unlock(35, 'L2A6', cost: 500000, note: '另一来源没有这一条'),
  ], warning: kDriverConflict),
  Ladder('飞行员', [
    Unlock(4, 'AH-6M（机枪）', cost: 50000),
    Unlock(10, 'Z20 LAKOTA', cost: 35000),
    Unlock(20, 'AH-6R（火箭）', cost: 200000),
    Unlock(25, 'Z20 LAKOTA（机枪）', cost: 75000),
    Unlock(35, 'HAVOC', cost: 500000),
  ]),
  Ladder('WARDOGS 等级', [
    Unlock(1, 'GGX 17', cost: 5000, isWeapon: true, note: '另一来源记 \$7,500'),
    Unlock(3, '1 级护甲 + 头盔', cost: 17500),
    Unlock(4, '紧凑型 T-2 红点', cost: 5000),
    Unlock(6, '9mm 肉伤弹（HP）', cost: 5000),
    Unlock(10, '5.56mm 肉伤弹（HP）', cost: 5000),
    Unlock(11, '7.62mm 肉伤弹（HP）', cost: 5000),
    Unlock(12, '野战背包', cost: 20000),
    Unlock(14, '中号战术背心', cost: 10000),
    Unlock(18, 'JUDGE', cost: 15000, isWeapon: true),
    Unlock(20, '干员背包', cost: 25000),
    Unlock(21, 'KOBRA 反射镜', cost: 7500),
    Unlock(23, 'GGX 33 发弹匣', cost: 10000),
    Unlock(30, '2 级护甲', cost: 50000),
    Unlock(30, '2 级头盔', cost: 37500),
    Unlock(31, '3X 战术棱镜镜', cost: 15000),
    Unlock(32, '突击背包', cost: 50000),
    Unlock(35, '运动伞', cost: 25000),
    Unlock(38, '迷你倾斜前握把', cost: 12500),
    Unlock(40, 'M1911 7 发弹匣'),
    Unlock(40, 'M1911', cost: 25000, isWeapon: true),
    Unlock(43, '.45ACP 手枪补偿器', cost: 15000),
    Unlock(45, '高容量电池', cost: 50000),
    Unlock(50, '大号战术背心', cost: 25000),
    Unlock(53, 'M1911 10 发弹匣', cost: 10000),
    Unlock(55, 'RUCK 背包', cost: 100000),
    Unlock(60, '3 级护甲', cost: 100000),
    Unlock(60, '3 级头盔', cost: 75000),
    Unlock(70, 'GGX 18', cost: 50000, isWeapon: true),
    Unlock(73, '机枪手背包 + 挂载', cost: 125000),
    Unlock(80, 'GGX 50 发鼓弹匣', cost: 50000),
    Unlock(85, 'DEAGLE', cost: 75000, isWeapon: true, note: '另一来源记 90 级'),
    Unlock(90, 'DEAGLE 7 发弹匣'),
    Unlock(90, 'SPH-2', cost: 500000),
    Unlock(100, '4 级护甲', cost: 200000),
    Unlock(100, '4 级头盔', cost: 150000),
    Unlock(150, '军械背包 + 2 挂载槽', cost: 175000),
  ]),
];

/// 不在任何解锁梯子上的枪 —— 免费或初始就有
const kNoLadderWeapons = <String, String>{
  'Bushmaster M17S': 'Lonestar 阵营免费武器',
  'A-91': 'Valkyra 阵营免费武器',
  'KH-2002': 'Manticore 阵营免费武器',
  'T-21': '突击兵初始武器',
  'AMP-9': '医护兵初始武器',
  'TD 侦查步枪': '侦察兵初始武器',
  'MP43': '无等级门槛，局内直接买',
};
