//
//  SMSFilterExtension.swift
//  SMSFilterExtension
//
//  Created by SMS Grouping App
//

import NetworkExtension

class SMSFilterExtension: NEFilterExtensionProvider {
    
    override init() {
        super.init()
        print("SMSFilterExtension initialized")
    }
    
    override func beginRequest(with context: NEFilterContext) {
        guard let message = context.message else {
            context.close(with: .actionNone)
            return
        }
        
        // 获取短信内容
        let messageBody = message.body ?? ""
        let sender = message.sender ?? ""
        
        // 分析短信内容并分类
        let category = classifyMessage(messageBody, sender: sender)
        
        // 保存到 App Group 共享容器
        saveMessageToSharedContainer(body: messageBody, sender: sender, category: category)
        
        // 创建过滤操作
        let action = NEFilterAction()
        action.flag = .valid
        
        // 返回分类结果
        context.close(with: action)
        
        print("Message classified as: \(category) from sender: \(sender)")
    }
    
    // 短信分类逻辑
    private func classifyMessage(_ body: String, sender: String) -> String {
        let lowercasedBody = body.lowercased()
        let lowercasedSender = sender.lowercased()
        
        // 验证码识别
        if isVerificationCode(body) {
            return "verification"
        }
        
        // 金融相关
        if isFinanceRelated(lowercasedBody, lowercasedSender) {
            return "finance"
        }
        
        // 物流快递
        if isDeliveryRelated(lowercasedBody, lowercasedSender) {
            return "delivery"
        }
        
        // 推广营销
        if isPromotion(lowercasedBody, lowercasedSender) {
            return "promotion"
        }
        
        // 系统通知
        if isNotification(lowercasedBody, lowercasedSender) {
            return "notification"
        }
        
        // 默认为一般短信
        return "general"
    }
    
    // 验证码识别
    private func isVerificationCode(_ body: String) -> Bool {
        let patterns = [
            "验证码",
            "code",
            "otp",
            "动态密码",
            "校验码",
            "确认码"
        ]
        
        // 检查是否包含验证码关键词
        let hasKeyword = patterns.contains { body.lowercased().contains($0.lowercased()) }
        
        // 检查是否包含4-8位数字
        let numberPattern = "\\b\\d{4,8}\\b"
        let hasNumber = body.range(of: numberPattern, options: .regularExpression) != nil
        
        return hasKeyword && hasNumber
    }
    
    // 金融相关识别
    private func isFinanceRelated(_ body: String, _ sender: String) -> Bool {
        let keywords = [
            "银行", "信用卡", "还款", "账单", "余额", "交易",
            "转账", "存款", "贷款", "投资", "理财", "收入",
            "支出", "支付宝", "微信支付", "银联", "atm"
        ]
        
        return keywords.contains { body.contains($0) || sender.contains($0) }
    }
    
    // 物流快递识别
    private func isDeliveryRelated(_ body: String, _ sender: String) -> Bool {
        let keywords = [
            "快递", "物流", "配送", "取件", "签收",
            "发货", "送货", "ems", "顺丰", "圆通",
            "中通", "申通", "韵达", "邮政", "菜鸟"
        ]
        
        return keywords.contains { body.contains($0) || sender.contains($0) }
    }
    
    // 推广营销识别
    private func isPromotion(_ body: String, _ sender: String) -> Bool {
        let keywords = [
            "优惠", "促销", "折扣", "秒杀", "团购",
            "特价", "限时", "抢购", "优惠券", "积分",
            "会员", "活动", "礼品", "赠送"
        ]
        
        return keywords.contains { body.contains($0) }
    }
    
    // 系统通知识别
    private func isNotification(_ body: String, _ sender: String) -> Bool {
        let systemSenders = [
            "10086", "10010", "10000", "移动", "联通", "电信",
            "955xx", "银行", "政府", "社区"
        ]
        
        // 检查是否为系统发送者
        let isSystemSender = systemSenders.contains { sender.contains($0) }
        
        let notificationKeywords = [
            "通知", "提醒", "警告", "成功", "失败",
            "已开通", "已关闭", "已办理", "业务办理"
        ]
        
        let hasNotificationKeyword = notificationKeywords.contains { body.contains($0) }
        
        return isSystemSender || hasNotificationKeyword
    }
    
    // 保存短信到 App Group 共享容器
    private func saveMessageToSharedContainer(body: String, sender: String, category: String) {
        // App Group ID - 需要与主应用配置一致
        let appGroupID = "group.com.smsgrouping.app"
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("Failed to access shared defaults")
            return
        }
        
        // 创建消息数据
        let messageData: [String: Any] = [
            "id": UUID().uuidString,
            "content": body,
            "sender": sender,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 获取现有消息列表
        var messages = sharedDefaults.array(forKey: "classified_messages") as? [[String: Any]] ?? []
        
        // 添加新消息（最多保存最近1000条）
        messages.insert(messageData, at: 0)
        if messages.count > 1000 {
            messages = Array(messages.prefix(1000))
        }
        
        // 保存到共享容器
        sharedDefaults.set(messages, forKey: "classified_messages")
        
        // 更新分类统计
        updateCategoryStats(category: category, sharedDefaults: sharedDefaults)
        
        print("Message saved to shared container. Category: \(category)")
    }
    
    // 更新分类统计
    private func updateCategoryStats(category: String, sharedDefaults: UserDefaults) {
        var stats = sharedDefaults.dictionary(forKey: "category_stats") as? [String: Int] ?? [:]
        stats[category] = (stats[category] ?? 0) + 1
        sharedDefaults.set(stats, forKey: "category_stats")
    }
}