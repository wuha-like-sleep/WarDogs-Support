import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../theme.dart';
import '../widgets/page_body.dart';
import 'compare_screen.dart';

class LoadoutScreen extends StatefulWidget {
  const LoadoutScreen({super.key});

  @override
  State<LoadoutScreen> createState() => _LoadoutScreenState();
}

class _LoadoutScreenState extends State<LoadoutScreen> {
  String _query = '';
  String? _category;

  List<Weapon> get _filtered {
    final q = _query.trim().toLowerCase();
    return kWeapons.where((w) {
      if (_category != null && w.category != _category) return false;
      if (q.isEmpty) return true;
      return w.name.toLowerCase().contains(q) ||
          w.category.contains(q) ||
          (w.track ?? '').contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('配装'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompareScreen()),
            ),
            child: const Text('对比',
                style: TextStyle(
                    color: C.gold, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: PageBody(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: C.text, fontSize: 16),
              decoration: InputDecoration(
                hintText: '搜枪名，比如 AK、MP5',
                hintStyle: const TextStyle(color: C.textFaint),
                prefixIcon: const Icon(Icons.search, color: C.textFaint, size: 20),
                filled: true,
                fillColor: C.field,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: C.gold),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _CatChip(
                  label: '全部',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in kWeaponCategories)
                  _CatChip(
                    label: c,
                    selected: _category == c,
                    onTap: () => setState(
                        () => _category = _category == c ? null : c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('没有匹配的枪',
                        style: TextStyle(color: C.textFaint, fontSize: 15)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    children: [
                      for (final cat in kWeaponCategories)
                        if (list.any((w) => w.category == cat)) ...[
                          _CatHeader(
                            cat,
                            count: list.where((w) => w.category == cat).length,
                          ),
                          for (final w in list.where((w) => w.category == cat))
                            _WeaponTile(w),
                        ],
                    ],
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 分类标题：金色竖条 + 数量，让长列表有节奏
class _CatHeader extends StatelessWidget {
  final String title;
  final int count;

  const _CatHeader(this.title, {required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 9),
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

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? C.goldFaint : C.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: BorderSide(color: selected ? C.gold : C.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? C.gold : C.textDim,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeaponTile extends StatelessWidget {
  final Weapon w;

  const _WeaponTile(this.w);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: C.surface,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: C.bg,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            builder: (_) => _WeaponSheet(w),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name,
                          style: const TextStyle(
                              color: C.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        w.track ?? w.category,
                        style: const TextStyle(color: C.textDim, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (w.headshotFmj != null) ...[
                  Text(
                    w.headshotFmj!.toStringAsFixed(0),
                    style: const TextStyle(
                      color: C.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('爆头',
                        style: TextStyle(color: C.textFaint, fontSize: 12)),
                  ),
                ],
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: C.textFaint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeaponSheet extends StatelessWidget {
  final Weapon w;

  const _WeaponSheet(this.w);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(w.name,
              style: const TextStyle(
                  color: C.text, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(w.category,
              style: const TextStyle(color: C.gold, fontSize: 14)),
          const SizedBox(height: 18),
          // 没有数据的字段显示横杠，整块不消失 —— 免得看着像功能坏了
          _Row('价格', w.priceUsd == null ? null : '\$${w.priceUsd}',
              doubtful: w.isFieldDoubtful('priceUsd')),
          _Row('重量', w.weightKg == null ? null : '${w.weightKg} kg',
              doubtful: w.isFieldDoubtful('weightKg')),
          _Row('口径', w.caliber, doubtful: w.isFieldDoubtful('caliber')),
          _Row('射击模式', w.fireModes,
              doubtful: w.isFieldDoubtful('fireModes')),
          _Row('进度线', w.track, doubtful: w.isFieldDoubtful('track')),
          _Row('解锁', w.unlock, doubtful: w.isFieldDoubtful('unlock')),
          if (w.doubtfulFields.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              '带 ? 的字段：几家资料对不上，或者只有单一来源。以游戏内实际为准。',
              style: TextStyle(color: C.textDim, fontSize: 14, height: 1.5),
            ),
          ],
          const SizedBox(height: 22),
          const Text('爆头伤害 / 护甲等级',
              style: TextStyle(
                  color: C.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          // 三行固定画满，没查到的格子显示横杠。
          // 空着不能渲染成 0 —— 那等于告诉玩家这枪打上去不掉血。
          _DamageTable(w.damageRows),
          if (w.dataNote != null) ...[
            const SizedBox(height: 10),
            Text(
              w.dataNote!,
              style: const TextStyle(
                  color: C.textDim, fontSize: 14, height: 1.5),
            ),
          ],
          if (w.attachments.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text('可装配件',
                style: TextStyle(
                    color: C.text, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final e in w.attachments.entries) _Row(e.key, e.value),
          ],

        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;

  /// 值存疑时在后面缀一个金色问号。
  /// 值本来就是横杠的字段不要标 —— 横杠已经说明「没有」，再加问号只会更糊涂。
  final bool doubtful;

  const _Row(this.label, this.value, {this.doubtful = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label,
                style: const TextStyle(color: C.textDim, fontSize: 14)),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: value ?? '—',
                children: [
                  if (doubtful && value != null)
                    const TextSpan(
                      text: ' ?',
                      style: TextStyle(
                          color: C.gold, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
              style: TextStyle(
                color: value == null ? C.textFaint : C.text,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DamageTable extends StatelessWidget {
  final List<AmmoRow> rows;

  const _DamageTable(this.rows);

  @override
  Widget build(BuildContext context) {
    const heads = ['弹药', '无甲', '1级', '2级', '3级', '4级'];
    TextStyle head() =>
        const TextStyle(color: C.textDim, fontSize: 13, fontWeight: FontWeight.w600);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Table(
          // 列宽跟着内容走，别写死。以前是固定 58，而「122.21」这种六位数
          // 要 78 —— 数字会画到隔壁格子上去，调大字号只会更糟。
          // 整张表外面套着横向滚动，列宽撑开没有关系。
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              children: [
                for (final h in heads)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 16, 6),
                    child: Text(h, style: head()),
                  ),
              ],
            ),
            for (final r in rows)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 7, 16, 7),
                    child: Text(r.ammo,
                        style: const TextStyle(
                            color: C.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  for (int tier = 0; tier < 5; tier++)
                    Builder(builder: (_) {
                      // 没查到就是横杠。千万别落回 0 —— 这张表是拿来
                      // 判「打不打得穿」的，一个假的 0 会让人换枪。
                      final v = r.at(tier);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 7, 16, 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v == null
                                  ? '—'
                                  : v.toStringAsFixed(
                                      v == v.roundToDouble() ? 0 : 2),
                              style: TextStyle(
                                color: v == null ? C.textFaint : C.text,
                                fontSize: 13,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            if (v != null && r.isDoubtful(tier))
                              const Padding(
                                padding: EdgeInsets.only(left: 3),
                                child: Text('?',
                                    style: TextStyle(
                                        color: C.gold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
