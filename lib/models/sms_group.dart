class SmsGroup {
  final String id;
  final String name;
  final String description;
  final List<String> keywords;
  final List<String> regexPatterns;
  final String color;

  SmsGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.keywords,
    required this.regexPatterns,
    required this.color,
  });

  bool matches(String content, String sender) {
    // 检查关键字匹配
    for (var keyword in keywords) {
      if (content.contains(keyword) || sender.contains(keyword)) {
        return true;
      }
    }

    // 检查正则表达式匹配
    for (var pattern in regexPatterns) {
      try {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(content) || regex.hasMatch(sender)) {
          return true;
        }
      } catch (e) {
        // 忽略无效的正则表达式
        continue;
      }
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'keywords': keywords,
      'regexPatterns': regexPatterns,
      'color': color,
    };
  }

  factory SmsGroup.fromJson(Map<String, dynamic> json) {
    return SmsGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      regexPatterns: List<String>.from(json['regexPatterns'] as List),
      color: json['color'] as String,
    );
  }

  @override
  String toString() {
    return 'SmsGroup(id: $id, name: $name, keywords: $keywords, regexPatterns: $regexPatterns)';
  }
}