import 'package:flutter/foundation.dart';

import '../ballistics.dart';
import 'store.dart';

/// 地图一格等于多少米。
///
/// 做成全局可监听，是因为它在「更多」里改、在「迫击炮」页用，
/// 而底部标签用 IndexedStack 保活，计算页不会自己重新读。
final gridMeters = ValueNotifier<double>(kGridMeters);

/// 可选的刻度。10 是实机验证的值；100 是社区文档普遍写的值，
/// 留着以防某些地图真的不一样。
const List<double> kGridChoices = [10, 100];

/// 当前用哪门炮。射程判断按它走。
final artillery = ValueNotifier<Artillery>(Artillery.l81);

Future<void> loadSettings() async {
  gridMeters.value = await Store.loadGridMeters();
  artillery.value = await Store.loadArtillery();
}

Future<void> setArtillery(Artillery a) async {
  artillery.value = a;
  await Store.saveArtillery(a);
}

Future<void> setGridMeters(double m) async {
  if (m <= 0) return;
  gridMeters.value = m;
  await Store.saveGridMeters(m);
}
