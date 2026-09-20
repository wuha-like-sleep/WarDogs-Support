#!/bin/bash
# 打正式包。混淆 + 导出符号表 + 归档到桌面发版目录。
#
# 为什么要有这个脚本：混淆后的崩溃栈没有符号表就还原不了，
# 而符号表只在打包那一刻生成。手敲命令迟早会漏掉 --split-debug-info，
# 漏了当时看不出来，等线上崩了才发现读不懂。
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="$HOME/development/flutter/bin:$PATH"
# apksigner 是 Java 写的，不设 JAVA_HOME 它会静默失败，
# 于是核验那步什么都不输出 —— 看着像通过了，其实压根没跑。
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
NAME=${VERSION%+*}
BUILD=${VERSION#*+}
DEST="$HOME/Desktop/战狗小助手 发版/$NAME+$BUILD"
SYMS="$DEST/符号表"

echo "打包 $NAME+$BUILD"
echo

echo "[1/5] 门禁"
./tool/check-offline.sh | tail -1
flutter test 2>&1 | tail -1

echo
echo "[2/5] 安卓（混淆）"
mkdir -p "$SYMS/android"
flutter build apk --release \
  --obfuscate --split-debug-info="$SYMS/android" 2>&1 | tail -1

echo
echo "[3/5] iOS（混淆）"
mkdir -p "$SYMS/ios"
flutter build ipa \
  --obfuscate --split-debug-info="$SYMS/ios" 2>&1 | grep -E "Built IPA|error"

echo
echo "[4/5] 归档"
mkdir -p "$DEST/安卓" "$DEST/iOS"
cp build/app/outputs/flutter-apk/app-release.apk "$DEST/安卓/wardogs-assistant-$NAME.apk"
cp build/ios/ipa/*.ipa "$DEST/iOS/战狗小助手-$NAME.ipa"

echo
echo "[5/5] 核验"
APKSIGNER=$(find ~/Library/Android/sdk/build-tools -name apksigner | sort -r | head -1)
AAPT=$(find ~/Library/Android/sdk/build-tools -name aapt2 | sort -r | head -1)
"$APKSIGNER" verify --print-certs "$DEST/安卓/wardogs-assistant-$NAME.apk" 2>&1 \
  | grep "certificate DN" | head -1 || { echo "✗ 签名核验失败"; exit 1; }
"$AAPT" dump permissions "$DEST/安卓/wardogs-assistant-$NAME.apk" 2>/dev/null \
  | grep "android.permission"
SYMCOUNT=$(find "$SYMS" -type f | wc -l | tr -d ' ')
[ "$SYMCOUNT" -ge 4 ] || { echo "✗ 符号表只有 $SYMCOUNT 个，应该至少 4 个"; exit 1; }
echo "符号表：$SYMCOUNT 个文件"

# 混淆真的生效了吗 —— 加了参数不等于起作用
command -v unzip >/dev/null && {
  rm -rf /tmp/_obfchk && mkdir -p /tmp/_obfchk
  unzip -q -o "$DEST/安卓/wardogs-assistant-$NAME.apk" -d /tmp/_obfchk
  LEAK=0
  for sym in FireSolution MortarScreen rangeWarningFor kGridMeters; do
    n=$(strings /tmp/_obfchk/lib/arm64-v8a/libapp.so 2>/dev/null | grep -c "$sym" || true)
    [ "$n" -eq 0 ] || { echo "✗ 混淆没生效：包里能搜到 $sym"; LEAK=1; }
  done
  [ "$LEAK" -eq 0 ] && echo "混淆：已生效（抽查 4 个符号均搜不到）"
  rm -rf /tmp/_obfchk
}
echo
echo "产物都在：$DEST"
echo "符号表不要删 —— 崩溃栈全靠它还原，而且只有打包那一刻有。"
