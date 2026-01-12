# iOS 短信分类功能配置指南

## 📱 功能概述

本应用使用 iOS 的 MessageFilter Extension 实现短信自动分类功能。

## 🛠️ 开发环境配置

### 1. Xcode 项目配置

1. **打开 Xcode 项目**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **添加 App Group Capability**
   
   a. 选择 Runner target
   
   b. 点击 "Signing & Capabilities" 标签
   
   c. 点击 "+ Capability" 按钮
   
   d. 添加 "App Groups" capability
   
   e. 创建新的 App Group: `group.com.smsgrouping.app`
   
   f. 确保 App Group 选中且启用

3. **配置 MessageFilter Extension**
   
   a. 在 Xcode 中添加新 Target
   
   b. 选择 "App Extension" → "Message Filter Extension"
   
   c. 设置 Product Name: `SMSFilterExtension`
   
   d. 配置 Bundle Identifier: `com.smsgrouping.app.SMSFilterExtension`
   
   e. 为 Extension 也添加相同的 App Group capability

4. **添加文件到项目**
   
   a. 将以下文件拖入对应的 Xcode 项目组:
      - `SMSFilterExtension/SMSFilterExtension.swift`
      - `SMSFilterExtension/Info.plist`
      - `Runner/SMSClassificationManager.swift`

### 2. 权限配置

在 `ios/Runner/Info.plist` 中添加:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.messagefilter.extension</string>
</dict>
```

### 3. Bundle Identifier 配置

确保以下 Bundle Identifiers 正确设置:

**主应用 (Runner):**
- Bundle Identifier: `com.smsgrouping.app`

**Extension (SMSFilterExtension):**
- Bundle Identifier: `com.smsgrouping.app.SMSFilterExtension`

**App Group ID:**
- Group ID: `group.com.smsgrouping.app`

## 📱 用户端配置

### 启用短信过滤扩展的步骤

1. **打开设置**
   - iPhone 设置应用

2. **导航到短信设置**
   - 设置 → 短信 → 未知与垃圾信息

3. **启用扩展**
   - 找到 "短信过滤" 部分
   - 启用 "SMS Grouping App"

4. **验证功能**
   - 返回应用，检查是否能看到分类的短信
   - 发送测试短信验证分类效果

## 🔧 开发调试

### 1. 查看 Extension 日志

```bash
# 在 Xcode 中运行 Extension target
# 使用 Console.app 查看日志
log stream --predicate 'process == "SMSFilterExtension"'
```

### 2. 调试 App Group 通信

在 Xcode 中使用 Console.app 查看共享数据:
```bash
# 查看共享容器中的数据
defaults read group.com.smsgrouping.app
```

### 3. 测试数据同步

在应用中添加测试短信:
```dart
await SMSClassificationService.addTestMessage(
  content: '您的验证码是: 123456',
  sender: '10690000',
  category: 'verification',
);
```

## 📋 功能验证清单

### 基础功能
- [ ] App Group 正确配置
- [ ] Extension 成功编译
- [ ] 主应用可以读取 Extension 写入的数据
- [ ] 短信分类逻辑正确工作

### 用户体验
- [ ] 用户可以成功启用 Extension
- [ ] 短信自动分类显示正确
- [ ] 分类界面正常显示
- [ ] 设置指南清晰易懂

### 性能测试
- [ ] Extension 处理时间不超过限制
- [ ] 内存使用合理
- [ ] 电池消耗正常

## 🚀 常见问题解决

### 问题1: Extension 无法启用
**解决方案:**
1. 检查 Bundle Identifier 配置
2. 确保 App Group ID 一致
3. 重新编译安装应用

### 问题2: 数据不同步
**解决方案:**
1. 检查 App Group 配置
2. 验证 Extension 权限
3. 重启应用测试

### 问题3: 分类不准确
**解决方案:**
1. 调整分类关键词
2. 优化分类算法
3. 添加更多规则

## 📊 性能优化建议

1. **Extension 性能**
   - 限制处理时间
   - 优化内存使用
   - 使用高效算法

2. **数据存储**
   - 定期清理过期数据
   - 限制存储数量
   - 压缩存储格式

3. **用户体验**
   - 提供清晰的反馈
   - 优化加载速度
   - 减少电量消耗

## 🔐 安全考虑

1. **数据隐私**
   - 仅存储必要的短信信息
   - 不上传敏感数据
   - 遵循隐私政策

2. **权限管理**
   - 最小化权限请求
   - 明确说明权限用途
   - 提供权限说明

## 📱 App Store 审核注意事项

1. **隐私政策**
   - 明确说明短信处理方式
   - 说明数据存储位置
   - 提供隐私政策链接

2. **功能说明**
   - 详细说明短信分类功能
   - 提供使用说明
   - 说明 Extension 作用

3. **审核测试**
   - 确保功能稳定
   - 提供测试账号
   - 准备审核说明文档