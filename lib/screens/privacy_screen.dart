import 'package:flutter/material.dart';

import '../theme.dart';

/// 隐私政策。正文写死在包里，不联网也能看 ——
/// 一个主打离线的工具，政策却要联网才读得到，说不过去。
/// 内容要和 docs/PRIVACY.md、App Store 隐私问卷保持一致，
/// 审核员会交叉核对，三处说法不一致会被退。
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      '一句话',
      '这个 App 不收集你的任何信息。没有服务器、没有账号、没有统计、没有广告。'
          '你在里面做的一切都留在自己手机上。'
    ),
    (
      '我们收集什么',
      '什么都不收集。不收集姓名、邮箱、手机号或任何身份信息；'
          '不收集设备标识符、广告 ID；不收集位置；'
          '不收集使用行为、点击记录、崩溃日志；'
          '不读取通讯录、照片、文件。'
          '不含任何第三方 SDK、分析组件或广告组件。'
    ),
    (
      '你的数据在哪',
      '你填的炮位坐标、记住的坐标、射击记录，全部保存在这台手机的应用沙盒里。'
          '这些数据不会离开你的设备，卸载 App 时会一并删除。'
    ),
    (
      '关于联网',
      '正常使用全程不联网，飞行模式下功能一模一样。\n\n'
          '唯一的网络请求发生在你主动点「检查更新」时：去读一下最新的版本号，'
          '判断有没有新版本。这个请求不携带你的任何信息。'
          '你要是从不点它，这个 App 一次网络请求都不会发起。\n\n'
          '安卓版只申请一个系统权限（INTERNET），就是给上面这件事用的。'
    ),
    (
      '儿童',
      '本 App 不面向儿童设计，也不收集任何人的信息，包括儿童的。'
    ),
    (
      '联系',
      '有问题可以在项目的 GitHub Issues 里提：\n'
          'github.com/wuha-like-sleep/WarDogs-Support/issues'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const Text('最后更新：2026 年 9 月 21 日',
              style: TextStyle(color: C.textFaint, fontSize: 14)),
          const SizedBox(height: 18),
          for (final (title, body) in _sections) ...[
            Text(title,
                style: const TextStyle(
                    color: C.gold, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(body,
                style: const TextStyle(
                    color: C.textDim, fontSize: 15, height: 1.7)),
            const SizedBox(height: 22),
          ],
          const Text(
            '本工具由玩家自发制作，免费提供，不用于任何商业用途。'
            '与 BULKHEAD、Team17 无关，未获其授权或认可。',
            style: TextStyle(color: C.textFaint, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
