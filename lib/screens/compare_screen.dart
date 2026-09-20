import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../theme.dart';
import '../widgets/page_body.dart';

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

  /// 这把枪有没有当前这种弹药的一行。没有就是没有，
  /// 别像以前那样回退成一行全 0 —— 那会把「没查到」画成一条 0 伤害的柱子，
  /// 玩家会当成「这枪打这种弹没用」而换掉它。
  AmmoRow? _rowOf(Weapon w) {
    for (final r in w.damage) {
      if (r.ammo == _ammoNames[_ammo]) return r;
    }
    return null;
  }

  double? _damageOf(Weapon w) => _rowOf(w)?.at(_tier);

  bool _isDoubtful(Weapon w) => _rowOf(w)?.isDoubtful(_tier) ?? false;

  @override
  Widget build(BuildContext context) {
    // 只排当前这一组里真有数值的枪。某一格是横杠的（比如 PKM 的 4 级甲）
    // 在这一组里就不出现，切回有数据的组又会回来。
    final ranked = kWeapons.where((w) => _damageOf(w) != null).toList()
      ..sort((a, b) => _damageOf(b)!.compareTo(_damageOf(a)!));
    final top = ranked.isEmpty ? 1.0 : _damageOf(ranked.first)!;

    return Scaffold(
      appBar: AppBar(title: const Text('伤害对比')),
      body: PageBody(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_ammoNames[_ammo]} 打${_tierNames[_tier]}：'
              '${kWeapons.length} 把枪里有 ${ranked.length} 把收录了数值',
              style: const TextStyle(color: C.textDim, fontSize: 14),
            ),
          ),
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
          // 图例放在柱子上面。以前它在页尾，收录的枪一多就被挤到屏幕外，
          // 玩家只看得见金色问号、看不见那句「存疑」—— 等于没标。
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration:
                          BoxDecoration(color: C.gold, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ranked.any(_isDoubtful)
                        ? '金色 = 本组伤害最高 · 带 ? 的数字存疑，以游戏内实际为准'
                        : '金色 = 本组伤害最高',
                    style: const TextStyle(
                        color: C.textDim, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                '这一组还没有可靠数值。\n'
                '不是 App 坏了 —— 是几家资料在这一格上对不上，'
                '与其给你一个编的数，不如空着。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: C.textDim, fontSize: 14, height: 1.6),
              ),
            ),
          for (final w in ranked)
            _Bar(
              name: w.name,
              category: w.category,
              value: _damageOf(w)!,
              ratio: top <= 0 ? 0 : _damageOf(w)! / top,
              // 金色标的是「这一组里最高」——一个页面上就能核对的事实。
              // 别改回按固定血量判「一枪带走」：玩家血量多少没有任何公开出处，
              // 猜错会让人拿着打不死人的枪去拼。
              best: ranked.isNotEmpty && w.name == ranked.first.name,
              doubtful: _isDoubtful(w),
            ),
          const SizedBox(height: 4),
          const Text(
            '官方没公布过武器数值表，这些数字来自玩家整理的资料站和游戏内图鉴誊抄。'
            '几家对不上的格子一律留横杠，不替你猜。',
            style: TextStyle(color: C.textFaint, fontSize: 13, height: 1.5),
          ),

        ],
      ),
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
  final bool best;
  final bool doubtful;

  const _Bar({
    required this.name,
    required this.category,
    required this.value,
    required this.ratio,
    required this.best,
    required this.doubtful,
  });

  static const _nameStyle =
      TextStyle(color: C.text, fontSize: 16, fontWeight: FontWeight.w600);
  static const _catStyle = TextStyle(color: C.textFaint, fontSize: 14);

  @override
  Widget build(BuildContext context) {
    final color = best ? C.gold : C.textDim;
    final valueText =
        value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    final valueStyle = TextStyle(
      color: color,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (ctx, box) {
            // 名字、分类、数字三样一行放不下就摞起来。
            // 这里是真的量过再决定的，不是按屏幕宽度猜：字号调到无障碍档位时，
            // 光一个「342.41」就能吃掉大半行，名字会被挤成 0 宽 —— 枪名整个看不见。
            final base = DefaultTextStyle.of(ctx).style;
            final scaler = MediaQuery.textScalerOf(ctx);
            double widthOf(String s, TextStyle st) => (TextPainter(
                  text: TextSpan(text: s, style: base.merge(st)),
                  textDirection: Directionality.of(ctx),
                  textScaler: scaler,
                )..layout())
                .width;

            final needed = widthOf(name, _nameStyle) +
                widthOf(category, _catStyle) +
                widthOf(doubtful ? '$valueText ?' : valueText, valueStyle) +
                20; // 两处间距 + 一点余量
            final stacked = needed > box.maxWidth;

            final title = Text(name, style: _nameStyle);
            final cat = Text(category, style: _catStyle);
            final number = Text.rich(
              TextSpan(
                text: valueText,
                children: [
                  if (doubtful)
                    const TextSpan(
                      text: ' ?',
                      style: TextStyle(
                          color: C.gold, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
              style: valueStyle,
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, cat, const SizedBox(height: 2), number],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                cat,
                const SizedBox(width: 12),
                number,
              ],
            );
          }),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: C.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(
                  best ? C.gold : C.border),
            ),
          ),
        ],
      ),
    );
  }
}
