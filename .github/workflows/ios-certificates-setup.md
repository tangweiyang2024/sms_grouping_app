# iOS 证书和签名配置指南

## 📱 GitHub Actions iOS 打包配置

本指南说明如何为 GitHub Actions 配置 iOS 证书和签名，实现自动化 iOS 应用打包。

## 🔧 配置步骤

### 1. 准备 iOS 开发者账号

1. **加入 Apple Developer Program**
   - 访问 https://developer.apple.com/programs/
   - 注册并付费加入开发者计划

2. **创建 App ID**
   ```bash
   # 登录 Apple Developer Console
   # 创建 App ID: com.smsgrouping.app
   ```

3. **创建证书和配置文件**
   - 开发证书 (Development Certificate)
   - 分发证书 (Distribution Certificate)
   - 配置文件 (Provisioning Profiles)

### 2. 导出证书和配置文件

#### 2.1 导出 .p12 证书

```bash
# 在 Mac 钥匙串访问中
1. 找到你的 iOS 开发证书
2. 右键点击 → 导出
3. 格式选择 "Personal Information Exchange (.p12)"
4. 设置密码（记住这个密码）
5. 保存为 ios_certificates.p12
```

#### 2.2 下载配置文件

```bash
# 从 Apple Developer Console 下载
1. 进入 Provisioning Profiles 部分
2. 下载开发配置文件
3. 下载分发配置文件
4. 重命名为:
   - development_profile.mobileprovision
   - appstore_profile.mobileprovision
```

### 3. 配置 GitHub Secrets

在 GitHub 仓库中添加以下 Secrets:

```bash
# 在 GitHub 仓库设置中
Settings → Secrets and variables → Actions → New repository secret

# 添加以下 Secrets:

1. IOS_CERTIFICATES_P12
   - 内容: ios_certificates.p12 的 base64 编码
   - 生成命令: base64 -i ios_certificates.p12 | pbcopy

2. IOS_CERTIFICATES_PASSWORD
   - 内容: .p12 证书的密码

3. IOS_DEVELOPMENT_PROVISIONING_PROFILE
   - 内容: development_profile.mobileprovision 的 base64 编码

4. IOS_APPSTORE_PROVISIONING_PROFILE
   - 内容: appstore_profile.mobileprovision 的 base64 编码

5. IOS_KEYCHAIN_PASSWORD
   - 内容: 随机生成的钥匙串密码
```

#### 命令示例

```bash
# 生成 base64 编码的证书
base64 -i ios_certificates.p12 > certificates_base64.txt
base64 -i development_profile.mobileprovision > dev_profile_base64.txt
base64 -i appstore_profile.mobileprovision > appstore_profile_base64.txt

# 复制内容到 GitHub Secrets
cat certificates_base64.txt | pbcopy
```

### 4. 更新 GitHub Actions 工作流

在 `.github/workflows/ios-build.yml` 中添加证书导入步骤:

```yaml
- name: Import Certificates
  if: github.event.inputs.release_type == 'release'
  run: |
    # 创建临时目录
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    mkdir -p certificates
    
    # 导入证书
    echo "${{ secrets.IOS_CERTIFICATES_P12 }}" | base64 -d > certificates/certificates.p12
    
    # 导入配置文件
    echo "${{ secrets.IOS_DEVELOPMENT_PROVISIONING_PROFILE }}" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/development.mobileprovision
    echo "${{ secrets.IOS_APPSTORE_PROVISIONING_PROFILE }}" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/appstore.mobileprovision
    
    # 创建钥匙串
    security create-keychain -p "${{ secrets.IOS_KEYCHAIN_PASSWORD }}" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "${{ secrets.IOS_KEYCHAIN_PASSWORD }}" build.keychain
    security import certificates/certificates.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATES_PASSWORD }}" -T /usr/bin/codesign
    
    # 设置钥匙串设置
    security set-key-partition-list -S apple-tool:,apple: -s -k "${{ secrets.IOS_KEYCHAIN_PASSWORD }}" build.keychain
    
    # 验证证书
    security find-identity -v build.keychain
```

### 5. 更新 iOS 项目配置

#### 5.1 更新 Bundle Identifier

在 `ios/Runner.xcodeproj/project.pbxproj` 中确保:

```
PRODUCT_BUNDLE_IDENTIFIER = com.smsgrouping.app;
CODE_SIGN_STYLE = Automatic;
DEVELOPMENT_TEAM = YOUR_TEAM_ID;
```

#### 5.2 配置签名

在 `ios/Runner.xcodeproj/project.pbxproj` 中:

```xml
<!-- 开发配置 -->
DEVELOPMENT_TEAM = YOUR_TEAM_ID;
CODE_SIGN_IDENTITY = "Apple Development";
PROVISIONING_PROFILE_SPECIFIER = "development";

<!-- 发布配置 -->
DEVELOPMENT_TEAM = YOUR_TEAM_ID;
CODE_SIGN_IDENTITY = "Apple Distribution";
PROVISIONING_PROFILE_SPECIFIER = "appstore";
```

## 🚀 使用工作流

### 手动触发构建

1. 进入 GitHub Actions 页面
2. 选择 "iOS Build - SMS Grouping App"
3. 点击 "Run workflow"
4. 选择构建类型:
   - `development`: 开发版本（无签名）
   - `release`: 发布版本（带签名）

### 自动触发构建

当以下文件有变化时自动触发:
- `lib/**` - Flutter 代码
- `ios/**` - iOS 配置
- `pubspec.yaml` - 依赖配置

## 📋 验证清单

### 开发环境
- [ ] Xcode 已安装
- [ ] Flutter 已配置
- [ ] CocoaPods 已安装
- [ ] 开发者账号已注册

### 证书配置
- [ ] App ID 已创建
- [ ] 证书已导出 (.p12)
- [ ] 配置文件已下载
- [ ] GitHub Secrets 已配置

### 构建测试
- [ ] 本地构建成功
- [ ] GitHub Actions 构建成功
- [ ] IPA 文件可下载
- [ ] 应用可在设备上安装

## 🔐 安全注意事项

1. **证书安全**
   - 不要将 .p12 文件提交到仓库
   - 定期更新证书
   - 使用强密码保护

2. **Secrets 管理**
   - 定期轮换 Secrets
   - 限制访问权限
   - 监控使用情况

3. **配置文件**
   - 使用合适的配置文件类型
   - 定期更新配置文件
   - 监控过期时间

## 🐛 常见问题

### 证书导入失败
**问题**: `security: SecKeychainItemImport: The specified item already exists in the keychain.`

**解决方案**:
```bash
# 清理现有钥匙串
security delete-keychain build.keychain
# 重新运行导入
```

### 配置文件不匹配
**问题**: `No provisioning profile found for specified bundle identifier`

**解决方案**:
1. 检查 Bundle Identifier 是否匹配
2. 确认配置文件类型正确
3. 重新下载配置文件

### 签名失败
**问题**: `Code signing is required for product type 'Application' in SDK 'iOS'`

**解决方案**:
1. 确认证书导入成功
2. 检查团队 ID 配置
3. 验证配置文件有效

## 📱 发布到 App Store

### 1. 构建发布版本
```bash
# 触发 release 构建
# 下载生成的 IPA 文件
```

### 2. 上传到 App Store Connect
```bash
# 使用 Transporter 上传
# 或使用命令行工具:
xcrun altool --upload-app --type ios --file Runner.ipa --username "your@email.com" --password "app-specific-password"
```

### 3. 在 App Store Connect 中完成发布
1. 创建新版本
2. 填写版本信息
3. 上传截图
4. 提交审核

通过这个配置，你就可以实现完全自动化的 iOS 应用打包和发布流程！