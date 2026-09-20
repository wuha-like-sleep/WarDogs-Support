import 'package:flutter/material.dart';

import '../data/progression.dart';
import '../theme.dart';
import '../widgets/page_body.dart';

/// 一条进度线的等级解锁表
class LadderScreen extends StatelessWidget {
  final Ladder ladder;

  const LadderScreen({super.key, required this.ladder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ladder.track)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          children: [
            Text(
              '${ladder.unlocks.length} 项，其中 ${ladder.weaponCount} 把枪',
              style: const TextStyle(color: C.textDim, fontSize: 14),
            ),
            if (ladder.warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: C.goldFaint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: C.gold),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(ladder.warning!,
                          style: const TextStyle(
                              color: C.gold, fontSize: 14, height: 1.6)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            for (final u in ladder.unlocks) _Row(u),
            const SizedBox(height: 18),
            const Text(
              '解锁费是一次性的。付过之后，每局再按枪的单价购买。',
              style: TextStyle(color: C.textFaint, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Unlock u;

  const _Row(this.u);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: u.isWeapon ? C.gold.withValues(alpha: 0.45) : C.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 等级徽章
                Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: u.isWeapon ? C.goldFaint : C.surfaceHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${u.level}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: u.isWeapon ? C.gold : C.textDim,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    u.name,
                    style: TextStyle(
                      color: u.isWeapon ? C.text : C.textDim,
                      fontSize: 15,
                      fontWeight:
                          u.isWeapon ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  // 没有解锁费不等于免费 —— 是「到了等级直接给」，
                  // 写「免费」会让人以为别的要另外买两次
                  u.cost == null ? '到级即得' : '\$${_money(u.cost!)}',
                  style: TextStyle(
                    color: u.cost == null ? C.textFaint : C.textDim,
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (u.note != null) ...[
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.only(left: 49),
                child: Text(u.note!,
                    style: const TextStyle(color: C.gold, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _money(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
