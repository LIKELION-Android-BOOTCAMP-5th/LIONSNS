import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/chat/models/chat_room.dart';
import 'package:lionsns/features/chat/data/datasources/supabase_chat_datasource.dart';

class ChatRoomListViewModel extends StateNotifier<Result<List<ChatRoom>>> {
  final SupabaseChatDatasource _datasource;
  final String userId;
  StreamSubscription<List<ChatRoom>>? _subscription;
  bool _hasInitialData = false;

  ChatRoomListViewModel(this._datasource, this.userId)
      : super(const Pending<List<ChatRoom>>()) {
    _loadInitialData();
    _listenToChatRooms();
  }

  /// 초기 데이터 로드 (chat_rooms Realtime이 없어도 작동하도록)
  Future<void> _loadInitialData() async {
    final result = await _datasource.getChatRooms(userId);
    result.when(
      success: (chatRooms) {
        _hasInitialData = true;
        state = Success(chatRooms);
      },
      failure: (message, _) {
        state = Failure(message);
      },
      pending: (_) {
        // 이미 Pending 상태이므로 변경 불필요
      },
    );
  }

  void _listenToChatRooms() {
    _subscription = _datasource.watchChatRooms(userId).listen(
      (chatRooms) {
        // 초기 데이터가 로드된 후에만 스트림 업데이트 적용
        // (chat_rooms Realtime이 없어도 messages 스트림으로 업데이트 가능)
        if (_hasInitialData || chatRooms.isNotEmpty) {
          state = Success(chatRooms);
        }
      },
      onError: (error) {
        // 초기 로드 실패 시에만 에러 표시
        if (!_hasInitialData) {
          state = Failure('채팅방 목록을 불러올 수 없습니다: $error');
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

