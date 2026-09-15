import 'package:flutter/material.dart';

/// 战狗小助手配色：暗底 + 军械金。
/// 打游戏时多半在暗环境、单手操作，所以底色压得很暗、点击区域给得很大。
class C {
  static const bg = Color(0xFF0B0E13);
  static const surface = Color(0xFF161B23);
  static const surfaceHigh = Color(0xFF1E242E);
  static const field = Color(0xFF1B212B);
  static const border = Color(0xFF2A323E);
  static const gold = Color(0xFFE0B24A);
  static const goldDim = Color(0xFF6B5A22);
  static const goldFaint = Color(0xFF3A2F17);
  static const text = Color(0xFFE8EAED);
  static const textDim = Color(0xFF8A9199);
  static const textFaint = Color(0xFF5C646E);
  static const danger = Color(0xFF7A3B3B);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: C.surface,
      primary: C.gold,
      secondary: C.gold,
      onPrimary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: C.text,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: base.textTheme.apply(bodyColor: C.text, displayColor: C.text),
    dividerColor: C.border,
  );
}

/// 数字一律用等宽字体，报诸元时看着不跳。
const kMono = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
