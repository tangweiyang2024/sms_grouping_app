import 'package:flutter/material.dart';
import '../models/sms_group.dart';
import '../models/sms_message.dart';
import '../services/group_service.dart';
import '../services/sms_service.dart';
import 'group_detail_screen.dart';
import 'group_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GroupService _groupService = GroupService();
  final SmsService _smsService = SmsService();
  
  List<SmsGroup> _groups = [];
  List<SmsMessage> _allMessages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 加载分组
      final groups = await _groupService.loadGroups();
      
      // 加载已保存的短信
      final messages = await _groupService.loadMessages();
      
      setState(() {
        _groups = groups;
        _allMessages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importSms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 显示调试信息
      debugPrint('开始导入短信...');
      debugPrint('运行平台: ${Theme.of(context).platform}');

      final messages = await _smsService.importAndCategorizeSms();
      
      debugPrint('短信导入完成，共 ${messages.length} 条');
      
      setState(() {
        _allMessages = messages;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 ${messages.length} 条短信'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorText = e.toString();
      debugPrint('短信导入失败: $errorText');
      
      setState(() {
        _error = errorText;
        _isLoading = false;
      });

      if (mounted) {
        // 显示详细错误对话框
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('短信导入失败'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('详细错误信息:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      errorText,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showErrorAnalysis(errorText);
                },
                child: const Text('查看解决方案'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showErrorAnalysis(String errorText) {
    String analysis = '';
    String solution = '';

    if (errorText.contains('没有短信读取权限')) {
      analysis = '应用没有获得短信读取权限。';
      solution = '1. 前往设置\n2. 找到应用权限\n3. 授予短信访问权限\n4. 重新导入短信';
    } else if (errorText.contains('原生短信读取失败')) {
      analysis = 'Android原生短信读取出现问题。';
      solution = '1. 检查Android版本是否为6.0+\n2. 确认手机有短信数据\n3. 重启应用后重试\n4. 如果问题持续，可能是设备兼容性问题';
    } else if (errorText.contains('PlatformException')) {
      analysis = '平台级别异常，可能是权限或系统问题。';
      solution = '1. 检查应用权限设置\n2. 确认系统版本兼容性\n3. 清除应用缓存后重试';
    } else {
      analysis = '未知的错误类型。';
      solution = '1. 记录错误信息\n2. 联系开发者\n3. 提供设备型号和Android版本';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误分析'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('问题: $analysis'),
            const SizedBox(height: 16),
            const Text('解决方案:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(solution),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  int _getMessageCount(String groupId) {
    return _allMessages.where((msg) => msg.category == groupId).length;
  }

  Color _getGroupColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('短信分组管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _importSms,
            tooltip: '导入短信',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'manage_groups') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupManagementScreen(),
                  ),
                );
                // 重新加载数据
                _initializeApp();
              } else if (value == 'clear_data') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要清空所有短信数据吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _groupService.saveMessages([]);
                  _initializeApp();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已清空所有数据')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_groups',
                child: Text('管理分组'),
              ),
              const PopupMenuItem(
                value: 'clear_data',
                child: Text('清空数据'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('出错: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _importSms,
              child: const Text('重新导入'),
            ),
          ],
        ),
      );
    }

    if (_allMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_failed, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无短信数据',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importSms,
              icon: const Icon(Icons.import_contacts),
              label: const Text('导入短信'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _importSms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final messageCount = _getMessageCount(group.id);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getGroupColor(group.color),
                child: Text(
                  messageCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(group.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(
                      group: group,
                      messages: _allMessages
                          .where((msg) => msg.category == group.id)
                          .toList(),
                    ),
                  ),
                );
                // 重新加载页面数据
                _initializeApp();
              },
            ),
          );
        },
      ),
    );
  }
}