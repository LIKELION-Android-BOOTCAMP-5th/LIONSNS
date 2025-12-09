// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  authorId: json['user_id'] as String,
  imageUrl: json['image_url'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  authorName: json['authorName'] as String?,
  authorImageUrl: json['authorImageUrl'] as String?,
  likesCount: (json['likesCount'] as num?)?.toInt(),
  commentsCount: (json['commentsCount'] as num?)?.toInt(),
  isLiked: json['isLiked'] as bool?,
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'user_id': instance.authorId,
  'image_url': instance.imageUrl,
  'thumbnailUrl': instance.thumbnailUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'authorName': instance.authorName,
  'authorImageUrl': instance.authorImageUrl,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'isLiked': instance.isLiked,
};
