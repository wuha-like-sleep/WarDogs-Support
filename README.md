# 战狗小助手

> **玩家自制工具，非官方。**
> 本工具由玩家自发制作，免费提供，**不用于任何商业用途，也不用于宣传推广**。
> 与 BULKHEAD、Team17 无关，未获其授权或认可。
> WARDOGS 及相关名称、商标、美术资源均归其权利人所有。
> 本工具不包含、不分发任何游戏文件或官方美术资源；
> 数据来自公开社区攻略，仅供玩家参考，以游戏内实际为准。
> 如权利人认为本工具有不妥之处，请联系删除。

WARDOGS（战狗）的本地助手 App。核心是迫击炮诸元计算器。

## 铁律

**App 不联网。** 所有计算、资料、记住的坐标全在手机本地，没有后端。
唯一一次网络请求是用户主动点「更多 → 检查更新」，除此之外不发任何请求。

安卓正式包**只申请 `INTERNET` 一个权限**，只被更新检查用到。

这条线由 `tool/check-offline.sh` 守着，改动后跑一次：

```bash
./tool/check-offline.sh
```

它会检查三件事：正式包权限只有 INTERNET、网络调用只出现在 `updater.dart`、
`checkForUpdate` 只被「更多」页调用（不会开机自动联网）。

## 诸元公式

公式是从实机截图反推并验证的，别凭感觉改：

- 一格地图 = **100 米**
- 距离 = `√(dx² + dy²) × 100`
- 方位角 = `atan2(东向分量, 北向分量)`，正北 0°，顺时针递增
- 坐标系：**X 向东为正，Y 向北为正**

校验样例（`test/ballistics_test.dart` 里已写死）：

| 炮位 | 敌人 | 应得 |
|---|---|---|
| 63.41, 104.52 | 67.56, 100.67 | 566 米 / 133SE |

```bash
flutter test
```

## 发版

更新走 GitHub Releases。**发版前必须先填** `lib/data/updater.dart` 里的
`kRepoOwner` / `kRepoName`，否则「检查更新」会提示未配置。

版本号要在两处保持一致：`pubspec.yaml` 的 `version` 和 `updater.dart` 的
`kAppVersion`。Release 的 tag 名就是版本号（`v` 前缀可有可无）。

安卓：

```bash
flutter build apk --release
```

把产物传到 GitHub Release，App 里检查更新就能看到。

iOS 由本人手动归档上传。注意：归档**不要**加 `--no-codesign`，
否则 Distribute 时会报 No Team Found in Archive。

## 数据

`lib/data/game_data.dart` 是唯一数据源，整理自 WARDOGS WIKI。
游戏 2026-09-11 才上线，数值还在调，补数据就改这个文件。
拿不到的字段留 `null`，界面会显示横杠而不是把整行藏掉。

## 关于 APK 里的第二条权限

`aapt2 dump permissions` 会看到两条：

- `android.permission.INTERNET` —— 我们自己加的，只给检查更新用
- `cn.bywave.wardogs_assistant.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` ——
  AndroidX 自动生成的**应用自定义权限**，签名级，用户看不到，不访问任何东西，
  每个现代安卓 App 都有。去不掉，也不需要去。

所以「只申请一个权限」指的是**系统权限只有 INTERNET 一条**。

## 避免纠纷的几条硬约束

做任何改动前先看这几条，踩了就是给自己找麻烦：

1. **不放官方美术资源。** 应用图标、界面里都不许用游戏截图、logo、角色立绘。
   图标要自己画或用通用图形。
2. **不内置任何游戏文件**，不做破解、外挂、注入、读内存一类的东西。
   本工具只是个算数器 + 资料本，不碰游戏进程。
3. **不收费、不放广告、不做内购。** 一旦开始赚钱，性质就变了。
4. **数据标明来源**，不宣称官方或权威。
5. 商店描述里不要写成「WARDOGS 官方助手」这类字样，
   要写明是玩家自制的非官方工具。

**iOS 上架要注意：** Apple 对第三方使用游戏商标名比较敏感，
用《战狗 / WARDOGS》做应用名有被拒的可能。真被拒了就改成不含商标的名字，
在描述里说明适用于哪款游戏。
