#!/bin/bash

# iOS 项目配置脚本
# 用于配置 iOS 打包所需的各项设置

set -e  # 遇到错误时退出

echo "🚀 开始配置 iOS 项目..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查当前目录
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}错误: 请在 Flutter 项目根目录运行此脚本${NC}"
    exit 1
fi

echo "📱 检查 iOS 项目结构..."

# 检查 iOS 目录
if [ ! -d "ios" ]; then
    echo -e "${RED}错误: 未找到 ios 目录${NC}"
    exit 1
fi

# 1. 配置 App Groups
echo "🔧 配置 App Groups..."
cat > ios/AppGroups.xcconfig << 'EOF'
// App Groups Configuration
// 用于 iOS MessageFilter Extension 和主应用之间的数据共享

#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"

// App Group Configuration
APP_GROUP_ID = group.com.smsgrouping.app

// 开发配置
DEVELOPMENT_TEAM = YOUR_TEAM_ID
PRODUCT_BUNDLE_IDENTIFIER = com.smsgrouping.app
CODE_SIGN_STYLE = Automatic

// Extension 配置
EXTENSION_BUNDLE_IDENTIFIER = com.smsgrouping.app.SMSFilterExtension
EOF

echo -e "${GREEN}✅ App Groups 配置完成${NC}"

# 2. 创建 MessageFilter Extension 配置
echo "🔧 创建 MessageFilter Extension 配置..."

# 创建 Extension 目录结构
mkdir -p ios/SMSFilterExtension

# 创建 Extension 的 Info.plist
cat > ios/SMSFilterExtension/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>SMS Filter</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.messagefilter.extension</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).SMSFilterExtension</string>
    </dict>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ MessageFilter Extension 配置完成${NC}"

# 3. 创建构建配置脚本
echo "🔧 创建构建配置脚本..."

cat > ios/scripts/configure_build.sh << 'EOF'
#!/bin/bash

# iOS 构建配置脚本

set -e

echo "🔧 配置 iOS 构建设置..."

# 检查是否安装了 CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods 未安装，正在安装..."
    sudo gem install cocoapods
fi

# 安装依赖
echo "📦 安装 CocoaPods 依赖..."
cd ios
pod install || pod install --repo-update
cd ..

echo "✅ iOS 构建配置完成"

# 显示配置信息
echo "📋 当前配置:"
echo "- Flutter 版本: $(flutter --version | head -n 1)"
echo "- CocoaPods 版本: $(pod --version)"
echo "- Xcode 版本: $(xcodebuild -version | head -n 1)"

# 检查项目结构
echo "📂 iOS 项目结构:"
ls -la ios/

EOF

chmod +x ios/scripts/configure_build.sh

echo -e "${GREEN}✅ 构建配置脚本创建完成${NC}"

# 4. 创建本地开发环境配置
echo "🔧 创建本地开发配置..."

cat > ios/LocalConfig.xcconfig << 'EOF'
// 本地开发配置
// 请根据你的开发环境修改这些值

// 你的 Apple Developer Team ID
// 可以在 https://developer.apple.com/account/#/membership/ 找到
DEVELOPMENT_TEAM = YOUR_TEAM_ID

// Bundle Identifier
PRODUCT_BUNDLE_IDENTIFIER = com.smsgrouping.app
EXTENSION_BUNDLE_IDENTIFIER = com.smsgrouping.app.SMSFilterExtension

// App Group ID
APP_GROUP_ID = group.com.smsgrouping.app

// 代码签名配置
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Automatic

// 开发配置
IPHONEOS_DEPLOYMENT_TARGET = 12.0

// 启用功能
ENABLE_BITCODE = NO
SWIFT_VERSION = 5.0
EOF

echo -e "${GREEN}✅ 本地开发配置创建完成${NC}"

# 5. 创建项目配置说明
cat > ios/README_CONFIG.md << 'EOF'
# iOS 项目配置说明

## 📋 快速开始

### 1. 本地开发配置

1. **安装 CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

2. **安装依赖**
   ```bash
   cd ios
   pod install
   ```

3. **配置开发环境**
   - 打开 `Runner.xcworkspace`
   - 在 Xcode 中配置你的 Team ID
   - 配置 Bundle Identifier 和 App Groups

### 2. App Groups 配置

1. **在 Xcode 中添加 App Groups**
   - 选择 Runner target
   - 点击 "Signing & Capabilities"
   - 添加 "App Groups" capability
   - 添加 App Group: `group.com.smsgrouping.app`

2. **为 Extension 添加 App Groups**
   - 选择 SMSFilterExtension target
   - 添加相同的 App Group

### 3. MessageFilter Extension 配置

1. **添加 Extension Target**
   - 在 Xcode 中: File → New → Target
   - 选择 "App Extension" → "Message Filter Extension"
   - 设置 Product Name: `SMSFilterExtension`

2. **配置 Extension**
   - Bundle Identifier: `com.smsgrouping.app.SMSFilterExtension`
   - 添加 App Groups capability
   - 将 `SMSFilterExtension.swift` 添加到项目

### 4. 签名和证书

#### 开发环境
- 使用你的 Apple ID 作为开发团队
- Xcode 会自动管理开发证书

#### 发布环境
- 需要 Apple Developer 账号
- 配置分发证书和配置文件
- 参考 `ios-certificates-setup.md`

## 🛠️ 开发工作流

### 日常开发
```bash
# 1. 拉取最新代码
git pull

# 2. 安装/更新依赖
cd ios && pod install && cd ..

# 3. 运行 Flutter 应用
flutter run

# 4. 测试 iOS 功能
flutter run -d ios
```

### 构建和测试
```bash
# 开发版本构建
flutter build ios --debug

# 发布版本构建
flutter build ios --release

# 无签名构建（用于测试）
flutter build ios --release --no-codesign
```

## 🔧 常见问题

### CocoaPods 问题
```bash
# 清理缓存
pod cache clean --all

# 重新安装
rm -rf Pods Podfile.lock
pod install
```

### 签名问题
```bash
# 清理构建缓存
flutter clean
cd ios && rm -rf build && cd ..

# 重新构建
flutter build ios
```

### Extension 不工作
1. 检查 App Groups 配置
2. 确认 Extension 已启用
3. 查看系统日志排查问题

## 📱 设备测试

### 真机测试
1. 连接 iOS 设备
2. 在 Xcode 中配置开发团队
3. 运行应用
4. 在设置中启用短信过滤扩展

### 模拟器测试
1. 选择 iOS 模拟器
2. 运行应用
3. 添加测试数据验证功能

## 🚀 发布准备

1. **代码审查**
   - 检查代码质量
   - 运行测试
   - 更新文档

2. **版本更新**
   - 更新 `pubspec.yaml` 中的版本号
   - 更新 `Info.plist` 中的版本信息

3. **构建发布版本**
   - 配置发布证书
   - 运行 GitHub Actions 工作流
   - 下载生成的 IPA 文件

4. **App Store 发布**
   - 在 App Store Connect 中创建新版本
   - 上传 IPA 文件
   - 填写版本信息和截图
   - 提交审核

## 🔐 安全注意事项

1. **证书管理**
   - 不要将证书提交到仓库
   - 使用 GitHub Secrets 存储敏感信息
   - 定期更新证书

2. **代码签名**
   - 开发环境使用自动签名
   - 发布环境使用手动签名
   - 妥善保管私钥和密码

3. **数据隐私**
   - 遵循 Apple 隐私政策
   - 正确处理用户数据
   - 提供隐私政策说明

这个配置确保了你的 iOS 项目可以顺利构建和发布！