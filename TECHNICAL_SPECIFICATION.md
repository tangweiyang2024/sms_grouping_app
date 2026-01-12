# iOS 短信分类应用技术方案

## 🎯 项目目标

开发一个 iOS 应用，利用 iOS MessageFilter Extension 实现短信自动分类功能，解决用户无法在 iOS 上直接读取短信的限制。

## 📋 技术架构

### 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                   iOS 短信分类系统架构                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐      ┌──────────────────┐              │
│  │   系统短信应用   │──────│ SMS Filter       │              │
│  │                 │      │ Extension        │              │
│  └─────────────────┘      └──────────────────┘              │
│                                       │                       │
│                                       ▼                       │
│                          ┌─────────────────────┐              │
│                          │   App Group        │              │
│                          │   Shared Data      │              │
│                          │   (UserDefaults)   │              │
│                          └─────────────────────┘              │
│                                       │                       │
│                                       ▼                       │
│  ┌─────────────────┐      ┌──────────────────┐              │
│  │ Flutter 主应用  │──────│   iOS 原生层     │              │
│  │   (UI 展示)     │      │ (Method Channel) │              │
│  └─────────────────┘      └──────────────────┘              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 数据流程

1. **短信接收阶段**
   ```
   用户收到短信 → iOS 系统调用 SMSFilter Extension 
   → Extension 分析短信内容 → 保存到 App Group
   ```

2. **数据处理阶段**
   ```
   Extension 分析短信内容 → 基于规则分类 
   → 保存分类结果 → 更新统计信息
   ```

3. **UI 展示阶段**
   ```
   Flutter 应用启动 → 通过 Method Channel 请求数据 
   → iOS 层读取 App Group 数据 → 返回给 Flutter 展示
   ```

## 🔧 核心组件

### 1. MessageFilter Extension

**功能职责:**
- 拦截系统短信
- 分析短信内容
- 自动分类短信
- 保存分类结果

**技术实现:**
```swift
class SMSFilterExtension: NEFilterExtensionProvider {
    override func beginRequest(with context: NEFilterContext) {
        // 1. 获取短信内容
        // 2. 分析并分类
        // 3. 保存到 App Group
        // 4. 返回过滤结果
    }
}
```

### 2. iOS 原生数据管理层

**功能职责:**
- 管理 App Group 数据
- 提供 Flutter Method Channel 接口
- 数据统计和分析
- 测试数据生成

**技术实现:**
```swift
class SMSClassificationManager {
    // 数据管理
    func getAllMessages() -> [[String: Any]]
    func getCategoryGroups() -> [[String: Any]]
    func getCategoryStats() -> [String: Any]
    
    // 数据操作
    func deleteMessage(withId id: String)
    func clearAllMessages()
    func addTestMessage(...)
}
```

### 3. Flutter 服务层

**功能职责:**
- 封装 Method Channel 调用
- 提供类型安全的接口
- 平台检测和兼容性处理

**技术实现:**
```dart
class SMSClassificationService {
  // 数据获取
  static Future<List<Map<String, dynamic>>> getAllMessages()
  static Future<List<Map<String, dynamic>>> getCategoryGroups()
  
  // 数据操作
  static Future<bool> deleteMessage(String messageId)
  static Future<bool> addTestMessage(...)
}
```

### 4. Flutter UI 层

**功能职责:**
- 展示分类结果
- 用户交互处理
- 设置指导
- 数据刷新

**界面设计:**
- 分类卡片列表
- 短信详情展示
- 设置指南对话框
- 下拉刷新功能

## 📊 短信分类策略

### 分类规则

```swift
enum MessageCategory {
    case verification = "验证码"    // 验证码短信
    case finance = "金融"          // 银行、支付相关
    case delivery = "物流"         // 快递、配送
    case notification = "通知"     // 系统通知
    case promotion = "推广"        // 营销推广
    case general = "一般"          // 普通短信
}
```

### 分类算法

#### 1. 验证码识别
- 关键词: "验证码", "code", "otp", "动态密码"
- 数字模式: 4-8位连续数字
- 优先级: 最高

#### 2. 金融相关
- 关键词: "银行", "信用卡", "还款", "转账"
- 发送者: 银行号码、支付平台

#### 3. 物流快递
- 关键词: "快递", "物流", "配送", "取件"
- 发送者: 快递公司、物流平台

#### 4. 系统通知
- 发送者: 系统号码 (10086, 10010, 10000)
- 关键词: "通知", "提醒", "业务办理"

## 🛠️ 开发实现步骤

### Phase 1: 基础架构 ✅
- [x] 创建 MessageFilter Extension
- [x] 配置 App Group
- [x] 实现数据管理类
- [x] 建立 Flutter Method Channel

### Phase 2: 核心功能 ✅
- [x] 实现短信分类逻辑
- [x] 数据存储和读取
- [x] Flutter UI 开发
- [x] 错误处理和用户提示

### Phase 3: 优化完善 🔄
- [ ] 性能优化
- [ ] 用户体验改进
- [ ] 测试和调试
- [ ] 文档完善

## ⚠️ 技术限制和解决方案

### 1. Extension 运行限制
**限制:** Extension 运行时间有限 (约 20 秒)
**解决:** 优化算法，快速处理，避免复杂计算

### 2. 内存限制
**限制:** Extension 内存使用受限
**解决:** 及时释放资源，限制数据存储量

### 3. 用户授权
**限制:** 需要用户手动启用 Extension
**解决:** 提供清晰的设置指南和用户引导

### 4. 实时性限制
**限制:** Extension 和主应用数据同步有延迟
**解决:** 提供手动刷新功能，设置合理的刷新策略

## 🔐 安全和隐私

### 数据保护
1. **本地存储**: 所有数据仅存储在用户设备
2. **加密传输**: 使用 App Group 的安全机制
3. **最小权限**: 仅请求必要的权限

### 隐私保护
1. **数据最小化**: 仅存储分类必需的信息
2. **用户控制**: 用户可删除所有数据
3. **透明度**: 明确说明数据处理方式

## 📱 App Store 审核策略

### 功能说明
1. **主要功能**: 短信分类和管理
2. **Extension 用途**: 提供短信过滤功能
3. **数据处理**: 本地处理，不上传服务器

### 隐私政策
1. **数据使用**: 仅用于短信分类
2. **数据存储**: 本地存储，用户控制
3. **权限说明**: 详细说明权限用途

### 测试准备
1. **功能演示**: 准备完整的功能演示
2. **测试数据**: 提供测试用的短信数据
3. **审核文档**: 准备详细的说明文档

## 🚀 后续优化方向

### 功能扩展
1. **自定义分类**: 允许用户自定义分类规则
2. **智能学习**: 基于用户行为优化分类
3. **统计报表**: 提供短信使用统计分析

### 用户体验
1. **快捷操作**: 添加快捷回复、转发功能
2. **搜索过滤**: 支持关键词搜索和过滤
3. **主题定制**: 提供多种界面主题

### 技术优化
1. **性能提升**: 优化 Extension 性能
2. **电池优化**: 减少电量消耗
3. **存储优化**: 优化数据存储方式

这个技术方案充分利用了 iOS 的现有能力，在系统限制内实现了短信分类功能，为用户提供了便利的短信管理体验。