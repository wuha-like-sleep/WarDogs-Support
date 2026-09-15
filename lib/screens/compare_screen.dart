import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../theme.dart';

/// 伤害对比：选弹药 + 选护甲等级，直接看哪把枪打得动。
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  int _ammo = 0; // 0=FMJ 1=HP 2=AP
  int _tier = 0; // 0=无甲 1..4=各级护甲

  static const _ammoNames = ['FMJ', 'HP', 'AP'];
  static const _tierNames = ['无甲', '1级', '2级', '3级', '4级'];

  double _damageOf(Weapon w) {
    final row = w.damage.firstWhere(
      (r) => r.ammo == _ammoNames[_ammo],
      orElse: () => const AmmoRow('', 0, 0, 0, 0, 0),
    );
    return switch (_tier) {
      0 => row.noArmor,
      1 => row.t1,
      2 => row.t2,
      3 => row.t3,
      _ => row.t4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ranked = kWeapons.where((w) => w.damage.isNotEmpty).toList()
      ..sort((a, b) => _damageOf(b).compareTo(_damageOf(a)));
    final top = ranked.isEmpty ? 1.0 : _damageOf(ranked.first);

    return Scaffold(
      appBar: AppBar(title: const Text('伤害对比')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        children: [
          _Seg(
            labels: _ammoNames,
            index: _ammo,
            onChanged: (i) => setState(() => _ammo = i),
          ),
          const SizedBox(height: 10),
          _Seg(
            labels: _tierNames,
            index: _tier,
            onChanged: (i) => setState(() => _tier = i),
          ),
          const SizedBox(height: 18),
          for (final w in ranked)
            _Bar(
              name: w.name,
              category: w.category,
              value: _damageOf(w),
              ratio: top <= 0 ? 0 : _damageOf(w) / top,
              // 一枪爆头带走
              lethal: _damageOf(w) >= 100,
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: C.gold, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('金色 = 爆头一枪带走（伤害 ≥ 100）',
                      style: TextStyle(color: C.textDim, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('只列出已有数值的枪，数据会陆续补齐。',
              style: TextStyle(color: C.textFaint, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const _Seg({
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
                  height: 36,
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

class _Bar extends StatelessWidget {
  final String name;
  final String category;
  final double value;
  final double ratio;
  final bool lethal;

  const _Bar({
    required this.name,
    required this.category,
    required this.value,
    required this.ratio,
    required this.lethal,
  });

  @override
  Widget build(BuildContext context) {
    final color = lethal ? C.gold : C.textDim;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        color: C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              Text(category,
                  style: const TextStyle(color: C.textFaint, fontSize: 14)),
              const SizedBox(width: 12),
              Text(
                value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: C.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(
                  lethal ? C.gold : C.border),
            ),
          ),
        ],
      ),
    );
  }
}
