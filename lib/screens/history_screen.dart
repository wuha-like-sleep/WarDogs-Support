import 'package:flutter/material.dart';
import '../data/store.dart';
import '../theme.dart';

/// 射击记录。反复试炮位的时候靠它回看和还原。
class HistoryScreen extends StatefulWidget {
  final List<ShotRecord> shots;

  const HistoryScreen({super.key, required this.shots});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<ShotRecord> _shots = List.of(widget.shots);

  Future<void> _delete(ShotRecord r) async {
    final list = _shots.where((e) => e.savedAt != r.savedAt).toList();
    await Store.saveShots(list);
    if (!mounted) return;
    setState(() => _shots = list);
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: const Text('清空记录', style: TextStyle(color: C.text, fontSize: 18)),
        content: const Text('这局打过的都会没掉，删了找不回来。',
            style: TextStyle(color: C.textDim, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('算了', style: TextStyle(color: C.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空',
                style: TextStyle(color: C.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Store.saveShots(const []);
    if (!mounted) return;
    setState(() => _shots = const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('射击记录'),
        actions: [
          if (_shots.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('清空',
                  style: TextStyle(color: C.textDim, fontSize: 15)),
            ),
        ],
      ),
      body: _shots.isEmpty
          ? const Center(
              child: Text('还没有记录\n复制诸元时会自动记一发',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.textFaint, fontSize: 16, height: 1.8)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              itemCount: _shots.length,
              itemBuilder: (_, i) => _ShotTile(
                shot: _shots[i],
                onRestore: () => Navigator.pop(context, _shots[i]),
                onDelete: () => _delete(_shots[i]),
              ),
            ),
    );
  }
}

class _ShotTile extends StatelessWidget {
  final ShotRecord shot;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ShotTile({
    required this.shot,
    required this.onRestore,
    required this.onDelete,
  });

  String get _time {
    final d = DateTime.fromMillisecondsSinceEpoch(shot.savedAt);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: C.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onRestore,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${shot.rangeM}',
                            style: const TextStyle(
                              color: C.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text('米',
                              style: TextStyle(color: C.textDim, fontSize: 14)),
                          const SizedBox(width: 12),
                          Text(
                            shot.bearing,
                            style: const TextStyle(
                              color: C.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text('炮位 ${shot.gunText}',
                          style: const TextStyle(color: C.textDim, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('目标 ${shot.tgtText}',
                          style: const TextStyle(color: C.textDim, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: C.textFaint),
                      onPressed: onDelete,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(_time,
                          style: const TextStyle(
                              color: C.textFaint, fontSize: 13)),
                    ),
                    if (shot.hasOffset)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: C.goldFaint,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('已矫正',
                              style: TextStyle(color: C.gold, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
