import 'package:flutter_test/flutter_test.dart';
import 'package:wardogs_assistant/data/game_data.dart';
import 'package:wardogs_assistant/data/progression.dart';

void main() {
  group('等级解锁表', () {
    test('每条梯子按等级递增，不能乱序', () {
      for (final l in kLadders) {
        var prev = 0;
        for (final u in l.unlocks) {
          expect(u.level, greaterThanOrEqualTo(prev),
              reason: '${l.track} 里「${u.name}」的等级 ${u.level} '
                  '排在 $prev 后面，顺序乱了');
          prev = u.level;
        }
      }
    });

    test('标成枪的条目，名字必须在枪械库里找得到', () {
      // 手抄 170 条，打错一个字玩家就在配装页搜不到这把枪。
      // 这里把两份数据对上，错字当场暴露。
      final known = kWeapons.map((w) => w.name).toSet();
      // 载具梯子（驾驶员/飞行员）里的不是枪，SPH-2 是火炮
      final notGuns = {'SPH-2'};
      for (final l in kLadders) {
        for (final u in l.unlocks) {
          if (!u.isWeapon || notGuns.contains(u.name)) continue;
          expect(known, contains(u.name),
              reason: '${l.track} 的 ${u.level} 级解锁「${u.name}」，'
                  '但枪械库里没有这个名字 —— 多半是抄错了');
        }
      }
    });

    test('有枪的梯子必须覆盖到枪械库里需要解锁的枪', () {
      final inLadder = <String>{};
      for (final l in kLadders) {
        for (final u in l.unlocks) {
          if (u.isWeapon) inLadder.add(u.name);
        }
      }
      // 免费枪和初始枪不在梯子上，单独列着
      final exempt = kNoLadderWeapons.keys.toSet();
      final missing = kWeapons
          .map((w) => w.name)
          .where((n) => !inLadder.contains(n) && !exempt.contains(n))
          .toList();
      // 还有几把枪各家资料都查不到解锁条件，允许缺，但数量要盯住 ——
      // 哪天补了数据这里会提醒更新
      expect(missing.length, lessThanOrEqualTo(8),
          reason: '有 ${missing.length} 把枪既不在解锁表里、也不在免费名单里：'
              '$missing');
    });

    test('驾驶员那条线必须带警告', () {
      final driver = kLadders.firstWhere((l) => l.track == '驾驶员');
      expect(driver.warning, isNotNull,
          reason: '两个来源对这条线整体不一致，不标出来就是在骗玩家');
    });

    test('只要等级不要钱的条目，cost 是 null 而不是 0', () {
      // 0 会被显示成 "\$0"，那是「免费」；
      // 「到级即得」是另一回事，不能混
      for (final l in kLadders) {
        for (final u in l.unlocks) {
          expect(u.cost, isNot(0),
              reason: '${l.track}「${u.name}」的 cost 写成了 0，'
                  '不要钱应该用 null');
        }
      }
    });
  });
}
