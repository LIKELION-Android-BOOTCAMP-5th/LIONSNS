import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

/// 댓글 모델
@JsonSerializable()
class Comment {
  final String id;
  @JsonKey(name: 'post_id')
  final String postId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // 조인된 데이터 (선택적)
  final String? authorName;
  final String? authorImageUrl;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorImageUrl,
  });

  /// JSON에서 객체로 변환
  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  /// 생성용 팩토리
  factory Comment.create({
    required String postId,
    required String userId,
    required String content,
  }) {
    final now = DateTime.now();
    return Comment(
      id: '', // 서버에서 생성
      postId: postId,
      userId: userId,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 업데이트용 copyWith
  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorImageUrl,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
    );
  }
}



