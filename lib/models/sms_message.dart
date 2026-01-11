class SmsMessage {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  String? category;

  SmsMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: json['category'] as String?,
    );
  }

  @override
  String toString() {
    return 'SmsMessage(id: $id, sender: $sender, content: $content, timestamp: $timestamp, category: $category)';
  }
}