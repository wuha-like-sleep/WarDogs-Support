import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../data/progression.dart';
import '../theme.dart';
import '../widgets/page_body.dart';
import 'ladder_screen.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('后勤')),
      body: Column(
        children: [
          PageBody(
            child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _Segmented(
              labels: const ['载具', '进度线', '机制'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          ),
          Expanded(
            child: PageBody(
              child: switch (_tab) {
                0 => const _Vehicles(),
                1 => const _Tracks(),
                _ => const _Systems(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: i == index ? C.goldFaint : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: i == index ? C.gold : C.textDim,
                        fontSize: 15,
                        fontWeight:
                            i == index ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Vehicles extends StatelessWidget {
  const _Vehicles();

  static const _icons = {
    '轻型载具': Icons.directions_car,
    '重型载具': Icons.shield,
    '直升机': Icons.flight,
    '固定武器': Icons.gps_fixed,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        for (final cat in kVehicleCategories) ...[
          _SectionHeader(
            cat,
            icon: _icons[cat] ?? Icons.category,
            count: kVehicles.where((v) => v.category == cat).length,
          ),
          for (final v in kVehicles.where((v) => v.category == cat))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(_icons[cat] ?? Icons.category,
                        size: 18, color: C.textFaint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(v.name,
                          style: const TextStyle(
                              color: C.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ),
                    if (v.note != null)
                      Flexible(
                        child: Text(
                          v.note!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: C.textDim, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// 分类标题：金色竖条 + 图标 + 数量，让长列表有节奏感
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _SectionHeader(this.title, {required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: C.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Icon(icon, size: 16, color: C.gold),
          const SizedBox(width: 7),
          Text(title,
              style: const TextStyle(
                  color: C.gold, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('$count',
              style: const TextStyle(color: C.textFaint, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Tracks extends StatelessWidget {
  const _Tracks();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: C.border.withValues(alpha: 0.5)),
          ),
          child: const Text(
            '没有选职业这一步 —— 你买什么装备，你就是什么角色。',
            style: TextStyle(color: C.textDim, fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 14),
        for (final t in kTracks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TrackCard(
              track: t,
              ladder: _ladderFor(t.name),
            ),
          ),
        // 副武器和护甲不挂在六条兵种线上，走通用账号等级
        if (_ladderFor('WARDOGS 等级') != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LadderEntry(ladder: _ladderFor('WARDOGS 等级')!),
          ),
        const SizedBox(height: 6),
        _NoLadderNote(),
      ],
    );
  }

  static Ladder? _ladderFor(String name) {
    for (final l in kLadders) {
      if (l.track == name) return l;
    }
    return null;
  }
}

/// 不挂在任何梯子上的枪，单独说一句，免得玩家在表里翻半天
class _NoLadderNote extends StatelessWidget {
  const _NoLadderNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: C.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('不用解锁的枪',
              style: TextStyle(
                  color: C.gold, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final e in kNoLadderWeapons.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: Text(e.key,
                        style: const TextStyle(color: C.text, fontSize: 14)),
                  ),
                  Expanded(
                    child: Text(e.value,
                        style:
                            const TextStyle(color: C.textDim, fontSize: 14)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 通用等级梯子的入口
class _LadderEntry extends StatelessWidget {
  final Ladder ladder;

  const _LadderEntry({required this.ladder});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => LadderScreen(ladder: ladder))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: C.goldFaint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.military_tech, size: 19, color: C.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ladder.track,
                        style: const TextStyle(
                            color: C.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('副武器和护甲走这条，共 ${ladder.unlocks.length} 项',
                        style: const TextStyle(color: C.textDim, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: C.textFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 兵种卡片：点开看这条线的完整解锁表
class _TrackCard extends StatelessWidget {
  final Track track;
  final Ladder? ladder;

  const _TrackCard({required this.track, this.ladder});

  static const _icons = {
    '突击兵': Icons.bolt,
    '医护兵': Icons.medical_services,
    '侦察兵': Icons.visibility,
    '支援兵': Icons.inventory_2,
    '驾驶员': Icons.directions_car,
    '飞行员': Icons.flight,
  };

  @override
  Widget build(BuildContext context) {
    final l = ladder;
    return Material(
      color: C.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: l == null
            ? null
            : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => LadderScreen(ladder: l))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: C.goldFaint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_icons[track.name] ?? Icons.person,
                        size: 19, color: C.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(track.name,
                        style: const TextStyle(
                            color: C.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (l != null)
                    const Icon(Icons.chevron_right,
                        color: C.textFaint, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              _Line('怎么涨', track.howToLevel),
              const SizedBox(height: 6),
              if (l != null)
                _Line('解锁表',
                    '${l.unlocks.length} 项，${l.weaponCount} 把枪 —— 点开看')
              else
                _Line('解锁什么', track.unlocks),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label, value;

  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Text(label,
              style: const TextStyle(color: C.textFaint, fontSize: 14)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: C.textDim, fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }
}

class _Systems extends StatelessWidget {
  const _Systems();

  static const _icons = {
    '基本规则': Icons.flag,
    '钱跨局保留': Icons.payments,
    'FOB 前进基地': Icons.home_work,
    '钻井平台': Icons.water_drop,
    '建造与破坏': Icons.construction,
    '弹药怎么选': Icons.adjust,
    '迫击炮怎么打': Icons.my_location,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        for (final s in kSystems)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_icons[s.title] ?? Icons.info_outline,
                          size: 18, color: C.gold),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(s.title,
                            style: const TextStyle(
                                color: C.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(s.body,
                      style: const TextStyle(
                          color: C.textDim, fontSize: 15, height: 1.6)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
