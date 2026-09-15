import 'package:flutter/material.dart';
import '../theme.dart';

enum KeyKind { digit, minus, dot, clear, backspace, next, hide }

class KeypadKey {
  final String label;
  final KeyKind kind;
  const KeypadKey(this.label, this.kind);
}

/// 自带小键盘。不用系统键盘是有原因的：
/// 系统键盘弹出慢、按键小，而这个 App 是在游戏里争分夺秒用的。
class Keypad extends StatelessWidget {
  final void Function(KeypadKey key) onKey;

  const Keypad({super.key, required this.onKey});

  @override
  Widget build(BuildContext context) {
    const rows = <List<KeypadKey>>[
      [KeypadKey('1', KeyKind.digit), KeypadKey('2', KeyKind.digit), KeypadKey('3', KeyKind.digit)],
      [KeypadKey('4', KeyKind.digit), KeypadKey('5', KeyKind.digit), KeypadKey('6', KeyKind.digit)],
      [KeypadKey('7', KeyKind.digit), KeypadKey('8', KeyKind.digit), KeypadKey('9', KeyKind.digit)],
      [KeypadKey('−', KeyKind.minus), KeypadKey('0', KeyKind.digit), KeypadKey('.', KeyKind.dot)],
      [KeypadKey('C', KeyKind.clear), KeypadKey('⌫', KeyKind.backspace), KeypadKey('下一项', KeyKind.next)],
    ];

    return Container(
      color: C.bg,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Key(
              const KeypadKey('收起键盘', KeyKind.hide),
              onKey: onKey,
              height: 36,
              fullWidth: true,
            ),
            const SizedBox(height: 6),
            for (final row in rows) ...[
              Row(
                children: [
                  for (int i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: _Key(row[i], onKey: onKey)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final KeypadKey k;
  final void Function(KeypadKey) onKey;
  final double height;
  final bool fullWidth;

  const _Key(this.k, {required this.onKey, this.height = 46, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    Color bg = C.surfaceHigh;
    Color fg = C.text;
    double size = 24;
    FontWeight weight = FontWeight.w500;

    switch (k.kind) {
      case KeyKind.next:
        bg = C.goldDim;
        fg = C.gold;
        size = 17;
        weight = FontWeight.w600;
      case KeyKind.backspace:
        bg = const Color(0xFF2A1D1D);
        fg = C.text;
        size = 22;
      case KeyKind.hide:
        bg = C.surfaceHigh;
        fg = C.gold;
        size = 15;
        weight = FontWeight.w600;
      case KeyKind.clear:
        size = 22;
        fg = C.textDim;
      default:
        break;
    }

    final child = Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onKey(k),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              k.label,
              style: TextStyle(color: fg, fontSize: size, fontWeight: weight),
            ),
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}
