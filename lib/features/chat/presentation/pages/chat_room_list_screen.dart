import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/widgets/common_app_bar.dart';
import 'package:lionsns/features/chat/presentation/providers/providers.dart';
import '../widgets/chat_room_item.dart';

/// 채팅방 목록 화면
class ChatRoomListScreen extends ConsumerWidget {
  const ChatRoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsResult = ref.watch(chatRoomListViewModelProvider);

    return Scaffold(
      appBar: const CommonAppBar(
        title: Text('채팅'),
        showChatIcon: false, // 채팅방 목록 화면에서는 채팅 아이콘 숨김
      ),
      body: chatRoomsResult.when(
        success: (chatRooms) {
          if (chatRooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '채팅방이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // 실시간 스트림이 자동으로 업데이트하므로 특별한 작업 불필요
              // 필요시에만 ViewModel 재생성 (일반적으로는 불필요)
              // ref.invalidate(chatRoomListViewModelProvider);
              
              // 실시간 스트림이 작동 중이므로 즉시 완료
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return ChatRoomItem(
                  chatRoom: chatRoom,
                  onTap: () async {
                    // 채팅방으로 이동
                    await context.push('/chat/${chatRoom.id}');
                    // 실시간 스트림이므로 자동으로 업데이트됨
                  },
                );
              },
            ),
          );
        },
        failure: (message, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        pending: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

