import 'package:equatable/equatable.dart';

class ChatbotMessage extends Equatable {
  final String id;
  final String messageId;
  final String sessionId;
  final String role;
  final String content;
  final String? intent;
  final double? confidenceScore;
  final bool isFallback;
  final DateTime? createdAt;
  final bool isLocalPending;

  const ChatbotMessage({
    required this.id,
    required this.messageId,
    required this.sessionId,
    required this.role,
    required this.content,
    this.intent,
    this.confidenceScore,
    required this.isFallback,
    this.createdAt,
    this.isLocalPending = false,
  });

  bool get isUser => role.trim().toLowerCase() == 'user';

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: json['id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      intent: json['intent']?.toString(),
      confidenceScore: (json['confidence_score'] is num)
          ? (json['confidence_score'] as num).toDouble()
          : double.tryParse('${json['confidence_score']}'),
      isFallback: json['is_fallback'] == true || json['isFallback'] == true,
      createdAt: _parseDate(json['created_at']),
    );
  }

  factory ChatbotMessage.localPending({
    required String messageId,
    required String content,
  }) {
    return ChatbotMessage(
      id: 'local:$messageId',
      messageId: messageId,
      sessionId: '',
      role: 'user',
      content: content,
      isFallback: false,
      createdAt: DateTime.now(),
      isLocalPending: true,
    );
  }

  ChatbotMessage copyWith({
    String? id,
    String? messageId,
    String? sessionId,
    String? role,
    String? content,
    String? intent,
    double? confidenceScore,
    bool? isFallback,
    DateTime? createdAt,
    bool? isLocalPending,
  }) {
    return ChatbotMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      intent: intent ?? this.intent,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isFallback: isFallback ?? this.isFallback,
      createdAt: createdAt ?? this.createdAt,
      isLocalPending: isLocalPending ?? this.isLocalPending,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [
        id,
        messageId,
        sessionId,
        role,
        content,
        intent,
        confidenceScore,
        isFallback,
        createdAt,
        isLocalPending,
      ];
}
