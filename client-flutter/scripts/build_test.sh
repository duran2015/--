#!/bin/bash
set -e

# 获取项目根目录（scripts 目录的上级目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo "      开始构建 测试版本 (Test/Debug)       "
echo "=========================================="

# 1. 禁用 SPM、环境清理与依赖升级
echo "--> 1/5: 禁用 Swift Package Manager (flutter config --no-enable-swift-package-manager)..."
flutter config --no-enable-swift-package-manager

echo "--> 2/5: 清理缓存 (flutter clean)..."
flutter clean

echo "--> 3/5: 升级依赖 (flutter pub upgrade)..."
flutter pub upgrade

# 2. 构建 Android Release APK
echo "--> 4/5: 开始打包 Android (flutter build apk --release)..."
flutter build apk --release

# 3. 切换到 iOS 目录，执行 pod install 并使用 fastlane 构建测试包
echo "--> 5/5: 开始打包 iOS (pod install & fastlane buildDebug)..."
cd "$PROJECT_ROOT/ios"
echo "    执行 pod install..."
pod install

echo "    执行 fastlane buildDebug..."
fastlane buildDebug

# 4. 统一归集打包产物到 build/app-outs 并按规则重命名
echo "--> 整理打包产出到 build/app-outs..."
OUTPUT_DIR="$PROJECT_ROOT/build/app-outs"
mkdir -p "$OUTPUT_DIR"

# 从 pubspec.yaml 读取 version 字段 (例如 0.1.0+1 -> 0.1.0_1)
APP_VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | sed -E 's/version:[[:space:]]*//' | tr -d '\r' | sed 's/+/_/g')
DATETIME=$(date +"%Y%m%d_%H%M%S")

# 重命名规则: kelu_${appversion}_${datetime}
APK_NAME="kelu_${APP_VERSION}_${DATETIME}.apk"
IPA_NAME="kelu_${APP_VERSION}_${DATETIME}.ipa"

if [ -f "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "    重命名并移动 APK 到 $OUTPUT_DIR/$APK_NAME..."
    mv "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/$APK_NAME"
fi

if [ -f "$PROJECT_ROOT/ios/Runner.ipa" ]; then
    echo "    重命名并移动 IPA 到 $OUTPUT_DIR/$IPA_NAME..."
    mv "$PROJECT_ROOT/ios/Runner.ipa" "$OUTPUT_DIR/$IPA_NAME"
fi

echo "=========================================="
echo "      测试版本打包完成！                  "
echo "  产物目录: $OUTPUT_DIR"
echo "=========================================="
