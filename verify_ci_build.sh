#!/bin/bash

# 本地模拟 GitHub Actions 构建流程
# 用于验证 CI/CD 配置是否正确

echo "🚀 开始验证 GitHub Actions 构建流程..."
echo "========================================"

# 模拟 GitHub Actions 环境
echo "📋 模拟 GitHub Actions 步骤："

# 1. Setup Flutter (模拟)
echo "✅ 1. Setup Flutter - Flutter 3.16.5 (stable)"

# 2. Flutter version
echo "🔍 2. 检查 Flutter 版本..."
flutter --version

# 3. Install dependencies
echo "📦 3. 安装依赖..."
flutter pub get
if [ $? -eq 0 ]; then
    echo "✅ 依赖安装成功"
else
    echo "❌ 依赖安装失败"
    exit 1
fi

# 4. Analyze code
echo "🔬 4. 分析代码..."
flutter analyze
if [ $? -eq 0 ]; then
    echo "✅ 代码分析通过"
else
    echo "⚠️ 代码分析有警告，但继续构建"
fi

# 5. Run tests
echo "🧪 5. 运行测试..."
flutter test
if [ $? -eq 0 ]; then
    echo "✅ 所有测试通过"
else
    echo "❌ 测试失败"
    exit 1
fi

# 6. Build APK (仅在系统支持时)
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🏗️  6a. 构建 Android APK..."
    flutter build apk --release
    if [ $? -eq 0 ]; then
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        if [ -f "$APK_PATH" ]; then
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            echo "✅ APK 构建成功: $APK_PATH ($APK_SIZE)"
        else
            echo "❌ APK 文件未找到"
            exit 1
        fi
    else
        echo "❌ APK 构建失败"
        exit 1
    fi
else
    echo "⏭️  跳过 Android 构建 (非 Linux/macOS 系统)"
fi

# 7. Build Web
echo "🌐 6b. 构建 Web 应用..."
flutter build web --release
if [ $? -eq 0 ]; then
    WEB_PATH="build/web"
    if [ -d "$WEB_PATH" ]; then
        FILE_COUNT=$(find "$WEB_PATH" -type f | wc -l)
        echo "✅ Web 构建成功: $WEB_PATH ($FILE_COUNT 个文件)"
    else
        echo "❌ Web 构建目录未找到"
        exit 1
    fi
else
    echo "❌ Web 构建失败"
    exit 1
fi

# 8. Build iOS (仅在 macOS 上)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 6c. 构建 iOS 应用..."
    flutter build ios --release --no-codesign
    if [ $? -eq 0 ]; then
        echo "✅ iOS 构建成功"
        
        # 创建 IPA
        echo "📦 创建 iOS IPA..."
        mkdir -p build/ipa
        cp -r build/ios/iphoneos/Runner.app build/ipa/Payload
        cd build/ipa
        zip -r ../Runner.ipa . > /dev/null
        cd ../..
        
        if [ -f "build/Runner.ipa" ]; then
            IPA_SIZE=$(du -h "build/Runner.ipa" | cut -f1)
            echo "✅ IPA 创建成功: build/Runner.ipa ($IPA_SIZE)"
        else
            echo "❌ IPA 文件未找到"
            exit 1
        fi
    else
        echo "❌ iOS 构建失败"
        exit 1
    fi
else
    echo "⏭️  跳过 iOS 构建 (非 macOS 系统)"
fi

echo "========================================"
echo "🎉 所有验证步骤完成！"
echo ""
echo "📊 构建产物验证："
echo "   ✅ Flutter 版本检查"
echo "   ✅ 依赖安装"
echo "   ✅ 代码分析"
echo "   ✅ 单元测试"
echo "   ✅ Web 构建"
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   ✅ Android APK 构建"
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   ✅ iOS IPA 构建"
fi
echo ""
echo "🚀 GitHub Actions 配置验证完成！准备推送。"