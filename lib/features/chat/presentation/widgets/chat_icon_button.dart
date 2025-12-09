import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/features/chat/presentation/providers/providers.dart';

/// 채팅 아이콘 버튼 (읽지 않은 메시지 수 배지 포함)
class ChatIconButton extends ConsumerWidget {
  const ChatIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadMessageCountProvider);
    
    return unreadCountAsync.when(
      data: (unreadCount) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                context.push('/chat');
              },
              tooltip: '채팅',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        icon: const Icon(Icons.chat),
        onPressed: () {
          context.push('/chat');
        },
        tooltip: '채팅',
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.chat),
        onPressed: () {
          context.push('/chat');
        },
        tooltip: '채팅',
      ),
    );
  }
}

