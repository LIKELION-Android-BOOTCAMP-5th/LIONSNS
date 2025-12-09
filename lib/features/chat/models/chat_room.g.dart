// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) => ChatRoom(
  id: json['id'] as String,
  user1Id: json['user1_id'] as String,
  user2Id: json['user2_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  otherUserName: json['other_user_name'] as String?,
  otherUserImageUrl: json['other_user_image_url'] as String?,
  lastMessage: json['last_message'] == null
      ? null
      : Message.fromJson(json['last_message'] as Map<String, dynamic>),
  unreadCount: (json['unread_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChatRoomToJson(ChatRoom instance) => <String, dynamic>{
  'id': instance.id,
  'user1_id': instance.user1Id,
  'user2_id': instance.user2Id,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'other_user_name': instance.otherUserName,
  'other_user_image_url': instance.otherUserImageUrl,
  'last_message': instance.lastMessage,
  'unread_count': instance.unreadCount,
};
