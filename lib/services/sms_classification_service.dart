import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// iOS 短信分类服务
/// 仅在 iOS 平台上可用
class SMSClassificationService {
  static const MethodChannel _channel = MethodChannel('com.smsgrouping.app/sms');
  
  /// 检查是否在 iOS 平台
  static bool get isIOS => Platform.isIOS;
  
  /// 获取所有分类的短信
  static Future<List<Map<String, dynamic>>> getAllMessages() async {
    if (!isIOS) return [];
    
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllMessages');
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting all messages: $e');
      return [];
    }
  }
  
  /// 按分类获取分组的短信
  static Future<List<Map<String, dynamic>>> getCategoryGroups() async {
    if (!isIOS) return [];
    
    try {
      final List<dynamic> result = await _channel.invokeMethod('getCategoryGroups');
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting category groups: $e');
      return [];
    }
  }
  
  /// 获取分类统计信息
  static Future<Map<String, dynamic>> getCategoryStats() async {
    if (!isIOS) return {};
    
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getCategoryStats');
      return result.cast<String, dynamic>();
    } catch (e) {
      print('Error getting category stats: $e');
      return {};
    }
  }
  
  /// 删除指定短信
  static Future<bool> deleteMessage(String messageId) async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('deleteMessage', {
        'id': messageId,
      });
      return result;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
  
  /// 清空所有短信
  static Future<bool> clearAllMessages() async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('clearAllMessages');
      return result;
    } catch (e) {
      print('Error clearing all messages: $e');
      return false;
    }
  }
  
  /// 添加测试短信（仅用于开发测试）
  static Future<bool> addTestMessage({
    required String content,
    required String sender,
    required String category,
  }) async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('addTestMessage', {
        'content': content,
        'sender': sender,
        'category': category,
      });
      return result;
    } catch (e) {
      print('Error adding test message: $e');
      return false;
    }
  }
  
  /// 检查扩展状态
  static Future<bool> checkExtensionStatus() async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('checkExtensionStatus');
      return result;
    } catch (e) {
      print('Error checking extension status: $e');
      return false;
    }
  }
  
  /// 获取扩展设置指南
  static Future<String> getExtensionSetupInstructions() async {
    if (!isIOS) return '';
    
    try {
      final String result = await _channel.invokeMethod('getExtensionSetupInstructions');
      return result;
    } catch (e) {
      print('Error getting setup instructions: $e');
      return '';
    }
  }
}

/// 短信分类枚举
enum MessageCategory {
  verification('验证码', '#FF6B6B', '🔐'),
  finance('金融', '#4ECDC4', '💰'),
  delivery('物流', '#45B7D1', '📦'),
  notification('通知', '#FFA07A', '🔔'),
  promotion('推广', '#98D8C8', '🎯'),
  general('一般', '#95E1D3', '💬');
  
  final String displayName;
  final String color;
  final String icon;
  
  const MessageCategory(this.displayName, this.color, this.icon);
  
  static MessageCategory fromString(String category) {
    return MessageCategory.values.firstWhere(
      (cat) => cat.name == category,
      orElse: () => MessageCategory.general,
    );
  }
}