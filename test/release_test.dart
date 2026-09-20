import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardogs_assistant/ballistics.dart';
import 'package:wardogs_assistant/data/store.dart';
import 'package:wardogs_assistant/data/updater.dart';

void main() {
  group('发版一致性', () {
    test('pubspec 的 version 和 updater 的 kAppVersion 必须一致', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final m = RegExp(r'^version:\s*([0-9.]+)', multiLine: true)
          .firstMatch(pubspec);
      expect(m, isNotNull, reason: 'pubspec.yaml 里没找到 version');
      final fromPubspec = m!.group(1);
      expect(
        kAppVersion,
        fromPubspec,
        reason: '改版本号时两处都要改：pubspec.yaml 的 version '
            '和 lib/data/updater.dart 的 kAppVersion。'
            '不一致会让「检查更新」拿错版本比',
      );
    });

    test('发版仓库已配置', () {
      expect(kUpdateConfigured, isTrue);
      expect(kRepoOwner, isNotEmpty);
      expect(kRepoName, isNotEmpty);
    });
  });

  group('版本号比较', () {
    test('带不带 v 前缀都认得', () {
      expect(compareVersions('v1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0', 'v1.0.0'), 0);
    });

    test('逐段比数字，不是比字符串', () {
      expect(compareVersions('1.10.0', '1.2.0'), greaterThan(0));
      expect(compareVersions('1.2.0', '1.10.0'), lessThan(0));
    });

    test('其它前缀的 tag 不能静默判成「已是最新」', () {
      // 这些以前会把前缀当成第 0 段，全部得出「不比当前新」
      expect(compareVersions('release-1.2.0', '1.0.0'), greaterThan(0));
      expect(compareVersions('Version 1.2.0', '1.0.0'), greaterThan(0));
      expect(compareVersions('wardogs-2.0.0', '1.0.0'), greaterThan(0));
    });

    test('压根没有版本号的 tag 一律不提示更新', () {
      expect(compareVersions('latest', '1.0.0'), lessThan(0));
      expect(compareVersions('v', '1.0.0'), lessThan(0));
      expect(compareVersions('', '1.0.0'), lessThan(0));
    });

    test('旧版本不会被当成新版本', () {
      expect(compareVersions('v0.9.9', '1.0.0'), lessThan(0));
    });
  });

  group('炮位记忆的保鲜期', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('刚存的能读回来', () async {
      final now = DateTime(2026, 9, 15, 20, 0);
      await Store.saveLastGun('63.41', '104.52', now: now);
      final (x, y) = await Store.loadLastGun(now: now.add(const Duration(minutes: 30)));
      expect(x, '63.41');
      expect(y, '104.52');
    });

    test('超过保鲜期就不再预填 —— 多半已经换局换图了', () async {
      final now = DateTime(2026, 9, 15, 20, 0);
      await Store.saveLastGun('63.41', '104.52', now: now);
      final (x, y) = await Store.loadLastGun(now: now.add(const Duration(hours: 13)));
      expect(x, '');
      expect(y, '');
    });

    test('从来没存过时读到空值，不报错', () async {
      final (x, y) = await Store.loadLastGun();
      expect(x, '');
      expect(y, '');
    });
  });

  group('混淆安全', () {
    test('火炮枚举的存储键是写死的，不跟随标识符', () {
      // 开了 --obfuscate 之后 .name 可能被重命名。
      // 这两个键一旦变了，老用户的选择会静默丢失。
      expect(Artillery.l81.storageKey, 'l81');
      expect(Artillery.sph2.storageKey, 'sph2');
      // 每个都不一样，否则 firstWhere 会认错
      final keys = Artillery.values.map((a) => a.storageKey).toSet();
      expect(keys.length, Artillery.values.length);
    });
  });
}
