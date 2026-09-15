import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ballistics.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/keypad.dart';
import 'history_screen.dart';

/// 四个输入框的顺序，「下一项」按这个顺序走
enum Field { gunX, gunY, tgtX, tgtY }

class MortarScreen extends StatefulWidget {
  const MortarScreen({super.key});

  @override
  State<MortarScreen> createState() => _MortarScreenState();
}

class _MortarScreenState extends State<MortarScreen> {
  final _text = <Field, String>{
    Field.gunX: '',
    Field.gunY: '',
    Field.tgtX: '',
    Field.tgtY: '',
  };

  Field? _focus = Field.gunX;
  double _offsetX = 0, _offsetY = 0;
  int _step = 25;
  List<SavedCoord> _saved = const [];
  List<ShotRecord> _shots = const [];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final step = await Store.loadStep();
    final coords = await Store.loadCoords();
    final shots = await Store.loadShots();
    final (gx, gy) = await Store.loadLastGun();
    if (!mounted) return;
    setState(() {
      _step = step;
      _saved = coords;
      _shots = shots;
      _text[Field.gunX] = gx;
      _text[Field.gunY] = gy;
      // 炮位一局之内不动。上次记着就直接跳到敌人坐标，省掉两次点击
      if (gx.isNotEmpty && gy.isNotEmpty) _focus = Field.tgtX;
    });
  }

  double? _val(Field f) => double.tryParse(_text[f]!);

  /// 四个框都填了才有诸元；缺一个就显示横杠，而不是把整块藏起来
  FireSolution? get _solution {
    final gx = _val(Field.gunX), gy = _val(Field.gunY);
    final tx = _val(Field.tgtX), ty = _val(Field.tgtY);
    if (gx == null || gy == null || tx == null || ty == null) return null;
    return solve(
      gunX: gx,
      gunY: gy,
      targetX: tx + _offsetX,
      targetY: ty + _offsetY,
    );
  }

  /// 矫正量是针对「当前这组炮位 + 目标」试出来的。
  /// 任何一个坐标变了，这组矫正就不再成立 —— 留着它会让新目标的诸元
  /// 静默偏掉，界面还一切正常。这是这个 App 最致命的一类错误。
  /// 必须在 setState 里调用；返回是否真的清掉了东西。
  bool _dropStaleOffset() {
    if (_offsetX == 0 && _offsetY == 0) return false;
    _offsetX = 0;
    _offsetY = 0;
    return true;
  }

  void _onKey(KeypadKey k) {
    HapticFeedback.selectionClick();
    final f = _focus;
    switch (k.kind) {
      case KeyKind.hide:
        setState(() => _focus = null);
        return;
      case KeyKind.next:
        if (f == null) return;
        final next = Field.values[(f.index + 1) % Field.values.length];
        setState(() => _focus = next);
        return;
      default:
        break;
    }
    if (f == null) return;

    var dropped = false;
    setState(() {
      final before = _text[f]!;
      var s = _text[f]!;
      switch (k.kind) {
        case KeyKind.digit:
          s += k.label;
        case KeyKind.dot:
          if (!s.contains('.')) s = s.isEmpty ? '0.' : '$s.';
        case KeyKind.minus:
          s = s.startsWith('-') ? s.substring(1) : '-$s';
        case KeyKind.clear:
          s = '';
        case KeyKind.backspace:
          if (s.isNotEmpty) s = s.substring(0, s.length - 1);
        default:
          break;
      }
      _text[f] = s;
      if (s != before) dropped = _dropStaleOffset();
    });

    if (dropped) _toast('坐标变了，弹着点矫正已清零');

    if (f == Field.gunX || f == Field.gunY) {
      Store.saveLastGun(_text[Field.gunX]!, _text[Field.gunY]!);
    }
  }

  void _nudge(Nudge d) {
    HapticFeedback.selectionClick();
    setState(() {
      final o = applyNudge(
        offsetX: _offsetX,
        offsetY: _offsetY,
        direction: d,
        stepMeters: _step.toDouble(),
      );
      _offsetX = o.dx;
      _offsetY = o.dy;
    });
  }

  void _setStep(int m) {
    final clamped = m.clamp(1, 500);
    setState(() => _step = clamped);
    Store.saveStep(clamped);
  }

  Future<void> _remember(bool gun) async {
    final x = _val(gun ? Field.gunX : Field.tgtX);
    final y = _val(gun ? Field.gunY : Field.tgtY);
    if (x == null || y == null) {
      _toast('这两个格子填完才能记');
      return;
    }
    final entry = SavedCoord(
      label: gun ? '炮位' : '目标',
      x: x,
      y: y,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final list = [entry, ..._saved];
    // 只留最近 20 条，不然列表会越滚越长
    final trimmed = list.take(20).toList();
    await Store.saveCoords(trimmed);
    if (!mounted) return;
    setState(() => _saved = trimmed);
    _toast('已记住 ${entry.label} ${entry.coordText}');
  }

  void _recall(SavedCoord c, bool intoGun) {
    var dropped = false;
    setState(() {
      _text[intoGun ? Field.gunX : Field.tgtX] = c.x.toStringAsFixed(2);
      _text[intoGun ? Field.gunY : Field.tgtY] = c.y.toStringAsFixed(2);
      dropped = _dropStaleOffset();
    });
    if (dropped) _toast('坐标变了，弹着点矫正已清零');
    if (intoGun) Store.saveLastGun(_text[Field.gunX]!, _text[Field.gunY]!);
  }

  Future<void> _deleteSaved(SavedCoord c) async {
    final list = _saved.where((e) => e.savedAt != c.savedAt).toList();
    await Store.saveCoords(list);
    if (!mounted) return;
    setState(() => _saved = list);
  }

  Future<void> _copy() async {
    final s = _solution;
    if (s == null) {
      _toast('四个坐标填完才有诸元');
      return;
    }
    await Clipboard.setData(ClipboardData(text: s.shareText));
    await _record(s);
    if (!mounted) return;
    _toast('已复制并记下这一发');
  }

  /// 复制诸元时自动记一发。同一发重复点不会记两条。
  Future<void> _record(FireSolution s) async {
    final entry = ShotRecord(
      gunX: _val(Field.gunX)!,
      gunY: _val(Field.gunY)!,
      tgtX: _val(Field.tgtX)!,
      tgtY: _val(Field.tgtY)!,
      offX: _offsetX,
      offY: _offsetY,
      rangeM: s.rangeRounded,
      bearing: s.bearingLabel,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
    if (_shots.isNotEmpty && _shots.first.sameAs(entry)) return;
    final list = [entry, ..._shots].take(50).toList();
    await Store.saveShots(list);
    if (!mounted) return;
    setState(() => _shots = list);
  }

  Future<void> _openHistory() async {
    final restored = await Navigator.push<ShotRecord>(
      context,
      MaterialPageRoute(builder: (_) => HistoryScreen(shots: _shots)),
    );
    final fresh = await Store.loadShots();
    if (!mounted) return;
    setState(() {
      _shots = fresh;
      if (restored != null) {
        _text[Field.gunX] = restored.gunX.toStringAsFixed(2);
        _text[Field.gunY] = restored.gunY.toStringAsFixed(2);
        _text[Field.tgtX] = restored.tgtX.toStringAsFixed(2);
        _text[Field.tgtY] = restored.tgtY.toStringAsFixed(2);
        _offsetX = restored.offX;
        _offsetY = restored.offY;
        _focus = null;
      }
    });
    if (restored != null) {
      Store.saveLastGun(_text[Field.gunX]!, _text[Field.gunY]!);
      _toast('已还原 ${restored.rangeM} 米 · ${restored.bearing}');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: C.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = _solution;
    return Scaffold(
      appBar: AppBar(
        title: const Text('迫击炮计算器'),
        actions: [
          TextButton(
            onPressed: _openHistory,
            child: Text(
              _shots.isEmpty ? '记录' : '记录 ${_shots.length}',
              style: const TextStyle(
                  color: C.gold, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _focus = null),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                children: [
                  _SolutionCard(solution: s, onCopy: _copy),
                  const SizedBox(height: 12),
                  _CoordGroup(
                    title: '我的炮位',
                    xField: Field.gunX,
                    yField: Field.gunY,
                    text: _text,
                    focus: _focus,
                    onFocus: (f) => setState(() => _focus = f),
                    onRemember: () => _remember(true),
                  ),
                  const SizedBox(height: 10),
                  _CoordGroup(
                    title: '敌人位置',
                    xField: Field.tgtX,
                    yField: Field.tgtY,
                    text: _text,
                    focus: _focus,
                    onFocus: (f) => setState(() => _focus = f),
                    onRemember: () => _remember(false),
                  ),
                  const SizedBox(height: 16),
                  _CorrectionSection(
                    step: _step,
                    onStep: _setStep,
                    onNudge: _nudge,
                    offsetX: _offsetX,
                    offsetY: _offsetY,
                    onReset: () => setState(() {
                      _offsetX = 0;
                      _offsetY = 0;
                    }),
                  ),
                  const SizedBox(height: 18),
                  _SavedList(
                    saved: _saved,
                    onRecall: _recall,
                    onDelete: _deleteSaved,
                  ),
                ],
              ),
            ),
          ),
          if (_focus != null) Keypad(onKey: _onKey),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 诸元卡片

class _SolutionCard extends StatelessWidget {
  final FireSolution? solution;
  final VoidCallback onCopy;

  const _SolutionCard({required this.solution, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final s = solution;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 8),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Readout(
                  label: 'RNG',
                  value: s == null ? '—' : '${s.rangeRounded}',
                  suffix: '(米)',
                ),
              ),
              Expanded(
                child: _Readout(
                  label: '方向',
                  value: s == null ? '—' : s.bearingLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: C.goldFaint,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onCopy,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  child: Text(
                    '复制诸元',
                    style: TextStyle(
                      color: C.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

class _Readout extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const _Readout({required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: C.textDim, fontSize: 14)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == '—' ? C.textFaint : C.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 5),
              Text(
                suffix!,
                style: const TextStyle(color: C.textDim, fontSize: 14),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- 坐标输入组

class _CoordGroup extends StatelessWidget {
  final String title;
  final Field xField, yField;
  final Map<Field, String> text;
  final Field? focus;
  final ValueChanged<Field> onFocus;
  final VoidCallback onRemember;

  const _CoordGroup({
    required this.title,
    required this.xField,
    required this.yField,
    required this.text,
    required this.focus,
    required this.onFocus,
    required this.onRemember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: C.textDim, fontSize: 15)),
            InkWell(
              onTap: onRemember,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  '记住',
                  style: TextStyle(
                    color: C.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _CoordField(
                axis: 'X',
                value: text[xField]!,
                active: focus == xField,
                onTap: () => onFocus(xField),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _CoordField(
                axis: 'Y',
                value: text[yField]!,
                active: focus == yField,
                onTap: () => onFocus(yField),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoordField extends StatelessWidget {
  final String axis;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const _CoordField({
    required this.axis,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: C.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? C.gold : C.border,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(axis, style: const TextStyle(color: C.textFaint, fontSize: 15)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? '' : value,
                style: const TextStyle(
                  color: C.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (active)
              Container(width: 2, height: 26, color: C.gold),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ 弹着点矫正

class _CorrectionSection extends StatelessWidget {
  final int step;
  final ValueChanged<int> onStep;
  final ValueChanged<Nudge> onNudge;
  final double offsetX, offsetY;
  final VoidCallback onReset;

  const _CorrectionSection({
    required this.step,
    required this.onStep,
    required this.onNudge,
    required this.offsetX,
    required this.offsetY,
    required this.onReset,
  });

  bool get _hasOffset => offsetX != 0 || offsetY != 0;

  @override
  Widget build(BuildContext context) {
    const presets = [5, 10, 25, 50];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('弹着点矫正',
                style: TextStyle(color: C.textDim, fontSize: 15)),
            Text('$step m',
                style: const TextStyle(color: C.gold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final p in presets) ...[
              _Chip(
                label: '$p',
                selected: p == step,
                onTap: () => onStep(p),
              ),
              const SizedBox(width: 9),
            ],
            _Chip(label: '−', onTap: () => onStep(step - 5)),
            const SizedBox(width: 9),
            _Chip(label: '+', onTap: () => onStep(step + 5)),
          ],
        ),
        const SizedBox(height: 12),
        _NudgePad(onNudge: onNudge),
        if (_hasOffset) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '已矫正 东 ${(offsetX * kGridMeters).round()} m · '
                  '北 ${(offsetY * kGridMeters).round()} m',
                  style: const TextStyle(color: C.gold, fontSize: 14),
                ),
              ),
              InkWell(
                onTap: onReset,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('清零',
                      style: TextStyle(color: C.textDim, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? C.goldFaint : C.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? C.gold : C.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 38,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? C.gold : C.text,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NudgePad extends StatelessWidget {
  final ValueChanged<Nudge> onNudge;

  const _NudgePad({required this.onNudge});

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, Nudge d) => Material(
          color: C.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onNudge(d),
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(label,
                    style: const TextStyle(color: C.text, fontSize: 18)),
              ),
            ),
          ),
        );

    const gap = SizedBox(width: 10);
    const vgap = SizedBox(height: 10);
    const blank = Expanded(child: SizedBox());

    return Column(
      children: [
        Row(children: [blank, gap, Expanded(child: btn('上', Nudge.up)), gap, blank]),
        vgap,
        Row(
          children: [
            Expanded(child: btn('左', Nudge.left)),
            gap,
            const Expanded(
              child: Center(
                child: Text('移动弹着点',
                    style: TextStyle(color: C.textFaint, fontSize: 14)),
              ),
            ),
            gap,
            Expanded(child: btn('右', Nudge.right)),
          ],
        ),
        vgap,
        Row(children: [blank, gap, Expanded(child: btn('下', Nudge.down)), gap, blank]),
      ],
    );
  }
}

// ------------------------------------------------------------- 已记坐标

class _SavedList extends StatelessWidget {
  final List<SavedCoord> saved;
  final void Function(SavedCoord, bool intoGun) onRecall;
  final ValueChanged<SavedCoord> onDelete;

  const _SavedList({
    required this.saved,
    required this.onRecall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('已记 · ${saved.length}',
            style: const TextStyle(color: C.textDim, fontSize: 15)),
        const SizedBox(height: 4),
        if (saved.isEmpty)
          const Text('点记住保存坐标',
              style: TextStyle(color: C.textFaint, fontSize: 14))
        else ...[
          const SizedBox(height: 6),
          for (final c in saved)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: C.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onRecall(c, false),
                  onLongPress: () => onRecall(c, true),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: C.goldFaint,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(c.label,
                              style: const TextStyle(
                                  color: C.gold, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.coordText,
                            style: const TextStyle(
                              color: C.text,
                              fontSize: 17,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: C.textFaint),
                          onPressed: () => onDelete(c),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
