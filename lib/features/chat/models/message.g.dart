// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  chatRoomId: json['chat_room_id'] as String,
  senderId: json['sender_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isRead: json['is_read'] as bool? ?? false,
  isSystemMessage: json['is_system_message'] as bool? ?? false,
  senderName: json['sender_name'] as String?,
  senderImageUrl: json['sender_image_url'] as String?,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'chat_room_id': instance.chatRoomId,
  'sender_id': instance.senderId,
  'content': instance.content,
  'created_at': instance.createdAt.toIso8601String(),
  'is_read': instance.isRead,
  'is_system_message': instance.isSystemMessage,
  'sender_name': instance.senderName,
  'sender_image_url': instance.senderImageUrl,
};
