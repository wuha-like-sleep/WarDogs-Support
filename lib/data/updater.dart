import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 当前版本，发版时改这里（要和 pubspec.yaml 的 version 一致）
const String kAppVersion = '1.0.6';

/// App Store 的应用编号。iOS 走商店更新，不走 GitHub。
const String kAppStoreId = '6812643556';

String get kAppStoreUrl => 'https://apps.apple.com/app/id$kAppStoreId';

/// 发版仓库。安卓走 GitHub Releases 自建渠道 —— 这是整个 App 唯一会联网的地方。
/// 换仓库只改这两行。
const String kRepoOwner = 'wuha-like-sleep';
const String kRepoName = 'WarDogs-Support';

bool get kUpdateConfigured => kRepoOwner.isNotEmpty && kRepoName.isNotEmpty;

class UpdateInfo {
  final String version;
  final String pageUrl;
  final String notes;

  const UpdateInfo({
    required this.version,
    required this.pageUrl,
    required this.notes,
  });
}

sealed class UpdateResult {
  const UpdateResult();
}

class UpToDate extends UpdateResult {
  const UpToDate();
}

class UpdateAvailable extends UpdateResult {
  final UpdateInfo info;
  const UpdateAvailable(this.info);
}

class UpdateFailed extends UpdateResult {
  final String reason;
  const UpdateFailed(this.reason);
}

class NotConfigured extends UpdateResult {
  const NotConfigured();
}

/// 从 tag 里挖出版本号。tag 可能叫 v1.2.0、release-1.2.0、Version 1.2.0，
/// 只剥 ^v 的话 "release" 会被当成第 0 段，整个比较静默失真。
List<int>? parseVersion(String v) {
  final m = RegExp(r'(\d+(?:\.\d+)*)').firstMatch(v);
  if (m == null) return null;
  return m.group(1)!.split('.').map(int.parse).toList();
}

/// 比版本号。1.2.0 > 1.10.0 这种坑要靠逐段比数字，不能比字符串。
/// 任一边解析不出版本号时返回 -1（当作「不比当前新」），
/// 宁可不提示更新，也不要因为 tag 起错名就把用户推去下载。
int compareVersions(String a, String b) {
  final pa = parseVersion(a);
  final pb = parseVersion(b);
  if (pa == null || pb == null) return -1;

  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// 主动去 GitHub 查最新版。只有用户点「检查更新」才会调用。
Future<UpdateResult> checkForUpdate({
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (!kUpdateConfigured) return const NotConfigured();

  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$kRepoOwner/$kRepoName/releases/latest',
    );
    final req = await client.getUrl(uri).timeout(timeout);
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    req.headers.set(HttpHeaders.userAgentHeader, 'wardogs-assistant');
    final res = await req.close().timeout(timeout);

    if (res.statusCode == 404) {
      return const UpdateFailed('暂时没有新版本');
    }
    if (res.statusCode != 200) {
      return const UpdateFailed('暂时连不上，待会儿再试');
    }

    final body = await res.transform(utf8.decoder).join().timeout(timeout);
    final json = jsonDecode(body) as Map<String, dynamic>;
    final tag = (json['tag_name'] as String?)?.trim() ?? '';
    if (tag.isEmpty) return const UpdateFailed('暂时没有新版本');

    if (compareVersions(tag, kAppVersion) <= 0) return const UpToDate();

    return UpdateAvailable(UpdateInfo(
      version: tag,
      pageUrl: (json['html_url'] as String?) ??
          'https://github.com/$kRepoOwner/$kRepoName/releases/latest',
      notes: (json['body'] as String?)?.trim() ?? '',
    ));
  } on TimeoutException {
    return const UpdateFailed('连接超时，检查一下网络');
  } on SocketException {
    return const UpdateFailed('连不上网络');
  } catch (_) {
    return const UpdateFailed('检查更新时出了点问题');
  } finally {
    client.close(force: true);
  }
}
