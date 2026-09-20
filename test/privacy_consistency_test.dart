import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/screens/privacy_screen.dart';

/// 隐私说法有四处：App 内页面、docs/PRIVACY.md、
/// iOS 隐私清单、以及 App Store Connect 的问卷（人工填）。
/// 审核员会交叉核对，任何一处对不上都会被退。
/// 这里守住能自动检查的三处。
void main() {
  group('隐私声明一致性', () {
    test('iOS 隐私清单：不追踪、不收集', () {
      final f = File('ios/Runner/PrivacyInfo.xcprivacy');
      expect(f.existsSync(), isTrue, reason: '隐私清单文件不见了');
      final xml = f.readAsStringSync();
      expect(xml, contains('NSPrivacyTracking'));
      // <key>NSPrivacyTracking</key> 后面必须紧跟 <false/>
      final m = RegExp(r'<key>NSPrivacyTracking</key>\s*<(\w+)/>')
          .firstMatch(xml);
      expect(m?.group(1), 'false',
          reason: 'NSPrivacyTracking 必须是 false');
      expect(xml, contains('<key>NSPrivacyCollectedDataTypes</key>'));
      expect(RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>')
          .hasMatch(xml), isTrue,
          reason: '声明收集了数据，就和 App 内「什么都不收集」矛盾了');
    });

    test('隐私清单已加进 Xcode 工程，否则打不进包', () {
      final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(pbx, contains('PrivacyInfo.xcprivacy'),
          reason: '文件在磁盘上但没进工程 —— 构建照常成功，包里却没有');
      expect(pbx.contains('PrivacyInfo.xcprivacy in Resources'), isTrue,
          reason: '没加进 Resources 构建阶段，不会被拷进 .app');
    });

    test('仓库里的隐私政策还在，且口径一致', () {
      final md = File('docs/PRIVACY.md');
      expect(md.existsSync(), isTrue,
          reason: 'App Store Connect 的隐私政策 URL 指向它，删了链接就断');
      final text = md.readAsStringSync();
      for (final claim in ['不收集', '检查更新', 'INTERNET']) {
        expect(text, contains(claim),
            reason: '隐私政策里少了「$claim」这一层说明');
      }
    });

    testWidgets('App 内那页要能打开，且离线可读（不依赖任何网络组件）', (t) async {
      await t.pumpWidget(const MaterialApp(home: PrivacyScreen()));
      await t.pumpAndSettle();

      expect(find.text('隐私政策'), findsOneWidget);
      expect(find.textContaining('不收集你的任何信息'), findsOneWidget);
      expect(find.textContaining('飞行模式'), findsOneWidget);
      expect(find.textContaining('检查更新'), findsOneWidget);
    });
  });

  group('双协议', () {
    test('三份协议文件都在', () {
      expect(File('LICENSE').existsSync(), isTrue);
      expect(File('LICENSE-EXCEPTION').existsSync(), isTrue);
      expect(File('LICENSE-DATA').existsSync(), isTrue);
    });

    test('LICENSE 是 GPL-3.0 原文，不能夹带别的', () {
      final t = File('LICENSE').readAsStringSync();
      expect(t.trimLeft(), startsWith('GNU GENERAL PUBLIC LICENSE'),
          reason: '前面加了自定义说明，GitHub 就识别不出协议、'
              '徽章会变成 Other，别人看不到「这是 GPL」这个信号');
      expect(t, contains('Version 3, 29 June 2007'));
    });

    test('App Store 例外单独成文且引用了 GPL 第 7 条', () {
      final t = File('LICENSE-EXCEPTION').readAsStringSync();
      // 少了这条，GPL 与 Apple 服务条款冲突，一封投诉就能让 App 下架
      expect(t, contains('App Store'));
      expect(t, contains('第 7 条'));
      expect(t, contains('源代码'),
          reason: '例外只豁免分发限制，提供源码的义务还在，必须写明');
    });

    test('数据协议是 CC BY-SA 4.0 并写明范围', () {
      final t = File('LICENSE-DATA').readAsStringSync();
      expect(t, contains('CC BY-SA 4.0'));
      expect(t, contains('game_data.dart'),
          reason: '没写清哪些算「数据」，这份协议就没有边界');
    });

    test('README 的协议说明和实际文件一致', () {
      final t = File('README.md').readAsStringSync();
      expect(t, contains('GPL-3.0'));
      expect(t, contains('CC BY-SA 4.0'));
      expect(t.contains('本项目以 [MIT 许可证](LICENSE)开源'), isFalse,
          reason: 'README 还在说 MIT，和 LICENSE 对不上');
    });
  });
}
