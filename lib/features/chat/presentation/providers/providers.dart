import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/chat/models/chat_room.dart';
import 'package:lionsns/features/chat/data/datasources/supabase_chat_datasource.dart';
import 'package:lionsns/features/chat/presentation/viewmodels/chat_room_list_viewmodel.dart';
import 'package:lionsns/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';

final chatDatasourceProvider = Provider<SupabaseChatDatasource>((ref) {
  return SupabaseChatDatasource();
});

/// 채팅방 목록 ViewModel Provider (실시간 업데이트)
final chatRoomListViewModelProvider = StateNotifierProvider.autoDispose<ChatRoomListViewModel, Result<List<ChatRoom>>>((ref) {
  final datasource = ref.watch(chatDatasourceProvider);
  final currentUserId = SupabaseService.currentUser?.id ?? '';
  
  return ChatRoomListViewModel(datasource, currentUserId);
});

final chatViewModelProvider = StateNotifierProvider.autoDispose.family<ChatViewModel, ChatState, String>((ref, chatRoomId) {
  final datasource = ref.watch(chatDatasourceProvider);
  final currentUserId = SupabaseService.currentUser?.id ?? '';
  return ChatViewModel(
    datasource,
    chatRoomId: chatRoomId,
    currentUserId: currentUserId,
  );
});

/// 읽지 않은 메시지 총 개수 Provider (실시간 업데이트)
final unreadMessageCountProvider = StreamProvider.autoDispose<int>((ref) {
  final currentUserId = SupabaseService.currentUser?.id;
  
  if (currentUserId == null) {
    return Stream.value(0);
  }
  
  final datasource = ref.watch(chatDatasourceProvider);
  
  return datasource.watchChatRooms(currentUserId).map((chatRooms) {
    // 모든 채팅방의 읽지 않은 메시지 수 합산
    return chatRooms.fold<int>(
      0,
      (sum, chatRoom) => sum + (chatRoom.unreadCount ?? 0),
    );
  });
});

