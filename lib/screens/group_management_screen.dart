import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/sms_group.dart';
import '../services/group_service.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final GroupService _groupService = GroupService();
  List<SmsGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.loadGroups();
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  Future<void> _addGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupEditScreen(),
      ),
    );

    if (result != null && result == true) {
      _loadGroups();
    }
  }

  Future<void> _editGroup(SmsGroup group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupEditScreen(group: group),
      ),
    );

    if (result != null && result == true) {
      _loadGroups();
    }
  }

  Future<void> _deleteGroup(SmsGroup group) async {
    if (group.id == 'other') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"其他"分组不能删除')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分组"${group.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _groupService.deleteGroup(group.id);
      _loadGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除分组"${group.name}"')),
        );
      }
    }
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
        title: const Text('分组管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getGroupColor(group.color),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(group.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editGroup(group),
                        ),
                        if (group.id != 'other')
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteGroup(group),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGroup,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GroupEditScreen extends StatefulWidget {
  final SmsGroup? group;

  const GroupEditScreen({super.key, this.group});

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _regexController = TextEditingController();
  
  Color _selectedColor = Colors.blue;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _isEditing = true;
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description;
      _keywordsController.text = widget.group!.keywords.join(', ');
      _regexController.text = widget.group!.regexPatterns.join('\n');
      _selectedColor = _parseColor(widget.group!.color);
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final groupService = GroupService();
    
    final group = SmsGroup(
      id: widget.group?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      keywords: _keywordsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      regexPatterns: _regexController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      color: _colorToHex(_selectedColor),
    );

    if (_isEditing) {
      await groupService.updateGroup(group);
    } else {
      await groupService.addGroup(group);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑分组' : '添加分组'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGroup,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分组名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入分组名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '分组描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入分组描述';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                labelText: '关键字 (用逗号分隔)',
                border: OutlineInputBorder(),
                helperText: '例如: 银行, 转账, 余额',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regexController,
              decoration: const InputDecoration(
                labelText: '正则表达式 (每行一个)',
                border: OutlineInputBorder(),
                helperText: '例如: \\d{16,19} (银行卡号)',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('分组颜色'),
              trailing: CircleAvatar(
                backgroundColor: _selectedColor,
                radius: 16,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('选择颜色'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _keywordsController.dispose();
    _regexController.dispose();
    super.dispose();
  }
}