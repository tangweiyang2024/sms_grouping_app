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

      final messages = await _smsService.importAndCategorizeSms();
      
      setState(() {
        _allMessages = messages;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('短信导入成功！')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
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