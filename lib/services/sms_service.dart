import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sms_message.dart';
import 'group_service.dart';

class SmsService {
  static const platform = MethodChannel('com.smsgrouping/sms');
  final GroupService _groupService = GroupService();

  // 请求SMS权限
  Future<bool> requestSmsPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.sms.status;
      if (status.isDenied) {
        final result = await Permission.sms.request();
        return result.isGranted;
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS不直接支持短信读取，返回true但使用模拟数据
      return true;
    }
    return false;
  }

  // 读取真实短信
  Future<List<SmsMessage>> readSms() async {
    final hasPermission = await requestSmsPermission();
    if (!hasPermission) {
      throw Exception('没有短信读取权限');
    }

    try {
      if (Platform.isAndroid) {
        // 尝试读取真实短信
        final List<dynamic> result = await platform.invokeMethod('readSms');
        return result.map((sms) => SmsMessage(
          id: sms['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          sender: sms['sender']?.toString() ?? '未知号码',
          content: sms['content']?.toString() ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            sms['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          ),
        )).toList();
      } else {
        // iOS使用模拟数据
        return _getMockSmsMessages();
      }
    } on PlatformException catch (e) {
      // 如果原生方法失败，返回模拟数据
      debugPrint('无法读取短信: ${e.message}');
      return _getMockSmsMessages();
    } catch (e) {
      // 返回模拟数据作为后备
      debugPrint('读取短信出错: $e');
      return _getMockSmsMessages();
    }
  }

  // 模拟短信数据（作为后备）
  List<SmsMessage> _getMockSmsMessages() {
    final now = DateTime.now();
    return [
      SmsMessage(
        id: '1',
        sender: '106980095500',
        content: '您的招商银行账户于01月10日18:30收入转账人民币5,000.00元，余额15,234.56元【招商银行】',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      SmsMessage(
        id: '2',
        sender: '菜鸟驿站',
        content: '您的快递已到达幸福小区菜鸟驿站，取件码：12-3456，请凭取件码取件，营业时间：9:00-21:00',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      SmsMessage(
        id: '3',
        sender: '顺丰速运',
        content: '顺丰速运提醒您：您的快件已到达北京朝阳营业点，派送员张三（电话：13800138000）正在派送，请保持电话畅通。',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      SmsMessage(
        id: '4',
        sender: '公司办公系统',
        content: '【会议通知】明天上午10:00在三楼会议室召开项目进度汇报会议，请准时参加。收到请回复。',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      SmsMessage(
        id: '5',
        sender: '京东',
        content: '【京东】您的订单已发货，京东物流正在为您派送。限时优惠：满99减20，明日生效！',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      SmsMessage(
        id: '6',
        sender: '10690999',
        content: '【安全中心】您的验证码是875643，10分钟内有效，请勿泄露给他人。',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      SmsMessage(
        id: '7',
        sender: '建设银行',
        content: '您尾号1234的建设银行信用卡1月份账单金额为人民币3,456.78元，到期还款日为01月25日。',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      SmsMessage(
        id: '8',
        sender: '天猫',
        content: '【天猫】双11返场优惠来啦！全场5折起，限时抢购，先到先得！点击链接进入会场：http://tmall.com/sale',
        timestamp: now.subtract(const Duration(days: 4)),
      ),
      SmsMessage(
        id: '9',
        sender: '公司人事部',
        content: '【紧急通知】由于天气原因，公司明天延迟2小时上班，请各位同事注意安全。',
        timestamp: now.subtract(const Duration(days: 5)),
      ),
      SmsMessage(
        id: '10',
        sender: '10086',
        content: '【中国移动】您好，您本月已使用流量8.5GB，剩余流量1.5GB。回复CXLL查询流量详情。',
        timestamp: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  // 导入并分类短信
  Future<List<SmsMessage>> importAndCategorizeSms() async {
    try {
      final messages = await readSms();
      
      // 为每条短信分类
      for (var message in messages) {
        message.category = await _groupService.categorizeMessage(
          message.content,
          message.sender,
        );
      }
      
      // 保存到本地存储
      await _groupService.saveMessages(messages);
      
      return messages;
    } catch (e) {
      throw Exception('导入短信失败: $e');
    }
  }

  // 刷新短信（重新读取和分类）
  Future<List<SmsMessage>> refreshSms() async {
    try {
      // 清空现有消息
      await _groupService.saveMessages([]);
      
      // 重新导入
      return await importAndCategorizeSms();
    } catch (e) {
      throw Exception('刷新短信失败: $e');
    }
  }

  // 获取短信统计信息
  Future<Map<String, int>> getSmsStatistics() async {
    final messages = await _groupService.loadMessages();
    final groups = await _groupService.loadGroups();
    
    final statistics = <String, int>{};
    for (var group in groups) {
      statistics[group.id] = messages
          .where((msg) => msg.category == group.id)
          .length;
    }
    
    return statistics;
  }
}