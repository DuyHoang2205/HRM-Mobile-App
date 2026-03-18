import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/chatbot_repository.dart';
import '../models/chat_session.dart';
import '../models/chatbot_message.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  final ChatbotRepository _repository;

  ChatbotCubit({ChatbotRepository? repository})
      : _repository = repository ?? ChatbotRepository(),
        super(const ChatbotState());

  Future<void> load() async {
    if (state.status == ChatbotStatus.loading) return;
    emit(state.copyWith(status: ChatbotStatus.loading, error: null));
    try {
      final sessions = await _repository.listSessions();
      final ChatSession? session = sessions.isNotEmpty ? sessions.first : null;
      if (session == null) {
        emit(
          state.copyWith(
            status: ChatbotStatus.success,
            session: null,
            messages: const [],
            error: null,
          ),
        );
        return;
      }

      final messages = await _repository.getMessages(session.id);
      emit(
        state.copyWith(
          status: ChatbotStatus.success,
          session: session,
          messages: messages,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatbotStatus.failure,
          error: 'Không thể tải chatbot: $e',
        ),
      );
    }
  }

  Future<void> sendMessage(String rawContent) async {
    final content = rawContent.trim();
    if (content.isEmpty || state.isSending) return;

    final pending = ChatbotMessage.localPending(
      messageId: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      content: content,
    );

    emit(
      state.copyWith(
        isSending: true,
        error: null,
        messages: [...state.messages, pending],
      ),
    );

    try {
      final result = await _repository.sendMessage(
        content: content,
        sessionId: state.session?.id,
      );

      final nextMessages = [...state.messages]
        ..removeWhere((m) => m.id == pending.id)
        ..add(result.userMessage)
        ..add(result.botMessage);

      final nextSession = state.session ??
          ChatSession(
            id: result.sessionId,
            userNo: '',
            employeeId: null,
            state: 'active',
          );

      emit(
        state.copyWith(
          status: ChatbotStatus.success,
          session: nextSession,
          messages: nextMessages,
          isSending: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          messages: [...state.messages]..removeWhere((m) => m.id == pending.id),
          error: 'Không gửi được tin nhắn: $e',
        ),
      );
    }
  }

  Future<void> escalate({String? reason}) async {
    final session = state.session;
    if (session == null || state.isEscalating) return;

    emit(state.copyWith(isEscalating: true, error: null));
    try {
      final updated = await _repository.escalateSession(
        session.id,
        reason: reason,
      );
      emit(
        state.copyWith(
          session: updated,
          isEscalating: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isEscalating: false,
          error: 'Không chuyển được hội thoại: $e',
        ),
      );
    }
  }
}
