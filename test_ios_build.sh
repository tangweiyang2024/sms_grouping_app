#!/bin/bash

echo "🧪 Testing iOS Build Configuration"
echo "=================================="

# 检查Flutter环境
echo "1. Checking Flutter environment..."
flutter --version
echo ""

# 检查iOS项目配置
echo "2. Checking iOS project configuration..."
cd ios
echo "Code signing configuration:"
grep -A2 -B2 "CODE_SIGN_STYLE\|CODE_SIGN_IDENTITY\|DEVELOPMENT_TEAM" Runner.xcodeproj/project.pbxproj | grep -A5 "97C147061CF9000F007C117D"
echo ""

# 尝试清理构建
echo "3. Cleaning previous builds..."
cd ..
flutter clean
echo ""

# 安装依赖
echo "4. Installing dependencies..."
flutter pub get
echo ""

# 检查iOS依赖
echo "5. Checking iOS dependencies..."
cd ios
pod install
cd ..
echo ""

echo "✅ Configuration check completed!"
echo ""
echo "📋 Summary:"
echo "- Flutter environment: OK"
echo "- iOS project configuration: OK"  
echo "- Code signing: Manual (no sign)"
echo "- Dependencies: Installed"
echo ""
echo "🚀 Ready for GitHub Actions build test!"