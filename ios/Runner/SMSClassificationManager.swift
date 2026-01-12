//
//  SMSClassificationManager.swift
//  Runner
//
//  Created by SMS Grouping App
//

import Foundation

class SMSClassificationManager: NSObject {
    
    static let shared = SMSClassificationManager()
    
    private let appGroupID = "group.com.smsgrouping.app"
    private let sharedDefaults: UserDefaults?
    
    // 短信分类枚举
    enum MessageCategory: String, CaseIterable {
        case verification = "验证码"
        case finance = "金融"
        case delivery = "物流"
        case notification = "通知"
        case promotion = "推广"
        case general = "一般"
        
        var color: String {
            switch self {
            case .verification: return "#FF6B6B"
            case .finance: return "#4ECDC4"
            case .delivery: return "#45B7D1"
            case .notification: return "#FFA07A"
            case .promotion: return "#98D8C8"
            case .general: return "#95E1D3"
            }
        }
        
        var icon: String {
            switch self {
            case .verification: return "🔐"
            case .finance: return "💰"
            case .delivery: return "📦"
            case .notification: return "🔔"
            case .promotion: return "🎯"
            case .general: return "💬"
            }
        }
    }
    
    // 短信消息结构
    struct SMSMessage {
        let id: String
        let content: String
        let sender: String
        let category: String
        let timestamp: Double
        
        var date: Date {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        init?(dictionary: [String: Any]) {
            guard let id = dictionary["id"] as? String,
                  let content = dictionary["content"] as? String,
                  let sender = dictionary["sender"] as? String,
                  let category = dictionary["category"] as? String,
                  let timestamp = dictionary["timestamp"] as? Double else {
                return nil
            }
            
            self.id = id
            self.content = content
            self.sender = sender
            self.category = category
            self.timestamp = timestamp
        }
        
        func toDictionary() -> [String: Any] {
            return [
                "id": id,
                "content": content,
                "sender": sender,
                "category": category,
                "timestamp": timestamp,
                "date": date.timeIntervalSince1970
            ]
        }
    }
    
    private override init() {
        // 初始化 App Group 共享容器
        self.sharedDefaults = UserDefaults(suiteName: appGroupID)
        super.init()
        
        // 添加示例数据（如果为空）
        addSampleDataIfEmpty()
    }
    
    // 获取所有分类的短信
    func getAllMessages() -> [[String: Any]] {
        guard let messages = sharedDefaults?.array(forKey: "classified_messages") as? [[String: Any]] else {
            return []
        }
        
        return messages.compactMap { message in
            if let smsMessage = SMSMessage(dictionary: message) {
                return smsMessage.toDictionary()
            }
            return nil
        }
    }
    
    // 按分类获取短信
    func getMessagesByCategory(_ category: String) -> [[String: Any]] {
        let allMessages = getAllMessages()
        return allMessages.filter { message in
            guard let messageCategory = message["category"] as? String else { return false }
            return messageCategory == category
        }
    }
    
    // 获取分组统计
    func getCategoryGroups() -> [[String: Any]] {
        let allMessages = getAllMessages()
        
        // 按分类分组
        let groupedMessages = Dictionary(grouping: allMessages) { message -> String in
            return (message["category"] as? String) ?? MessageCategory.general.rawValue
        }
        
        // 构建结果
        return MessageCategory.allCases.map { category in
            let messages = groupedMessages[category.rawValue] ?? []
            return [
                "category": category.rawValue,
                "color": category.color,
                "icon": category.icon,
                "count": messages.count,
                "messages": messages
            ]
        }
    }
    
    // 获取分类统计
    func getCategoryStats() -> [String: Any] {
        guard let stats = sharedDefaults?.dictionary(forKey: "category_stats") as? [String: Int] else {
            return [:]
        }
        
        var result: [String: Any] = [:]
        for (category, count) in stats {
            result[category] = [
                "count": count,
                "color": MessageCategory(rawValue: category)?.color ?? "#95E1D3",
                "icon": MessageCategory(rawValue: category)?.icon ?? "💬"
            ]
        }
        
        return result
    }
    
    // 清空所有消息
    func clearAllMessages() {
        sharedDefaults?.removeObject(forKey: "classified_messages")
        sharedDefaults?.removeObject(forKey: "category_stats")
    }
    
    // 删除特定消息
    func deleteMessage(withId id: String) {
        guard var messages = sharedDefaults?.array(forKey: "classified_messages") as? [[String: Any]] else {
            return
        }
        
        messages.removeAll { message in
            return (message["id"] as? String) == id
        }
        
        sharedDefaults?.set(messages, forKey: "classified_messages")
    }
    
    // 手动添加消息（用于测试）
    func addTestMessage(content: String, sender: String, category: String) {
        let messageData: [String: Any] = [
            "id": UUID().uuidString,
            "content": content,
            "sender": sender,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        var messages = sharedDefaults?.array(forKey: "classified_messages") as? [[String: Any]] ?? []
        messages.insert(messageData, at: 0)
        
        // 限制保存数量
        if messages.count > 1000 {
            messages = Array(messages.prefix(1000))
        }
        
        sharedDefaults?.set(messages, forKey: "classified_messages")
        
        // 更新统计
        var stats = sharedDefaults?.dictionary(forKey: "category_stats") as? [String: Int] ?? [:]
        stats[category] = (stats[category] ?? 0) + 1
        sharedDefaults?.set(stats, forKey: "category_stats")
    }
    
    // 添加示例数据
    private func addSampleDataIfEmpty() {
        guard let messages = sharedDefaults?.array(forKey: "classified_messages") as? [[String: Any]],
              !messages.isEmpty else {
            // 添加示例数据
            addTestMessage(content: "您的验证码是: 123456", sender: "10690000", category: MessageCategory.verification.rawValue)
            addTestMessage(content: "招商银行:您于2025年1月12日消费人民币888.88元", sender: "95555", category: MessageCategory.finance.rawValue)
            addTestMessage(content: "您的快递已到达菜鸟驿站，请凭取件码12-34-56取件", sender: "菜鸟驿站", category: MessageCategory.delivery.rawValue)
            addTestMessage(content: "系统通知：您的账户已成功开通，感谢您的使用", sender: "10086", category: MessageCategory.notification.rawValue)
            addTestMessage(content: "限时优惠！全场商品5折起，点击查看详情", sender: "电商平台", category: MessageCategory.promotion.rawValue)
            return
        }
    }
    
    // 检查扩展权限状态
    func checkExtensionStatus() -> Bool {
        // 检查是否有分类数据，如果有则说明扩展正在工作
        guard let messages = sharedDefaults?.array(forKey: "classified_messages") as? [[String: Any]] else {
            return false
        }
        return !messages.isEmpty
    }
    
    // 获取扩展设置指南
    func getExtensionSetupInstructions() -> String {
        return """
        短信分类扩展设置指南：
        
        1. 打开 iPhone 设置
        2. 向下滚动找到 "短信" 选项
        3. 点击进入，选择 "未知与垃圾信息"
        4. 找到 "短信过滤" 部分
        5. 启用 "SMS Grouping App"
        6. 返回应用即可看到分类效果
        
        注意：只有启用短信过滤扩展后，应用才能自动分类短信。
        """
    }
}