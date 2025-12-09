import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/features/chat/presentation/providers/providers.dart';
import 'package:lionsns/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../widgets/message_bubble.dart';
import '../widgets/system_message_bubble.dart';
import '../widgets/date_divider.dart';

/// 1:1 채팅 화면
class ChatScreen extends ConsumerStatefulWidget {
  final String chatRoomId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 메시지 리스트 빌드 (날짜 구분선 포함)
  Widget _buildMessageList(
    BuildContext context,
    WidgetRef ref,
    ChatState chatState,
  ) {
    final viewModel = ref.read(
      chatViewModelProvider(widget.chatRoomId).notifier,
    );
    
    // 메시지를 날짜별로 그룹화하고 날짜 구분선 추가
    final List<Widget> messageWidgets = [];
    DateTime? previousDate;
    
    for (int i = 0; i < chatState.messages.length; i++) {
      final message = chatState.messages[i];
      final messageDate = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );
      
      // 날짜가 바뀌면 구분선 추가
      if (previousDate == null || messageDate != previousDate) {
        messageWidgets.add(
          DateDivider(date: message.createdAt),
        );
        previousDate = messageDate;
      }
      
      // 시스템 메시지와 일반 메시지 구분
      if (message.isSystemMessage) {
        messageWidgets.add(
          SystemMessageBubble(message: message),
        );
      } else {
        final isCurrentUser = message.senderId == viewModel.currentUserId;
        messageWidgets.add(
          MessageBubble(
            message: message,
            isCurrentUser: isCurrentUser,
          ),
        );
      }
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messageWidgets.length,
      itemBuilder: (context, index) {
        return messageWidgets[index];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider(widget.chatRoomId));

    ref.listen<ChatState>(
      chatViewModelProvider(widget.chatRoomId),
      (previous, next) {
        if (previous?.messages.length != next.messages.length) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.pop();
            },
            tooltip: '나가기',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? const Center(
                        child: Text('메시지가 없습니다'),
                      )
                    : _buildMessageList(context, ref, chatState),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: chatState.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: chatState.isSending
                      ? null
                      : () {
                          final content = _messageController.text;
                          if (content.trim().isNotEmpty) {
                            ref
                                .read(
                                  chatViewModelProvider(widget.chatRoomId)
                                      .notifier,
                                )
                                .sendMessage(content);
                            _messageController.clear();
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

