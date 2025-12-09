import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  @JsonKey(name: 'chat_room_id')
  final String chatRoomId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'is_system_message')
  final bool isSystemMessage;

  // 조인된 데이터 (선택적)
  @JsonKey(name: 'sender_name')
  final String? senderName;
  @JsonKey(name: 'sender_image_url')
  final String? senderImageUrl;

  const Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.isSystemMessage = false,
    this.senderName,
    this.senderImageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

