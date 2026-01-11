import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sms_group.dart';
import '../models/sms_message.dart';

class GroupService {
  static const String _groupsKey = 'sms_groups';
  static const String _messagesKey = 'sms_messages';
  
  final List<SmsGroup> _defaultGroups = [
    SmsGroup(
      id: 'bank',
      name: '银行短信',
      description: '银行、金融相关短信',
      keywords: ['银行', '转账', '余额', '账单', '还款', '存款', '贷款', '信用卡', '网银'],
      regexPatterns: [
        r'\d{16,19}', // 银行卡号
        r'交易|余额|账单|还款',
      ],
      color: '#4CAF50',
    ),
    SmsGroup(
      id: 'express',
      name: '快递短信',
      description: '快递、物流相关短信',
      keywords: ['快递', '物流', '取件', '签收', '派送', '驿站', '丰巢', '菜鸟'],
      regexPatterns: [
        r'\d{10,12}', // 快递单号
        r'取件码[:：]\s*\d+', // 取件码
        r'签收|派送|取件',
      ],
      color: '#2196F3',
    ),
    SmsGroup(
      id: 'work',
      name: '工作短信',
      description: '工作相关短信',
      keywords: ['会议', '通知', '工作', '项目', '报告', '紧急', '审批', '办公'],
      regexPatterns: [
        r'会议|通知|工作',
        r'\d{1,2}[:：]\d{2}', // 时间格式
      ],
      color: '#FF9800',
    ),
    SmsGroup(
      id: 'promotion',
      name: '促销短信',
      description: '营销、促销相关短信',
      keywords: ['优惠', '折扣', '促销', '特价', '限时', '抢购', '秒杀', '立减'],
      regexPatterns: [
        r'\d+元', // 价格
        r'\d+折', // 折扣
        r'优惠|促销|秒杀',
      ],
      color: '#E91E63',
    ),
    SmsGroup(
      id: 'service',
      name: '服务短信',
      description: '各类服务提醒短信',
      keywords: ['验证码', '密码', '登录', '安全', '提醒', '通知', '激活'],
      regexPatterns: [
        r'\d{4,8}', // 验证码
        r'验证码|密码|登录',
      ],
      color: '#9C27B0',
    ),
    SmsGroup(
      id: 'other',
      name: '其他短信',
      description: '未分类的其他短信',
      keywords: [],
      regexPatterns: [],
      color: '#9E9E9E',
    ),
  ];

  Future<List<SmsGroup>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);
    
    if (groupsJson != null) {
      final groupsList = json.decode(groupsJson) as List;
      return groupsList
          .map((json) => SmsGroup.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    
    // 首次使用，保存默认分组
    await saveGroups(_defaultGroups);
    return _defaultGroups;
  }

  Future<void> saveGroups(List<SmsGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = json.encode(groups.map((group) => group.toJson()).toList());
    await prefs.setString(_groupsKey, groupsJson);
  }

  Future<void> addGroup(SmsGroup group) async {
    final groups = await loadGroups();
    groups.add(group);
    await saveGroups(groups);
  }

  Future<void> updateGroup(SmsGroup updatedGroup) async {
    final groups = await loadGroups();
    final index = groups.indexWhere((group) => group.id == updatedGroup.id);
    if (index != -1) {
      groups[index] = updatedGroup;
      await saveGroups(groups);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await loadGroups();
    groups.removeWhere((group) => group.id == groupId);
    await saveGroups(groups);
  }

  Future<List<SmsMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_messagesKey);
    
    if (messagesJson != null) {
      final messagesList = json.decode(messagesJson) as List;
      return messagesList
          .map((json) => SmsMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    
    return [];
  }

  Future<void> saveMessages(List<SmsMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = json.encode(messages.map((msg) => msg.toJson()).toList());
    await prefs.setString(_messagesKey, messagesJson);
  }

  Future<void> addMessage(SmsMessage message) async {
    final messages = await loadMessages();
    messages.add(message);
    await saveMessages(messages);
  }

  // 对短信进行分类
  Future<String> categorizeMessage(String content, String sender) async {
    final groups = await loadGroups();
    
    for (var group in groups) {
      if (group.id != 'other' && group.matches(content, sender)) {
        return group.id;
      }
    }
    
    return 'other'; // 默认分类为"其他"
  }

  // 批量分类短信
  Future<void> categorizeAllMessages() async {
    final messages = await loadMessages();
    final groups = await loadGroups();
    
    for (var message in messages) {
      if (message.category == null || message.category!.isEmpty) {
        for (var group in groups) {
          if (group.id != 'other' && group.matches(message.content, message.sender)) {
            message.category = group.id;
            break;
          }
        }
        if (message.category == null || message.category!.isEmpty) {
          message.category = 'other';
        }
      }
    }
    
    await saveMessages(messages);
  }
}