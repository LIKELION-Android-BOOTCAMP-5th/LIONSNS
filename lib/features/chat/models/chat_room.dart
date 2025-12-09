import 'package:json_annotation/json_annotation.dart';
import 'message.dart';

part 'chat_room.g.dart';

@JsonSerializable()
class ChatRoom {
  final String id;
  @JsonKey(name: 'user1_id')
  final String user1Id;
  @JsonKey(name: 'user2_id')
  final String user2Id;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // 조인된 데이터 (선택적)
  @JsonKey(name: 'other_user_name')
  final String? otherUserName;
  @JsonKey(name: 'other_user_image_url')
  final String? otherUserImageUrl;
  @JsonKey(name: 'last_message')
  final Message? lastMessage;
  @JsonKey(name: 'unread_count')
  final int? unreadCount;

  const ChatRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
    this.otherUserName,
    this.otherUserImageUrl,
    this.lastMessage,
    this.unreadCount,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);

  String getOtherUserId(String currentUserId) {
    if (user1Id == currentUserId) {
      return user2Id;
    } else {
      return user1Id;
    }
  }
}

