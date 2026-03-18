import 'dart:math';

import '../../../core/network/dio_client.dart';
import '../models/chat_session.dart';
import '../models/chatbot_message.dart';

class ChatbotRepository {
  final DioClient _client;

  ChatbotRepository({DioClient? client}) : _client = client ?? DioClient();

  Future<List<ChatSession>> listSessions() async {
    final response = await _client.dio.get('chatbot/sessions');
    final raw = response.data as List? ?? const [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(ChatSession.fromJson)
        .toList();
  }

  Future<ChatSession> createSession() async {
    final response = await _client.dio.post('chatbot/sessions');
    return ChatSession.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<ChatbotMessage>> getMessages(String sessionId) async {
    final response = await _client.dio.get(
      'chatbot/sessions/$sessionId/messages',
      queryParameters: {'limit': 100, 'offset': 0},
    );
    final raw = (response.data is Map ? response.data['items'] : null) as List? ??
        const [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(ChatbotMessage.fromJson)
        .toList();
  }

  Future<SendChatMessageResult> sendMessage({
    required String content,
    String? sessionId,
  }) async {
    final messageId = _buildMessageId();
    final response = await _client.dio.post(
      'chatbot/messages',
      data: {
        'message_id': messageId,
        'content': content,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return SendChatMessageResult(
      sessionId: data['session_id']?.toString() ?? '',
      userMessage: ChatbotMessage.fromJson(
        Map<String, dynamic>.from(data['user_message'] as Map),
      ),
      botMessage: ChatbotMessage.fromJson(
        Map<String, dynamic>.from(data['bot_message'] as Map),
      ),
    );
  }

  Future<ChatSession> escalateSession(
    String sessionId, {
    String? reason,
  }) async {
    final response = await _client.dio.post(
      'chatbot/sessions/$sessionId/escalate',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return ChatSession.fromJson(Map<String, dynamic>.from(response.data));
  }

  String _buildMessageId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return 'msg-$now-$random';
  }
}

class SendChatMessageResult {
  final String sessionId;
  final ChatbotMessage userMessage;
  final ChatbotMessage botMessage;

  SendChatMessageResult({
    required this.sessionId,
    required this.userMessage,
    required this.botMessage,
  });
}
