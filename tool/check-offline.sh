#!/bin/bash
# 门禁：守住「不联网」这条线。
# 1) 正式包只能有 INTERNET 一个权限
# 2) 源码里不能出现除更新检查以外的网络调用
set -u
fail=0

MANIFEST=android/app/src/main/AndroidManifest.xml

perms=$(grep -o 'android.permission.[A-Z_]*' "$MANIFEST" | sort -u)
count=$(echo "$perms" | grep -c . )

if [ "$count" -ne 1 ] || [ "$perms" != "android.permission.INTERNET" ]; then
  echo "✗ 正式包权限不对。期望只有 INTERNET，实际："
  echo "$perms" | sed 's/^/    /'
  fail=1
else
  echo "✓ 正式包只申请 INTERNET 一个权限"
fi

# 网络调用只允许出现在 updater.dart 里
hits=$(grep -rlE 'HttpClient|package:http|WebSocket|Socket\(' lib/ 2>/dev/null \
       | grep -v 'lib/data/updater.dart' || true)
if [ -n "$hits" ]; then
  echo "✗ updater.dart 之外出现了网络调用："
  echo "$hits" | sed 's/^/    /'
  fail=1
else
  echo "✓ 网络调用只存在于 updater.dart"
fi

# updater 只能被「更多」页调用，不能在启动时自动跑
auto=$(grep -rn 'checkForUpdate' lib/ | grep -v 'lib/data/updater.dart' \
       | grep -v 'lib/screens/more_screen.dart' || true)
if [ -n "$auto" ]; then
  echo "✗ 检查更新被「更多」页以外的地方调用了（可能会自动联网）："
  echo "$auto" | sed 's/^/    /'
  fail=1
else
  echo "✓ 检查更新只由用户在「更多」页主动触发"
fi

[ "$fail" -eq 0 ] && echo "" && echo "不联网门禁全部通过" || echo ""
exit $fail
