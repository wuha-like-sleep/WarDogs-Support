import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ballistics.dart';
import '../data/settings.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/keypad.dart';
import '../widgets/page_body.dart';
import 'history_screen.dart';

/// 四个输入框的顺序，「下一项」按这个顺序走
enum Field { gunX, gunY, tgtX, tgtY }

/// 坐标最多这么长。游戏里的坐标形如 104.52，8 位足够，
/// 超了只可能是误触追加出来的垃圾（还会把输入框撑爆）。
const int kMaxCoordLength = 8;

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

  /// 刚切到这个格子、还没按过数字。此时按第一个数字表示重打，
  /// 而不是接在旧值后面 —— 否则「67.56」上接着敲会变成「67.567012」，
  /// 一个完全合法、解析得出、但错得离谱的坐标。
  bool _freshFocus = true;

  /// 小屏（iPhone SE 375×667）上键盘占掉 313px，敌人坐标那两个格子
  /// 会整块落在折叠线以下。切焦点时把当前格子滚进视野，
  /// 否则玩家是在看不见输入框的情况下敲坐标。
  final _fieldKeys = {for (final f in Field.values) f: GlobalKey()};

  void _ensureFocusVisible() {
    final f = _focus;
    if (f == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _fieldKeys[f]?.currentContext;
      if (ctx == null) return;
      // keepVisibleAtEnd：只在这个格子确实不可见时才滚，滚最小距离。
      // 不能用 alignment —— 那会不管三七二十一滚到指定位置，
      // 启动时就把诸元卡片的顶部（RNG / 方向 两个标签）顶出屏幕。
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }
  double _offsetX = 0, _offsetY = 0;

  /// 用容差判零。步长 5/10/15/20 米时偏移是 0.05 这类二进制除不尽的数，
  /// 上下各按三次回到原点会剩 2.8e-17，用 != 0 判会让「已矫正 东 0 m · 北 0 m」
  /// 这行自相矛盾的提示永远消不掉。
  bool get _offsetIsSet => _offsetX.abs() > 1e-9 || _offsetY.abs() > 1e-9;
  int _step = 25;

  double get _grid => gridMeters.value;
  List<SavedCoord> _saved = const [];
  List<ShotRecord> _shots = const [];

  @override
  void initState() {
    super.initState();
    _restore();
    // 在「更多」里改了刻度，这边要立刻跟着重算
    gridMeters.addListener(_onGridChanged);
    artillery.addListener(_onGridChanged);
  }

  @override
  void dispose() {
    gridMeters.removeListener(_onGridChanged);
    artillery.removeListener(_onGridChanged);
    super.dispose();
  }

  void _onGridChanged() {
    if (mounted) setState(() {});
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
    // 启动时不主动滚。焦点落在第一个格子上本来就可见，
    // 强行滚只会把诸元卡片顶出屏幕。
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
      gridMeters: _grid,
    );
  }

  /// 矫正量是针对「当前这组炮位 + 目标」试出来的。
  /// 任何一个坐标变了，这组矫正就不再成立 —— 留着它会让新目标的诸元
  /// 静默偏掉，界面还一切正常。这是这个 App 最致命的一类错误。
  /// 必须在 setState 里调用；返回是否真的清掉了东西。
  bool _dropStaleOffset() {
    if (!_offsetIsSet) return false;
    _offsetX = 0;
    _offsetY = 0;
    return true;
  }

  void _focusField(Field f) {
    setState(() {
      _focus = f;
      _freshFocus = true;
    });
    _ensureFocusVisible();
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
        setState(() {
          _focus = next;
          _freshFocus = true;
        });
        _ensureFocusVisible();
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
          if (_freshFocus) s = '';
          if (s.length < kMaxCoordLength) s += k.label;
        case KeyKind.dot:
          if (_freshFocus) s = '';
          if (!s.contains('.') && s.length < kMaxCoordLength) {
            s = s.isEmpty ? '0.' : '$s.';
          }
        case KeyKind.minus:
          // 空格子上按负号只会得到一个孤零零的 "-"：看着像填好了，
          // 其实解析不出来，还会被存进磁盘。空的时候直接忽略。
          if (s.isEmpty) break;
          s = s.startsWith('-') ? s.substring(1) : '-$s';
        case KeyKind.clear:
          s = '';
        case KeyKind.backspace:
          if (s.isNotEmpty) s = s.substring(0, s.length - 1);
        default:
          break;
      }
      _text[f] = s;
      _freshFocus = false;
      if (s != before) dropped = _dropStaleOffset();
    });

    if (dropped) _toast('坐标变了，弹着点矫正已清零');

    if (f == Field.gunX || f == Field.gunY) {
      // 只存解析得出的值。"-" 或 "0." 这类中间态存进去，
      // 下次启动会预填一个用不了的炮位。
      final gx = _text[Field.gunX]!;
      final gy = _text[Field.gunY]!;
      final okX = gx.isEmpty || double.tryParse(gx) != null;
      final okY = gy.isEmpty || double.tryParse(gy) != null;
      if (okX && okY) Store.saveLastGun(gx, gy);
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
        gridMeters: _grid,
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

  /// 在 L81 和 SPH-2 之间切。射程判断跟着走。
  Future<void> _toggleGun() async {
    final next =
        artillery.value == Artillery.l81 ? Artillery.sph2 : Artillery.l81;
    await setArtillery(next);
    if (!mounted) return;
    _toast('已切到 ${next.label}');
  }

  /// 在 100 / 10 之间切。默认 100 是对的，留这个是为了万一。
  Future<void> _toggleGrid() async {
    final next = gridMeters.value == 100 ? 10.0 : 100.0;
    await setGridMeters(next);
    if (!mounted) return;
    _toast('地图刻度已切到 ${next.toInt()} 米/格');
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
      // 存米：这条记录换个刻度打开也还原得回来
      offX: _offsetIsSet ? _offsetX * _grid : 0,
      offY: _offsetIsSet ? _offsetY * _grid : 0,
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
        // 记录里存的是米，换回当前刻度下的格
        _offsetX = restored.offX / _grid;
        _offsetY = restored.offY / _grid;
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
            child: PageBody(
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _focus = null),
              child: ListView(
                // 四个坐标框必须始终保持构建：滚出视口被销毁后，
                // GlobalKey 的 currentContext 变空，
                // 「切焦点自动滚进视野」就彻底失效了（而且悄无声息）。
                cacheExtent: 1200,
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                children: [
                  _SolutionCard(
                    solution: s,
                    onCopy: _copy,
                    gun: artillery.value,
                    grid: _grid,
                    onToggleGun: _toggleGun,
                    onToggleGrid: _toggleGrid,
                  ),
                  const SizedBox(height: 12),
                  _CoordGroup(
                    title: '我的炮位',
                    xField: Field.gunX,
                    yField: Field.gunY,
                    text: _text,
                    focus: _focus,
                    onFocus: _focusField,
                    onRemember: () => _remember(true),
                    fieldKeys: _fieldKeys,
                  ),
                  const SizedBox(height: 10),
                  _CoordGroup(
                    title: '敌人位置',
                    xField: Field.tgtX,
                    yField: Field.tgtY,
                    text: _text,
                    focus: _focus,
                    onFocus: _focusField,
                    onRemember: () => _remember(false),
                    fieldKeys: _fieldKeys,
                  ),
                  const SizedBox(height: 16),
                  _CorrectionSection(
                    step: _step,
                    onStep: _setStep,
                    onNudge: _nudge,
                    offsetX: _offsetIsSet ? _offsetX : 0,
                    offsetY: _offsetIsSet ? _offsetY : 0,
                    gridMeters: _grid,
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
          ),
          if (_focus != null) PageBody(child: Keypad(onKey: _onKey)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 诸元卡片

class _SolutionCard extends StatelessWidget {
  final FireSolution? solution;
  final VoidCallback onCopy;
  final Artillery gun;
  final double grid;
  final VoidCallback onToggleGun;
  final VoidCallback onToggleGrid;

  const _SolutionCard({
    required this.solution,
    required this.onCopy,
    required this.gun,
    required this.grid,
    required this.onToggleGun,
    required this.onToggleGrid,
  });

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
          if (s?.rangeWarningFor(gun) != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 17, color: C.gold),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    s!.rangeWarningFor(gun)!,
                    style: const TextStyle(color: C.gold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // 用 Wrap 不用 Row：窄屏或大字号下这三个排不下，
          // Row 会直接横向溢出。
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              // 这两个参数都会改变上面那两个数字，必须和它们同屏。
              // 藏进设置里 = 把会出错的东西藏起来。
              _MiniToggle(
                icon: Icons.adjust,
                label: gun.shortLabel,
                onTap: onToggleGun,
              ),
              _MiniToggle(
                icon: Icons.grid_4x4,
                label: '${grid.toInt()}m/格',
                onTap: onToggleGrid,
              ),
              Material(
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
            ],
          ),
        ],
      ),
    );
  }
}

/// 诸元卡片底部那两个小开关。低调但一眼能看见当前值。
class _MiniToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.surfaceHigh,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: C.textFaint),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(color: C.textDim, fontSize: 13)),
            ],
          ),
        ),
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
  final Map<Field, GlobalKey> fieldKeys;

  const _CoordGroup({
    required this.title,
    required this.xField,
    required this.yField,
    required this.text,
    required this.focus,
    required this.onFocus,
    required this.onRemember,
    required this.fieldKeys,
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
                key: fieldKeys[xField],
                axis: 'X',
                value: text[xField]!,
                active: focus == xField,
                onTap: () => onFocus(xField),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _CoordField(
                key: fieldKeys[yField],
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
    super.key,
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
  final double gridMeters;

  const _CorrectionSection({
    required this.step,
    required this.onStep,
    required this.onNudge,
    required this.offsetX,
    required this.offsetY,
    required this.onReset,
    required this.gridMeters,
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
        // 用 Wrap 不用 Row：6 个按钮在 320 宽的屏上排不下，
        // Row 会直接横向溢出 29px。窄屏上让它换行，别挤没了。
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final p in presets)
              _Chip(
                label: '$p',
                selected: p == step,
                onTap: () => onStep(p),
              ),
            _Chip(label: '−', onTap: () => onStep(step - 5)),
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
                  '已矫正 东 ${(offsetX * gridMeters).round()} m · '
                  '北 ${(offsetY * gridMeters).round()} m',
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
                  // 卡片上写着「炮位」就填进炮位，写着「目标」就填进目标。
                  // 原先是点=目标、长按=炮位，而界面上没有一个字说明，
                  // 于是点一张写着「炮位」的卡片，数字会落进敌人格子。
                  onTap: () => onRecall(c, c.label == '炮位'),
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
