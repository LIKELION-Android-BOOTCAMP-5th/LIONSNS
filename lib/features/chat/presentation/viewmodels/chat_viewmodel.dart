import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/chat/models/message.dart';
import 'package:lionsns/features/chat/data/datasources/supabase_chat_datasource.dart';

/// 채팅 화면 상태
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool isSending;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSending = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? isSending,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  final SupabaseChatDatasource _datasource;
  final String chatRoomId;
  final String currentUserId;
  StreamSubscription<List<Message>>? _messagesSubscription;

  ChatViewModel(
    this._datasource, {
    required this.chatRoomId,
    required this.currentUserId,
  }) : super(const ChatState()) {
    _listenToMessages();
    _markAsRead();
  }

  void _listenToMessages() {
    _messagesSubscription = _datasource.watchMessages(chatRoomId).listen(
      (messages) {
        state = state.copyWith(messages: messages);
        _markAsRead();
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: '메시지를 불러올 수 없습니다: $error',
        );
      },
    );
  }

  Future<void> _markAsRead() async {
    await _datasource.markMessagesAsRead(
      chatRoomId: chatRoomId,
      userId: currentUserId,
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    state = state.copyWith(isSending: true, errorMessage: null);

    final result = await _datasource.sendMessage(
      chatRoomId: chatRoomId,
      senderId: currentUserId,
      content: content.trim(),
    );

    result.when(
      success: (_) {
        state = state.copyWith(isSending: false);
      },
      failure: (message, _) {
        state = state.copyWith(
          isSending: false,
          errorMessage: message,
        );
        debugPrint('메시지 전송 실패: $message');
      },
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

