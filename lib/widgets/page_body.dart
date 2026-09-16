import 'package:flutter/material.dart';

/// 内容最大宽度。超过这个宽度就居中留白，不要把一套按手机设计的界面
/// 横向拉满 —— 在 13 吋 iPad 上那会变成「顶部一小撮控件 + 大半屏空白」。
const double kMaxContentWidth = 560;

/// 把页面内容收在可读宽度内并居中。窄屏上完全不生效。
class PageBody extends StatelessWidget {
  final Widget child;

  const PageBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: child,
      ),
    );
  }
}
