import 'package:equatable/equatable.dart';

import '../models/chat_session.dart';
import '../models/chatbot_message.dart';

enum ChatbotStatus { initial, loading, success, failure }

class ChatbotState extends Equatable {
  final ChatbotStatus status;
  final ChatSession? session;
  final List<ChatbotMessage> messages;
  final bool isSending;
  final bool isEscalating;
  final String? error;

  const ChatbotState({
    this.status = ChatbotStatus.initial,
    this.session,
    this.messages = const [],
    this.isSending = false,
    this.isEscalating = false,
    this.error,
  });

  ChatbotState copyWith({
    ChatbotStatus? status,
    ChatSession? session,
    List<ChatbotMessage>? messages,
    bool? isSending,
    bool? isEscalating,
    String? error,
  }) {
    return ChatbotState(
      status: status ?? this.status,
      session: session ?? this.session,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isEscalating: isEscalating ?? this.isEscalating,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, session, messages, isSending, isEscalating, error];
}
