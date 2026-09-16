import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/updater.dart';
import '../theme.dart';
import '../widgets/page_body.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _checking = false;

  Future<void> _openStore() async {
    final uri = Uri.parse(kAppStoreUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _snack('打不开 App Store');
    }
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final r = await checkForUpdate();
    if (!mounted) return;
    setState(() => _checking = false);

    switch (r) {
      case UpToDate():
        _snack('已经是最新版本');
      case NotConfigured():
        _snack('暂时无法检查更新');
      case UpdateFailed(:final reason):
        _snack(reason);
      case UpdateAvailable(:final info):
        _showUpdate(info);
    }
  }

  void _showUpdate(UpdateInfo info) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('有新版本 ${info.version}',
            style: const TextStyle(color: C.text, fontSize: 18)),
        content: SingleChildScrollView(
          child: Text(
            info.notes.isEmpty ? '去下载页面看看这版更新了什么。' : info.notes,
            style: const TextStyle(color: C.textDim, fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('以后再说',
                style: TextStyle(color: C.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(info.pageUrl);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (mounted) _snack('打不开下载页面');
              }
            },
            child: const Text('去下载',
                style: TextStyle(color: C.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: C.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: PageBody(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('战狗小助手',
                    style: TextStyle(
                        color: C.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('版本 $kAppVersion',
                    style: const TextStyle(color: C.textDim, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: InkWell(
              // iOS 的更新由 App Store 负责。去 GitHub 查版本对 iPhone 用户
              // 毫无意义 —— 那边挂的是安卓 APK，点进去拿到一个装不了的文件。
              onTap: _checking ? null : (Platform.isIOS ? _openStore : _check),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          Platform.isIOS ? '在 App Store 中查看' : '检查更新',
                          style: const TextStyle(color: C.text, fontSize: 16)),
                    ),
                    if (_checking)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: C.gold),
                      )
                    else
                      const Icon(Icons.chevron_right,
                          color: C.textFaint, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('玩家自制工具',
                    style: TextStyle(
                        color: C.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 9),
                Text(
                  '本工具由玩家自发制作，免费提供，不用于任何商业用途。\n'
                  '与 BULKHEAD、Team17 无关，未获其授权或认可。\n'
                  'WARDOGS 及相关名称、商标归其权利人所有。\n'
                  '数据来自公开社区攻略，以游戏内实际数值为准。\n'
                  '如权利人认为有不妥之处，请联系删除。',
                  style: TextStyle(color: C.textDim, fontSize: 14, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Row(
              children: const [
                Icon(Icons.wifi_off, color: C.gold, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text('所有功能和数据都在本地，断网照常用',
                      style: TextStyle(color: C.textDim, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: child,
    );
  }
}
