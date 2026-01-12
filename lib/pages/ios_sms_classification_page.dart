import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/sms_classification_service.dart';

/// iOS 短信分类展示页面
class IOSSMSClassificationPage extends StatefulWidget {
  const IOSSMSClassificationPage({Key? key}) : super(key: key);

  @override
  State<IOSSMSClassificationPage> createState() => _IOSSMSClassificationPageState();
}

class _IOSSMSClassificationPageState extends State<IOSSMSClassificationPage> {
  List<Map<String, dynamic>> _categoryGroups = [];
  Map<String, dynamic> _categoryStats = {};
  bool _isLoading = true;
  bool _extensionEnabled = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await SMSClassificationService.getCategoryGroups();
      final stats = await SMSClassificationService.getCategoryStats();
      final enabled = await SMSClassificationService.checkExtensionStatus();

      setState(() {
        _categoryGroups = groups;
        _categoryStats = stats;
        _extensionEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果不是 iOS 平台，显示提示信息
    if (!Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('短信分类'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '此功能仅在 iOS 平台可用',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('短信分类'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSetupGuide,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_extensionEnabled) {
      return _buildSetupGuide();
    }

    if (_categoryGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_failed, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无短信数据',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '启用短信过滤扩展后，短信将自动分类',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _categoryGroups.length,
        itemBuilder: (context, index) {
          final group = _categoryGroups[index];
          return _buildCategoryCard(group);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> group) {
    final category = group['category'] as String;
    final count = group['count'] as int;
    final color = group['color'] as String;
    final icon = group['icon'] as String;
    final messages = group['messages'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(color),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(category),
        subtitle: Text('$count 条短信'),
        trailing: Text(
          color,
          style: TextStyle(
            color: _parseColor(color),
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          if (messages.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: messages.length > 10 ? 10 : messages.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final message = messages[index] as Map<String, dynamic>;
                return _buildMessageTile(message);
              },
            ),
          if (messages.length > 10)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '还有 ${messages.length - 10} 条短信...',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    final content = message['content'] as String;
    final sender = message['sender'] as String;
    final timestamp = message['timestamp'] as double;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);

    return ListTile(
      title: Text(
        content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$sender • ${_formatDate(date)}',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () => _showMessageDetails(message),
    );
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('短信详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message['content'] as String,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                '发送者: ${message['sender']}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                '分类: ${message['category']}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupGuide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.extension_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              '启用短信过滤扩展',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '需要启用短信过滤扩展才能自动分类短信',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showSetupGuide,
              icon: const Icon(Icons.settings),
              label: const Text('查看设置指南'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('短信过滤扩展设置指南'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStep('1', '打开 iPhone 设置'),
              _buildStep('2', '向下滚动找到 "短信" 选项'),
              _buildStep('3', '点击进入，选择 "未知与垃圾信息"'),
              _buildStep('4', '找到 "短信过滤" 部分'),
              _buildStep('5', '启用 "SMS Grouping App"'),
              _buildStep('6', '返回应用即可看到分类效果'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '只有启用短信过滤扩展后，应用才能自动分类短信',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}